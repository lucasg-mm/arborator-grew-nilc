import api from "boot/backend-api";

import defaultState from "./defaultState";

import { Notify } from "quasar";

export default {
  namespaced: true,
  state: defaultState(),
  getters: {
    getProjectConfig: (state) => state,
    infos: (state) => state,
    admins: (state) => state.admins,
    guests: (state) => state.guests,
    isAdmin: (state, getters, rootSate) => {
      return state.admins.includes(rootSate.user.id);
      // return state.admins.includes(getters["getUserInfos"].id);
    },
    isGuest: (state, getters, rootState) => {
      return state.guests.includes(rootState.user.id);
    },
    isTeacher: (state, getters) => {
      return getters.isAdmin && getters.exerciseMode;
    },
    isStudent: (state, getters) => {
      return !getters.isAdmin && getters.exerciseMode;
    },
    visibility: (state) => state.visibility,
    showAllTrees: (state) => state.showAllTrees,
    description: (state) => state.description,
    exerciseMode: (state) => state.exerciseMode,
    diffMode: (state) => state.diffMode,
    diffUserId: (state) => state.diffUserId,
    shownfeatures: (state) => state.shownfeatures,
    TEACHER: (state) => state.TEACHER,
    shownmeta: (state) => state.shownmeta,
    annotationFeatures: (state) => state.annotationFeatures,
    getAnnofjson: (state) => {
      return JSON.stringify(state.annotationFeatures, null, 4);
    },
    shownmetachoices: (state) => {
      return state.annotationFeatures.META;
    },
    shownfeatureschoices: (state) =>
      ["TREE", "FORM", "UPOS", "LEMMA"].concat(
        state.annotationFeatures.FEATS.map(
          ({ name }) => "FEATS." + name
        ).concat(
          state.annotationFeatures.MISC
            ? state.annotationFeatures.MISC.map(({ name }) => "MISC." + name)
            : []
        )
      ),
    cleanedImage: (state) => {
      if (state.image !== null) {
        var clean = state.image.replace("b", "");
        clean = clean.replace(/^'/g, "");
        clean = clean.replace(/'$/g, "");
        var ifImageNotEmpty = "data:image/png;base64, " + clean;
        return ifImageNotEmpty;
      } else {
      }

      var ifImageEmpty =
        "../statics/images/niko-photos-tGTVxeOr_Rs-unsplash.jpg";

      if (state.image == null) {
        state.image = "b''";
      }
      if (state.image == "b''") {
        return ifImageEmpty;
      } else if (state.image.length < 1) {
        return ifImageEmpty;
      } else {
        return ifImageNotEmpty;
      }
    },
  },
  mutations: {
    set_project_settings(state, payload) {
      state = Object.assign(state, payload);
    },
    set_project_conllu_schema(state, payload) {
      state = Object.assign(state, payload);
    },
    reset_annotation_features(state) {
      Object.assign(
        state.annotationFeatures,
        defaultState().annotationFeatures
      );
    },
    // Set admins for klang projects
    set_klang_project_settings(state, payload) {
      state.admins = payload.admins;
    },
  },
  actions: {
    /*
     * For now, `configShown` regroup information about `shownmeta` and `shownfeatures`
     * while `configConllu` regroup the information about `annotationfeatures`
     * both of these config are saved on different servers (resp arborator-flask and grew_server)
     * so we need to keep separate the logic in Vuex, API calls and so on
     */
    fetchProjectSettings({ commit, state }, { projectname }) {
      api
        .getProject(projectname)
        .then((response) => {
          commit("set_project_settings", {
            name: response.data.projectName,
            showAllTrees: response.data.showAllTrees,
            exerciseMode: response.data.exerciseMode,
            diffMode: response.data.diffMode,
            diffUserId: response.data.diffUserId,
            visibility: response.data.visibility,
            image: response.data.image,
            description: response.data.description,
          });
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
          // this.$q.notify({
          // message: `${error}`,
          // color: "negative",
          // position: "bottom",
          // });
        });
      api.getProjectUsersAccess(projectname).then((response) => {
        commit("set_project_settings", {
          admins: response.data.admins,
          guests: response.data.guests,
        });
      });
      api.getProjectFeatures(projectname).then((response) => {
        commit("set_project_settings", {
          shownmeta: response.data.shownmeta,
          shownfeatures: response.data.shownfeatures,
        });
      });
      api.getProjectConlluSchema(projectname).then((response) => {
        var fetchedAnnotationFeatures = response.data.annotationFeatures;
        // check if there is a json in proper format, otherwise use default ConfigConllu
        if (
          typeof fetchedAnnotationFeatures !== "object" ||
          fetchedAnnotationFeatures === null
        ) {
          // commit("reset_project_config");
          fetchedAnnotationFeatures = state.annotationFeatures;
        }
        commit("set_project_conllu_schema", {
          annotationFeatures: fetchedAnnotationFeatures,
        });
      });
    },
    // KK TODO
    // there is still a mismatch between all name 'updateProjectSettings' and 'updateProjectSettings'
    // ... so we have to get a proper data structure of the whole setting for then having better
    // ... separation of conscerns for API calls
    putProjectDescription({ state }) {
      api
        .updateProject(state.name, { description: state.description })
        .then(() => {
          Notify.create({
            message: `Change saved!`,
          });
        })
        .catch((error) => {
          dispatch("notifyError", { error: error }, { root: true });
          Notify.create({
            message: `${error}`,
            color: "negative",
            position: "bottom",
          });
        });
    },

    updateProjectSettings({ commit, dispatch, state }, { toUpdateObject }) {
      return new Promise((resolve, reject) => {
        api
          .updateProject(state.name, toUpdateObject)
          .then((response) => {
            commit("set_project_settings", { ...toUpdateObject });
            Notify.create({
              message: `Change saved!`,
            });
            resolve(response);
          })
          .catch((error) => {
            dispatch("notifyError", { error: error }, { root: true });
            Notify.create({
              message: `${error}`,
              color: "negative",
              position: "bottom",
            });
            reject(error);
          });
      });
    },
    updateProjectShownFeatures(
      { commit, dispatch },
      { projectname, toUpdateObject }
    ) {
      return new Promise((resolve, reject) => {
        api
          .updateProjectFeatures(projectname, toUpdateObject)
          .then((response) => {
            commit("set_project_settings", { ...toUpdateObject });
            Notify.create({
              message: `Change saved!`,
            });
            resolve(response);
          })
          .catch((error) => {
            dispatch("notifyError", { error: error }, { root: true });
            Notify.create({
              message: `${error}`,
              color: "negative",
              position: "bottom",
            });
            reject(error);
          });
      });
    },
    postImage({ commit, state }, newImage) {
      return new Promise((resolve, reject) => {
        var form = new FormData();
        form.append("files", newImage);
        api
          .uploadProjectImage(state.name, form)
          .then((response) => {
            commit("set_project_settings", { ...response.data });
            resolve(response);
          })
          .catch((error) => {
            reject(error);
          });
      });
    },
    updateProjectConlluSchema({ commit }, { projectname, annotationFeatures }) {
      return new Promise((resolve, reject) => {
        api
          .updateProjectConlluSchema(projectname, {
            config: annotationFeatures,
          })
          .then((response) => {
            commit("set_project_conllu_schema", {
              annotationFeatures: annotationFeatures,
            });
            resolve(response);
          })
          .catch((error) => {
            reject(error.response.data.errors);
          });
      });
    },
    //// for now, AnnotationFeatures is the same thing as configConllu. We need to find an appropriate short name
    resetAnnotationFeatures({ commit }) {
      commit("reset_annotation_features");
    },

    // method for fetching klang project's settings, currently only admins
    fetchKlangProjectSettings({ commit, state }, { projectname }) {
      api
        .getKlangProjectAdmins(projectname)
        .then((response) => {
          const admins = response.data;
          commit("set_klang_project_settings", {
            admins: admins,
          });
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
        });
    },
  },
};
