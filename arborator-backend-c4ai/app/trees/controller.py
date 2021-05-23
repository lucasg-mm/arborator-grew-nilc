from app.utils.conll3 import changeMetaField, conll2tree, emptyConllu
from app.projects.service import ProjectAccessService, ProjectService
from app.samples.service import SampleExerciseLevelService
from app.utils.grew_utils import grew_request, GrewService
from flask import abort, current_app, jsonify, request
from flask_login import current_user
from flask_restx import Namespace, Resource, reqparse
from app.utils.log_manager import write_save

BASE_TREE = "base_tree"
TEACHER = "teacher"

api = Namespace(
    "Trees", description="Endpoints for dealing with trees of a sample"
)  # noqa


@api.route("/<string:projectName>/samples/<string:sampleName>/trees")
class SampleTreesResource(Resource):
    "Trees"

    def get(self, projectName: str, sampleName: str):
        """Entrypoint for getting all trees of a given sample"""
        project = ProjectService.get_by_name(projectName)
        ProjectService.check_if_project_exist(project)

        grew_sample_trees = GrewService.get_sample_trees(
            projectName, sampleName)

        # ProjectAccessService.require_access_level(project.id, 2)
        ##### exercise mode block #####
        exercise_mode = project.exercise_mode
        project_access: int = 0
        exercise_level: int = 4
        if current_user.is_authenticated:
            project_access_obj = ProjectAccessService.get_by_user_id(
                current_user.id, projectName
            )

            if project_access_obj:
                project_access = project_access_obj.access_level.code

        if project.visibility == 0 and project_access == 0:
            abort(
                403,
                "The project is not visible and you don't have the right privileges",
            )

        if exercise_mode:
            exercise_level_obj = SampleExerciseLevelService.get_by_sample_name(
                project.id, sampleName
            )
            if exercise_level_obj:
                exercise_level = exercise_level_obj.exercise_level.code

            sample_trees = extract_trees_from_sample(
                grew_sample_trees, sampleName)
            sample_trees = add_base_tree(sample_trees)

            username = "anonymous"
            if current_user.is_authenticated:
                username = current_user.username
                if project_access <= 1:
                    sample_trees = add_user_tree(sample_trees, username)

            if project_access <= 1:
                restricted_users = [BASE_TREE, TEACHER, username]
                sample_trees = restrict_trees(sample_trees, restricted_users)

        else:
            if project.show_all_trees or project.visibility == 2:
                sample_trees = samples2trees(grew_sample_trees, sampleName)
            else:
                validator = 1
                # validator = project_service.is_validator(
                #     project.id, sampleName, current_user.id)
                if validator:
                    sample_trees = samples2trees(
                        grew_sample_trees,
                        sampleName,
                    )
                else:
                    sample_trees = samples2trees_with_restrictions(
                        grew_sample_trees,
                        sampleName,
                        current_user,
                    )
        data = {"sample_trees": sample_trees, "exercise_level": exercise_level}
        return data

    def post(self, projectName: str, sampleName: str):
        parser = reqparse.RequestParser()
        parser.add_argument(name="sent_id", type=str)
        parser.add_argument(name="user_id", type=str)
        parser.add_argument(name="conll", type=str)

        args = parser.parse_args()

        project = ProjectService.get_by_name(projectName)
        project_name = projectName
        sample_name = sampleName
        user_id = args.user_id
        conll = args.conll
        sent_id = args.sent_id

        if not conll:
            abort(400)

        # TODO : add the is_annotator service
        # if project.visibility != 2:
        #     if not project_service.is_annotator(project.id, sample_name, current_user.id) or not project_service.is_validator(project.id, sample_name, current_user.id):
        #         if project.exercise_mode == 0:
        #             abort(403)

        if project.exercise_mode == 1 and user_id == TEACHER:
            conll = changeMetaField(conll, "user_id", TEACHER)
        data = {
            "project_id": project_name,
            "sample_id": sample_name,
            "user_id": user_id,
            "sent_id": sent_id,
            "conll_graph": conll,
        }
        grew_request("saveGraph", data=data)

        write_save(
            request.json["user_id"], request.json["project_name"], request.json["sent_id"], request.json["changes"])

        return {"status": "success"}


################################################################################
##################                                       #######################
##################            Tree functions             #######################
##################                                       #######################
################################################################################


def samples2trees(samples, sample_name):
    """ transforms a list of samples into a trees object """
    trees = {}
    for sentId, users in samples.items():
        for user_id, conll in users.items():
            tree = conll2tree(conll)
            if sentId not in trees:
                trees[sentId] = {
                    "sample_name": sample_name,
                    "sentence": tree.sentence(),
                    "conlls": {},
                    "matches": {},
                }
            trees[sentId]["conlls"][user_id] = conll
    return trees


def extract_trees_from_sample(sample, sample_name):
    """ transforms a samples into a trees object """
    trees = {}
    for sentId, users in sample.items():
        for user_id, conll in users.items():
            tree = conll2tree(conll)
            if sentId not in trees:
                trees[sentId] = {
                    "sample_name": sample_name,
                    "sentence": tree.sentence(),
                    "conlls": {},
                    "matches": {},
                }
            trees[sentId]["conlls"][user_id] = conll
    return trees


def add_base_tree(trees):
    for sent_id, sent_trees in trees.items():
        sent_conlls = sent_trees["conlls"]
        list_users = list(sent_conlls.keys())
        if BASE_TREE not in list_users:
            model_user = TEACHER if TEACHER in list_users else list_users[0]
            model_tree = sent_conlls[model_user]
            empty_conllu = emptyConllu(model_tree)
            sent_conlls[BASE_TREE] = empty_conllu
    return trees


def add_user_tree(trees, username):
    for sent_id, sent_trees in trees.items():
        sent_conlls = sent_trees["conlls"]
        list_users = list(sent_conlls.keys())
        if username not in list_users:
            sent_conlls[username] = sent_conlls[BASE_TREE]
    return trees


def restrict_trees(trees, restricted_users):
    for sent_id, sent_trees in trees.items():
        sent_conlls = sent_trees["conlls"]
        for user_id in list(sent_conlls.keys()):
            if user_id not in restricted_users:
                del sent_conlls[user_id]
    return trees


def samples2trees_with_restrictions(samples, sample_name, current_user):
    """ transforms a list of samples into a trees object and restrict it to user trees and default tree(s) """
    trees = {}
    # p = project_dao.find_by_name(project_name)
    # default_user_trees_ids = [dut.username for dut in project_dao.find_default_user_trees(p.id)]
    default_user_trees_ids = []
    default_usernames = list()
    default_usernames = default_user_trees_ids
    # if len(default_user_trees_ids) > 0: default_usernames = user_dao.find_username_by_ids(default_user_trees_ids)
    if current_user.username not in default_usernames:
        default_usernames.append(current_user.username)
    for sentId, users in samples.items():
        filtered_users = {
            username: users[username]
            for username in default_usernames
            if username in users
        }
        for user_id, conll in filtered_users.items():
            tree = conll2tree(conll)
            if sentId not in trees:
                trees[sentId] = {
                    "sample_name": sample_name,
                    "sentence": tree.sentence(),
                    "conlls": {},
                    "matches": {},
                }
            trees[sentId]["conlls"][user_id] = conll
    return trees


def samples2trees_exercise_mode(trees_on_grew, sample_name, current_user, project_name):
    """ transforms a list of samples into a trees object and restrict it to user trees and default tree(s) """
    trees_processed = {}
    usernames = ["teacher", current_user.username]

    for tree_id, tree_users in trees_on_grew.items():
        trees_processed[tree_id] = {
            "sample_name": sample_name,
            "sentence": "",
            "conlls": {},
            "matches": {},
        }
        for username, tree in tree_users.items():
            if username in usernames:
                trees_processed[tree_id]["conlls"][username] = tree
                # add the sentence to the dict
                # TODO : put this script on frontend and not in backend (add a conllu -> sentence in javascript)
                # if tree:
                if trees_processed[tree_id]["sentence"] == "":
                    trees_processed[tree_id]["sentence"] = conll2tree(
                        tree).sentence()

                    ### add the base tree (emptied conllu) ###
                    empty_conllu = emptyConllu(tree)
                    base_conllu = changeMetaField(
                        empty_conllu, "user_id", BASE_TREE)
                    trees_processed[tree_id]["conlls"][BASE_TREE] = base_conllu

        if current_user.username not in trees_processed[tree_id]["conlls"]:
            empty_conllu = emptyConllu(tree)
            user_empty_conllu = changeMetaField(
                empty_conllu, "user_id", current_user.username
            )
            trees_processed[tree_id]["conlls"][
                current_user.username
            ] = user_empty_conllu
    return trees_processed
