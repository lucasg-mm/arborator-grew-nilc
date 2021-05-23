open Eliom_lib
open Eliom_content
open Html.D
open Gs_utils
open Gs_main
open Libgrew


module Grew_server_app =
  Eliom_registration.App (
  struct
    let application_name = "grew_server"
    let global_data_path = None
  end)


(* -------------------------------------------------------------------------------- *)
(* ping *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["ping"])
    ~meth:(Eliom_service.Post (Eliom_parameter.unit, Eliom_parameter.unit))
    (fun () () ->
       Log.info "<>";
       Lwt.return ("{}" , "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* free *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["free"])
    ~meth:(Eliom_service.Post (Eliom_parameter.unit, Eliom_parameter.unit))
    (fun () () ->
       free_outdated ();
       Lwt.return ("{}" , "text/plain")
    )



(* -------------------------------------------------------------------------------- *)
(* newProject *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["newProject"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<newProject> project_id=[%s]" project_id;
       let json = wrap new_project project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* getProjects *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getProjects"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit, Eliom_parameter.unit
      ))
    (fun () () ->
       Log.info "<getProjects>";
       let json = wrap get_projects () in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* eraseProject *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["eraseProject"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<eraseProject> project_id=[%s]" project_id;
       let json = wrap erase_project project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* renameProject *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["renameProject"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "new_project_id")
      ))
    (fun () (project_id, new_project_id) ->
       Log.info "<renameProject> project_id=[%s] new_project_id=[%s]" project_id new_project_id;
       let json = wrap (rename_project project_id) new_project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* getProjectConfig *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getProjectConfig"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<getProjectConfig> project_id=[%s]" project_id;
       let json = wrap get_project_config project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* updateProjectConfig *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["updateProjectConfig"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "config")
      ))
    (fun () (project_id,config) ->
       Log.info "<updateProjectConfig> project_id=[%s] config=[%s]" project_id config;
       let json = wrap (update_project_config project_id) config in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )




(* -------------------------------------------------------------------------------- *)
(* newSample *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["newSample"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<newSample> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (new_sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )


(* -------------------------------------------------------------------------------- *)
(* getSamples *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getSamples"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.string "project_id"
      ))
    (fun () (project_id) ->
       Log.info "<getSamples> project_id=[%s]" project_id;
       let json = wrap get_samples project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* eraseSample *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["eraseSample"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<eraseSample> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (erase_sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* renameSample *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["renameSample"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "new_sample_id"))
      ))
    (fun () (project_id,(sample_id,new_sample_id)) ->
       Log.info "<renameSample> project_id=[%s] sample_id=[%s] new_sample_id=[%s]" project_id sample_id new_sample_id;
       let json = wrap (rename_sample project_id sample_id) new_sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )


(* -------------------------------------------------------------------------------- *)
(* eraseSentence *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["eraseSentence"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "sent_id"))
      ))
    (fun () (project_id,(sample_id,sent_id)) ->
       Log.info "<eraseSentence> project_id=[%s] sample_id=[%s] sent_id=[%s]" project_id sample_id sent_id;
       let json = wrap (erase_sentence project_id sample_id) sent_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* eraseGraph *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["eraseGraph"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "sent_id" ** string "user_id")))
      ))
    (fun () (project_id,(sample_id,(sent_id,user_id))) ->
       Log.info "<eraseGraph> project_id=[%s] sample_id=[%s] sent_id=[%s] user_id=[%s]" project_id sample_id sent_id user_id;
       let json = wrap (erase_graph project_id sample_id sent_id) user_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )


(* -------------------------------------------------------------------------------- *)
(* getConll *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "sent_id" ** string "user_id")))
      ))
    (fun () (project_id,(sample_id,(sent_id,user_id))) ->
       Log.info "<getConll#1> project_id=[%s] sample_id=[%s] sent_id=[%s] user_id=[%s]" project_id sample_id sent_id user_id;
       let json = wrap (get_conll__user project_id sample_id sent_id) user_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "sent_id"))
      ))
    (fun () (project_id,(sample_id,sent_id)) ->
       Log.info "<getConll#2> project_id=[%s] sample_id=[%s] sent_id=[%s]" project_id sample_id sent_id;
       let json = wrap (get_conll__sent_id project_id sample_id) sent_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<getConll#3> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (get_conll__sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )


(* -------------------------------------------------------------------------------- *)
(* getUsers *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getUsers"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<getUsers#1> project_id=[%s]" project_id;
       let json = wrap get_users__project project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getUsers"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<getUsers#2> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (get_users__sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getUsers"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "sent_id"))
      ))
    (fun () (project_id,(sample_id,sent_id)) ->
       Log.info "<getUsers#2> project_id=[%s] sample_id=[%s] sent_id=[%s]" project_id sample_id sent_id;
       let json = wrap (get_users__sentence project_id sample_id) sent_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )



(* -------------------------------------------------------------------------------- *)
(* getSentIds *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getSentIds"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<getSentIds#1> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (get_sent_ids__sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getSentIds"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<getSentIds#2> project_id=[%s]" project_id;
       let json = wrap get_sent_ids__project project_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )






(* -------------------------------------------------------------------------------- *)
(* saveConll *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(file "conll_file" ** (string "project_id" ** (string "sample_id" ** (string "sent_id" ** string "user_id"))))
      ))
    (fun () (conll_file, (project_id, (sample_id, (sent_id, user_id)))) ->
       Log.info "<saveConll#1> conll_file=[%s] project_id=[%s] sample_id=[%s] sent_id=[%s] user_id=[%s]"
         (Eliom_request_info.get_tmp_filename conll_file) project_id sample_id sent_id user_id;
       let json = wrap (save_conll project_id ~sample_id ~sent_id ~user_id) conll_file in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(file "conll_file" ** (string "project_id" ** (string "sample_id" ** string "sent_id")))
      ))
    (fun () (conll_file, (project_id, (sample_id, sent_id))) ->
       Log.info "<saveConll#2> conll_file=[%s] project_id=[%s] sample_id=[%s] sent_id=[%s]"
         (Eliom_request_info.get_tmp_filename conll_file) project_id sample_id sent_id;
       let json = wrap (save_conll project_id ~sample_id ~sent_id) conll_file in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(file "conll_file" ** (string "project_id" ** (string "sample_id" ** string "user_id")))
      ))
    (fun () (conll_file, (project_id, (sample_id, user_id))) ->
       Log.info "<saveConll#3> conll_file=[%s] project_id=[%s] sample_id=[%s] user_id=[%s]"
         (Eliom_request_info.get_tmp_filename conll_file) project_id sample_id user_id;
       let json = wrap (save_conll project_id ~sample_id ~user_id) conll_file in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(file "conll_file" ** (string "project_id" ** string "sample_id"))
      ))
    (fun () (conll_file, (project_id, sample_id)) ->
       Log.info "<saveConll#4> conll_file=[%s] project_id=[%s] sample_id=[%s]"
         (Eliom_request_info.get_tmp_filename conll_file) project_id sample_id;
       let json = wrap (save_conll project_id ~sample_id) conll_file in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveConll"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(file "conll_file" ** string "project_id")
      ))
    (fun () (conll_file, project_id) ->
       Log.info "<saveConll#5> conll_file=[%s] project_id=[%s]"
         (Eliom_request_info.get_tmp_filename conll_file) project_id;
       let json = wrap (save_conll project_id) conll_file in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )





(* -------------------------------------------------------------------------------- *)
(* saveGraph *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["saveGraph"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "sent_id" ** (string "user_id" ** string "conll_graph" ))))
      ))
    (fun () (project_id,(sample_id,(sent_id,(user_id,conll_graph)))) ->
       Log.info "<saveGraph> project_id=[%s] sample_id=[%s] sent_id=[%s] user_id=[%s] conll_graph=[%s]" project_id sample_id sent_id user_id conll_graph;
       let json = wrap (save_graph project_id sample_id sent_id user_id) conll_graph in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* searchPatternInGraphs *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["searchPatternInGraphs"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "pattern")
      ))
    (fun () (project_id,pattern) ->
       Log.info "<searchPatternInGraphs#1> project_id=[%s] pattern=[%s]" project_id pattern;
       let json = wrap (search_pattern_in_graphs project_id pattern) [] in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["searchPatternInGraphs"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "pattern" ** string "clusters"))
      ))
    (fun () (project_id,(pattern,clusters)) ->
       Log.info "<searchPatternInGraphs#2> project_id=[%s] pattern=[%s] clusters=[%s]" project_id pattern clusters;
       let cluster_keys = Str.split (Str.regexp " *; *") clusters in
       let json = wrap (search_pattern_in_graphs project_id pattern) cluster_keys in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* tryRule DEPRECATED *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "pattern" ** string "commands"))
      ))
    (fun () (project_id,(pattern,commands)) ->
       Log.info "<tryRule#1> project_id=[%s] pattern=[%s] commands=[%s]" project_id pattern commands;
       let json = wrap (try_rule project_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "pattern" ** string "commands")))
      ))
    (fun () (project_id,(sample_id,(pattern,commands))) ->
       Log.info "<tryRule#2> project_id=[%s] sample_id=[%s] pattern=[%s] commands=[%s]" project_id sample_id pattern commands;
       let json = wrap (try_rule project_id ~sample_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "user_id" ** (string "pattern" ** string "commands")))
      ))
    (fun () (project_id,(user_id,(pattern,commands))) ->
       Log.info "<tryRule#3> project_id=[%s] user_id=[%s] pattern=[%s] commands=[%s]" project_id user_id pattern commands;
       let json = wrap (try_rule project_id ~user_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "user_id" ** (string "pattern" ** string "commands"))))
      ))
    (fun () (project_id,(sample_id,(user_id,(pattern,commands)))) ->
       Log.info "<tryRule#4> project_id=[%s] sample_id=[%s] user_id=[%s] pattern=[%s] commands=[%s]" project_id sample_id user_id pattern commands;
       let json = wrap (try_rule project_id ~sample_id ~user_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* tryRules *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "rules")
      ))
    (fun () (project_id,rules) ->
       Log.info "<tryRules#1> project_id=[%s] rules=[%s]" project_id rules;
       let json = wrap (try_rules project_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "rules"))
      ))
    (fun () (project_id,(sample_id,rules)) ->
       Log.info "<tryRules#2> project_id=[%s] sample_id=[%s] rules=[%s]" project_id sample_id rules;
       let json = wrap (try_rules project_id ~sample_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "user_id" ** string "rules"))
      ))
    (fun () (project_id,(user_id,rules)) ->
       Log.info "<tryRules#3> project_id=[%s] user_id=[%s] rules=[%s]" project_id user_id rules;
       let json = wrap (try_rules project_id ~user_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["tryRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "user_id" ** string "rules")))
      ))
    (fun () (project_id,(sample_id,(user_id,rules))) ->
       Log.info "<tryRules#4> project_id=[%s] sample_id=[%s] user_id=[%s] rules=[%s]" project_id sample_id user_id rules;
       let json = wrap (try_rules project_id ~sample_id ~user_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* applyRule DEPRECATED *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "pattern" ** string "commands"))
      ))
    (fun () (project_id,(pattern,commands)) ->
       Log.info "<applyRule#1> project_id=[%s] pattern=[%s] commands=[%s]" project_id pattern commands;
       let json = wrap (apply_rule project_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "pattern" ** string "commands")))
      ))
    (fun () (project_id,(sample_id,(pattern,commands))) ->
       Log.info "<applyRule#2> project_id=[%s] sample_id=[%s] pattern=[%s] commands=[%s]" project_id sample_id pattern commands;
       let json = wrap (apply_rule project_id ~sample_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "user_id" ** (string "pattern" ** string "commands")))
      ))
    (fun () (project_id,(user_id,(pattern,commands))) ->
       Log.info "<applyRule#3> project_id=[%s] user_id=[%s] pattern=[%s] commands=[%s]" project_id user_id pattern commands;
       let json = wrap (apply_rule project_id ~user_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRule"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "user_id" ** (string "pattern" ** string "commands"))))
      ))
    (fun () (project_id,(sample_id,(user_id,(pattern,commands)))) ->
       Log.info "<applyRule#4> project_id=[%s] sample_id=[%s] user_id=[%s] pattern=[%s] commands=[%s]" project_id sample_id user_id pattern commands;
       let json = wrap (apply_rule project_id ~sample_id ~user_id pattern) commands in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* applyRules *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "rules")
      ))
    (fun () (project_id,rules) ->
       Log.info "<applyRules#1> project_id=[%s] rules=[%s]" project_id rules;
       let json = wrap (apply_rules project_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** string "rules"))
      ))
    (fun () (project_id,(sample_id,rules)) ->
       Log.info "<applyRules#2> project_id=[%s] sample_id=[%s] rules=[%s]" project_id sample_id rules;
       let json = wrap (apply_rules project_id ~sample_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "user_id" ** string "rules"))
      ))
    (fun () (project_id,(user_id,rules)) ->
       Log.info "<applyRules#3> project_id=[%s] user_id=[%s] rules=[%s]" project_id user_id rules;
       let json = wrap (apply_rules project_id ~user_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["applyRules"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_id" ** (string "user_id" ** string "rules")))
      ))
    (fun () (project_id,(sample_id,(user_id,rules))) ->
       Log.info "<applyRules#4> project_id=[%s] sample_id=[%s] user_id=[%s] rules=[%s]" project_id sample_id user_id rules;
       let json = wrap (apply_rules project_id ~sample_id ~user_id) rules in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )



(* -------------------------------------------------------------------------------- *)
(* exportProject *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["exportProject"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id")
      ))
    (fun () project_id ->
       Log.info "<exportProject#1> project_id=[%s]" project_id;
       let json = wrap (export_project project_id) "[]" in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["exportProject"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_ids")
      ))
    (fun () (project_id,sample_ids) ->
       Log.info "<exportProject#2> project_id=[%s] sample_ids=[%s]" project_id sample_ids;
       let json = wrap (export_project project_id) sample_ids in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* getLexicon *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getLexicon"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_ids")
      ))
    (fun () (project_id,sample_ids) ->
       Log.info "<getLexicon#2> project_id=[%s] sample_ids=[%s]" project_id sample_ids;
       let json = wrap (get_lexicon project_id) sample_ids in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["getLexicon"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** (string "sample_ids" ** string "features"))
      ))
    (fun () (project_id,(sample_ids, features)) ->
       Log.info "<getLexicon#4> project_id=[%s] sample_ids=[%s] features=[%s]" project_id sample_ids features;
       let json = wrap (get_lexicon ~features project_id) sample_ids in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )

(* -------------------------------------------------------------------------------- *)
(* __swapSample *)
(* -------------------------------------------------------------------------------- *)
let _ = Eliom_registration.String.create
    ~path:(Eliom_service.Path ["__swapSample"])
    ~meth:(Eliom_service.Post (
        Eliom_parameter.unit,
        Eliom_parameter.(string "project_id" ** string "sample_id")
      ))
    (fun () (project_id,sample_id) ->
       Log.info "<__swapSample> project_id=[%s] sample_id=[%s]" project_id sample_id;
       let json = wrap (__swap_sample project_id) sample_id in
       Lwt.return (Yojson.Basic.pretty_to_string json, "text/plain")
    )
