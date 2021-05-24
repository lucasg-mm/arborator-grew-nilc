open Printf
open Yojson
open Conllx
open Libgrew
open Gs_utils
open Gs_sentence
open Gs_sample
open Gs_project
open Gs_cluster_output


(* ================================================================================ *)
(* Global storage of the corpora *)
(* ================================================================================ *)

let delay = 10 * 60               (* 10 minutes: number of seconds before a corpus is removed from memory *)
let refresh_frequency = 15 * 60   (* 15 minutes: time between each refresh (free corpuses from memory if no interaction since [delay]) *)
let time () = int_of_float (Unix.time ())

type state =
  | Disk of Project.size     (* storage of the sizes info to be able to answer to getProjects without loading *)
  | Mem of (Project.t * int) (* int is the timestamp of last intercation with the project *)

(* a [key] is a project_id *)
let (current_projects : state String_map.t ref) = ref String_map.empty

(* read project from storage directory *)
let load_project project_id =
  let storage = get_global "storage" in
  let project_dir = Filename.concat storage project_id in
  printf " INFO:  [load_project] project_dir=`%s`\n%!" project_dir;
  let config =
    let config_file = Filename.concat project_dir "config.json" in
    try Yojson.Basic.from_file config_file with
    | Sys_error _ -> `Null (* no config file *)
    | Yojson.Json_error msg ->
      printf " WARNING: loading config file `%s`, IGNORED (project_id=`%s`, message=`%s`)" config_file project_id msg; `Null in
  let samples =
    folder_fold
      (fun file acc -> match file with
         | filename when Filename.check_suffix filename ".json" -> acc
         | sample_id ->
           let conll_corpus =
             try Conllx_corpus.load ~config:conllx_config (Filename.concat project_dir sample_id)
             with Conllx_error js -> raise (Error (sprintf "Conllx_error: %s" (Yojson.Basic.pretty_to_string js))) in
           let sample =
             Array.fold_left
               (fun acc2 (sent_id, conllx)  ->
                  match List.assoc_opt "user_id" (Conllx.get_meta conllx) with
                  | None -> warn "No user_id found, conll skipped"; acc2
                  | Some user_id ->
                    match List.assoc_opt "sent_id" (Conllx.get_meta conllx) with
                    | None -> warn "No sent_id found, conll skipped"; acc2
                    | Some sent_id ->
                      let (graph : Graph.t) = conllx |> Conllx.to_json |> Graph.of_json in
                      Sample.insert sent_id user_id graph acc2)
               Sample.empty (Conllx_corpus.get_data conll_corpus) in
           String_map.add sample_id sample acc
      ) String_map.empty project_dir in
  {Project.config; samples}


(* load project from disk if necessary *)
let get_project project_id =
  match String_map.find_opt project_id !current_projects with
  | None -> raise (Error (sprintf "[new_get_project] No project named '%s'" project_id))
  | Some (Disk _) ->
    let project = load_project project_id in
    current_projects := String_map.add project_id (Mem (project, time ())) !current_projects; project
  | Some (Mem (project,_)) ->
    current_projects := String_map.add project_id (Mem (project, time ())) !current_projects; project

let update_project project_id new_project =
  current_projects := String_map.add project_id (Mem (new_project, time ())) !current_projects

(* force to free a project in mem *)
let free_project project_id =
  let storage = get_global "storage" in
  match String_map.find_opt project_id !current_projects with
  | None -> raise (Error (sprintf "[free_project] No project named '%s'" project_id))
  | Some (Disk _) -> ()
  | Some (Mem (project,_)) ->
    let project_dir = Filename.concat storage project_id in
    let size = Project.get_size project in
    Yojson.Basic.to_file (Filename.concat project_dir "size.json") (Project.json_of_size size);
    current_projects := String_map.add project_id (Disk size) !current_projects

let free_outdated () =
  let kept_on_disk = ref 0 in
  let kept_in_mem = ref [] in
  let removed_from_mem = ref [] in

  let storage = get_global "storage" in
  current_projects := String_map.mapi
      (fun project_id (state : state) ->
         match state with
         | Disk s -> incr kept_on_disk; Disk s
         | Mem (project, t) ->
           let uptime = (time ()) - t in
           if uptime > delay
           then
             begin
               removed_from_mem := project_id :: !removed_from_mem;
               let project_dir = Filename.concat storage project_id in
               let size = Project.get_size project in
               Yojson.Basic.to_file (Filename.concat project_dir "size.json") (Project.json_of_size size);
               Disk size
             end
           else
             begin
               kept_in_mem := project_id :: !kept_in_mem;
               Mem (project, t)
             end
      ) !current_projects;
  Gc.major();
  Log.info " ===[free_outdated]===> DISK:%d, MEM: %d (%s), MEM-->DISK: %d (%s)"
    !kept_on_disk
    (List.length !kept_in_mem)
    (String.concat "; " !kept_in_mem)
    (List.length !removed_from_mem)
    (String.concat "; " !removed_from_mem)

let rec refresh () =
  free_outdated ();
  Lwt_timeout.start (Lwt_timeout.create refresh_frequency (fun () -> refresh()))


(* initialize the project at starting time: project are loaded lazily *)
let load_from_storage () =
  let storage = get_global "storage" in
  folder_iter
    (fun project_id ->
       let project_dir = Filename.concat storage project_id in
       let size_file = Filename.concat project_dir "size.json" in
       let size =
         try Yojson.Basic.from_file size_file |> Project.size_of_json with
         | Sys_error _
         | Yojson.Json_error _ ->
           printf " WARNING: [project_id=`%s`] cannot find a correct `size.json` file, force loading project\n%!" project_id;
           let project = load_project project_id in
           update_project project_id project;
           free_project project_id; (* force free memory and update the `size.json` file *)
           Project.get_size project in
       printf " INFO:  [load_from_storage] project_id=`%s`\n%!" project_id;
       current_projects := String_map.add project_id (Disk size) !current_projects
    ) storage;
  printf " INFO:  [load_from_storage] ----- Data loading finished -----\n%!";
  refresh ()


(* ================================================================================ *)
(* general function to get info in the current data *)
(* ================================================================================ *)
let get_sample project_id sample_id =
  try
    let project = get_project project_id in
    String_map.find sample_id project.samples
  with Not_found -> raise (Error (sprintf "[project: %s] No sample named '%s'" project_id sample_id))

let get_project_sample project_id sample_id =
  let project = get_project project_id in
  try (project, String_map.find sample_id project.samples)
  with Not_found -> raise (Error (sprintf "[project: %s] No sample named '%s'" project_id sample_id))

let get_sentence project_id sample_id sent_id =
  try String_map.find sent_id (get_sample project_id sample_id).Sample.data
  with Not_found -> raise (Error (sprintf "[project: %s, sample:%s] No sent_id '%s'" project_id sample_id sent_id))

(* ================================================================================ *)
(* general storage function in the current data *)
(* ================================================================================ *)
let save_sample project_id sample_id =
  let sample = get_sample project_id sample_id in
  let file = Filename.concat (Filename.concat (get_global "storage") project_id) sample_id in
  let out_ch = open_out file in
  Sample.save out_ch sample;
  close_out out_ch

let safe_set_meta feat value graph =
  match Graph.get_meta_opt feat graph with
  | None -> Graph.set_meta feat value graph
  | Some v when v = value -> graph
  | Some v -> raise (Error (sprintf "Inconsistent metadata `%s`: value `%s` in data is different from value `%s` in request" feat v value))

let update_conll_data project_id sample_id sent_id user_id conllx =
  let (project, sample) = get_project_sample project_id sample_id in

  let sentence = match String_map.find_opt sent_id sample.data with
    | None -> Sentence.empty
    | Some sent -> sent in

  let graph =
    conllx |> Conllx.to_json |> Graph.of_json
    |> (safe_set_meta "sent_id" sent_id)
    |> (safe_set_meta "user_id" user_id) in

  let new_sentence = Sentence.add_graph user_id graph sentence in

  let new_rev_order =
    if String_map.mem sent_id sample.data
    then sample.rev_order
    else sent_id :: sample.rev_order in
  let new_sample = {Sample.data = String_map.add sent_id new_sentence sample.data; rev_order=new_rev_order} in
  let new_project = { project with samples = String_map.add sample_id new_sample project.samples } in

  (* local update *)
  update_project project_id new_project

let parse_meta meta =
  List.fold_left (
    fun acc l ->
      match Str.bounded_full_split (Str.regexp "# \\| = ") l 4 with
      | [Str.Delim "# "; Str.Text name; Str.Delim " = "; Str.Text value] -> (name, value) :: acc
      | _ -> acc
  ) [] meta

exception Skip
let save_conll_filename project_id ?sample_id ?sent_id ?user_id conll_filename =
  let conll_corpus =
    try Conllx_corpus.load ~config:conllx_config conll_filename
    with Conllx_error js -> raise (Error (sprintf "Conllx_error: %s" (Yojson.Basic.pretty_to_string js))) in

  let sample_ids_to_backup = ref String_set.empty in
  Array.iter (
    fun (meta_sent_id, conllx) ->
      let assoc_meta = Conllx.get_meta conllx in
      let meta_sample_id = List.assoc_opt "sample_id" assoc_meta in
      let meta_user_id = List.assoc_opt "user_id" assoc_meta in
      try
        let final_sample_id = match (sample_id, meta_sample_id) with
          | (None, None) -> warn "No sample_id found, conll skipped"; raise Skip
          | (Some sn, None)
          | (None, Some sn) -> sn
          | (Some sn2, Some sn) when sn2=sn -> sn
          | (Some sn2, Some sn) -> warn (sprintf "Inconsistent sample_id %s≠%s, %s is ignored" sn2 sn sn2); sn in
        let final_sent_id = match (sent_id, meta_sent_id) with
          | (None, si) -> si
          | (Some si2, si) when si2=si -> si
          | (Some si2, si) -> warn (sprintf "Inconsistent sent_id %s≠%s, %s is ignored" si2 si si2); si in
        let final_user_id = match (user_id, meta_user_id) with
          | (None, None) -> warn "No user_id found, conll skipped"; raise Skip
          | (Some ui, None)
          | (None, Some ui) -> ui
          | (Some ui2, Some ui) when ui2=ui -> ui
          | (Some ui2, Some ui) -> warn (sprintf "Inconsistent user_id %s≠%s, %s is ignored" ui2 ui ui2); ui in
        (* NB: backup is false to avoid file saving after each graph on server during loading *)
        update_conll_data project_id final_sample_id final_sent_id final_user_id conllx;
        sample_ids_to_backup := String_set.add final_sample_id !sample_ids_to_backup;
        ()
      with Skip -> ()
  ) (Conllx_corpus.get_data conll_corpus);

  (* storage update (only at the end) *)
  String_set.iter (save_sample project_id) !sample_ids_to_backup

(* ================================================================================ *)
(* project level functions *)
(* ================================================================================ *)
let new_project project_id =
  if String_map.mem project_id !current_projects
  then raise (Error (sprintf "project '%s' already exists" project_id));
  update_project project_id Project.empty;
  Unix.mkdir (Filename.concat (get_global "storage") project_id) 0o755;
  `Null

let get_projects () =
  let project_list = String_map.fold
      (fun project_id state acc ->
         match state with
         | Mem (project, _) ->
           let size = Project.get_size project in
           (Project.json_of_size ~project_id size) :: acc
         | Disk (size) ->
           (Project.json_of_size ~project_id size) :: acc
      ) !current_projects []
  in `List project_list



let erase_project project_id =
  (* local update *)
  current_projects := String_map.remove project_id !current_projects;

  (* storage update *)
  FileUtil.rm ~recurse:true [(Filename.concat (get_global "storage") project_id)];
  `Null


let rename_project project_id new_project_id =
  if String_map.mem new_project_id !current_projects
  then raise (Error (sprintf "[project: %s] already exists" new_project_id));

  (* local update *)
  let project = get_project project_id in
  current_projects := String_map.remove project_id !current_projects;
  update_project new_project_id project;

  (* storage update *)
  let storage = get_global "storage" in
  FileUtil.mv (Filename.concat storage project_id) (Filename.concat storage new_project_id);

  `Null

let get_project_config project_id =
  let project = get_project project_id in
  project.config

let update_project_config project_id json_config =
  let config = Yojson.Basic.from_string json_config in
  let project = get_project project_id in
  let new_project = { project with config } in

  update_project project_id new_project;
  let project_dir = Filename.concat (get_global "storage") project_id in
  Yojson.Basic.to_file (Filename.concat project_dir "config.json") config;
  `Null

(* ================================================================================ *)
(* sample level functions *)
(* ================================================================================ *)
let new_sample project_id sample_id =
  let project = get_project project_id in
  if String_map.mem sample_id project.samples
  then raise (Error (sprintf "sample '%s' already exists in project '%s'" sample_id project_id))
  else
    begin
      let new_project = { project with samples = String_map.add sample_id Sample.empty project.samples } in

      update_project project_id new_project;

      let project_dir = Filename.concat (get_global "storage") project_id in
      FileUtil.touch (Filename.concat project_dir sample_id)
    end;
  `Null

let get_samples project_id =
  let project = get_project project_id in
  Project.to_json project

let erase_sample project_id sample_id =
  let project = get_project project_id in
  let new_project = { project with samples = String_map.remove sample_id project.samples } in

  update_project project_id new_project;

  FileUtil.rm [Filename.concat (Filename.concat (get_global "storage") project_id) sample_id];

  `Null


let rename_sample project_id sample_id new_sample_id =
  let (project, sample) = get_project_sample project_id sample_id in
  if String_map.mem new_sample_id project.samples
  then raise (Error (sprintf "[project: %s] sample %s already exists" project_id new_sample_id));
  let new_project = { project with samples = String_map.add new_sample_id sample (String_map.remove sample_id project.samples) } in

  update_project project_id new_project;

  let project_dir = Filename.concat (get_global "storage") project_id in
  FileUtil.mv (Filename.concat project_dir sample_id) (Filename.concat project_dir new_sample_id);

  `Null


let __swap_sample project_id sample_id =
  let (project, sample) = get_project_sample project_id sample_id in
  let new_sample = Sample.swap sample in
  let new_project = { project with samples = String_map.add sample_id new_sample project.samples } in

  update_project project_id new_project;
  save_sample project_id sample_id;
  `Null


(* ================================================================================ *)
(* sentence level functions *)
(* ================================================================================ *)
let erase_sentence project_id sample_id sent_id =
  let (project, sample) = get_project_sample project_id sample_id in
  let new_sample = Sample.remove_sent sent_id sample in
  let new_project = { project with samples = String_map.add sample_id new_sample project.samples } in

  update_project project_id new_project;
  save_sample project_id sample_id;
  `Null


(* ================================================================================ *)
(* Graph level functions *)
(* ================================================================================ *)
let erase_graph project_id sample_id sent_id user_id =
  let (project, sample) = get_project_sample project_id sample_id in
  let sentence = get_sentence project_id sample_id sent_id in
  let new_sentence = Sentence.remove_graph user_id sentence in
  let new_sample = {sample with Sample.data = String_map.add sent_id new_sentence sample.data } in
  let new_project = { project with samples = String_map.add sample_id new_sample project.samples } in

  update_project project_id new_project;
  save_sample project_id sample_id;
  `Null



(* ================================================================================ *)
let get_conll__user project_id sample_id sent_id user_id =
  let sentence = get_sentence project_id sample_id sent_id in
  match Sentence.find_opt user_id sentence with
  | None -> raise (Error (sprintf "[project: %s, sample:%s, sent_id=%s] No user '%s'" project_id sample_id sent_id user_id))
  | Some graph -> `String (graph |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config)

let get_conll__sent_id project_id sample_id sent_id =
  let sentence = get_sentence project_id sample_id sent_id in
  `Assoc (
    Sentence.fold
      (fun user_id graph acc ->
         (user_id, `String (graph |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config)) :: acc
      ) sentence []
  )

let get_conll__sample project_id sample_id =
  let sample = get_sample project_id sample_id in
  `Assoc (
    List.rev_map
      (fun sent_id ->
         (sent_id, get_conll__sent_id project_id sample_id sent_id)
      ) sample.rev_order
  )

(* ================================================================================ *)
let get_users__project project_id =
  let project = get_project project_id in
  String_set.to_json (Project.users project)

let get_users__sample project_id sample_id =
  let sample = get_sample project_id sample_id in
  String_set.to_json (Sample.users sample)

let get_users__sentence project_id sample_id sent_id =
  let sentence = get_sentence project_id sample_id sent_id in
  String_set.to_json (Sentence.get_users sentence)

(* ================================================================================ *)
let get_sent_ids__project project_id =
  let project = get_project project_id in
  `List (List.map (fun x -> `String x) (Project.sent_ids project))

let get_sent_ids__sample project_id sample_id =
  let sample = get_sample project_id sample_id in
  `List (List.map (fun x -> `String x) (Sample.sent_ids sample))



(* ================================================================================ *)
(* Save Annotations *)
(* ================================================================================ *)

let save_conll project_id ?sample_id ?sent_id ?user_id conll_file =
  let conll_filename = Eliom_request_info.get_tmp_filename conll_file in
  save_conll_filename project_id ?sample_id ?sent_id ?user_id conll_filename;
  `Null

let save_graph project_id sample_id sent_id user_id conll_graph =
  update_conll_data project_id sample_id sent_id user_id (Conllx.of_string ~config:conllx_config conll_graph);
  save_sample project_id sample_id;
  `Null

(* ================================================================================ *)
(* Search with Grew patterns *)
(* ================================================================================ *)
let search_pattern_in_graphs project_id string_pattern clust_keys =
  let project = get_project project_id in
  let pattern = Pattern.parse ~config:conllx_config string_pattern in

  let cluster_output =
    Project.fold_sentence
      (fun sample_id sent_id sentence acc ->
         Sentence.fold
           (fun user_id graph acc2 ->
              match Graph.search_pattern ~config:conllx_config pattern graph with
              | [] -> acc2
              | matching_list ->
                let prefix = [
                  ("sample_id", `String sample_id);
                  ("sent_id", `String sent_id);
                  ("conll", `String (graph |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config));
                  ("user_id", `String user_id);
                ] in
                List.fold_left
                  (fun acc3 matching ->
                     Cluster_output.insert prefix clust_keys pattern graph matching acc3
                  ) acc2 matching_list
           ) sentence acc
      ) project (Cluster_output.init clust_keys) in
  Cluster_output.to_json cluster_output




let pack json_rule_list =
  let open Yojson.Basic.Util in
  let pat_cmd_list = json_rule_list |> Yojson.Basic.from_string |> to_list |> List.map to_string in
  let rule_list = List.mapi (fun i pat_cmd -> sprintf "rule r_%d { %s }" i pat_cmd) pat_cmd_list in
  let string_pack = sprintf "package p { %s }" (String.concat "\n" rule_list) in
  let grs = Grs.parse ~config:conllx_config string_pack in
  grs

(* ================================================================================ *)
(* try_rules *)
(* ================================================================================ *)
let try_rules project_id ?sample_id ?user_id json_rule_list =
  let project = get_project project_id in
  let grs = pack json_rule_list in
  let output =
    Project.fold_sentence
      (fun _sample_id sent_id sentence acc ->
         match sample_id with
         | Some id when id <> _sample_id -> acc
         | _ ->
           Sentence.fold
             (fun _user_id graph acc2 ->
                match user_id with
                | Some id when id <> _user_id -> acc2
                | _ ->
                  match Rewrite.onf_rewrite_opt ~config:conllx_config graph grs "Onf(p)" with
                  | None -> acc2
                  | Some new_graph ->
                    `Assoc [
                      ("sample_id", `String _sample_id);
                      ("sent_id", `String sent_id);
                      ("conll", `String (new_graph |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config));
                      ("user_id", `String _user_id);
                    ] :: acc2
             ) sentence acc
      ) project [] in
  `List output

(* ================================================================================ *)
(* try_rule *)
(* ================================================================================ *)
let try_rule project_id ?sample_id ?user_id string_pattern string_commands =
  let json_rule_list = Yojson.Basic.to_string (`List [`String (sprintf "%s %s" string_pattern string_commands)]) in
  try_rules project_id ?sample_id ?user_id json_rule_list


(* ================================================================================ *)
(* apply_rules *)
(* ================================================================================ *)
let apply_rules project_id ?sample_id ?user_id json_rule_list =
  let project = get_project project_id in
  let grs = pack json_rule_list in

  let cpt_rewritten = ref 0 in
  let cpt_unchanged = ref 0 in

  let new_project =
    Project.mapi
      (fun _sample_id sample ->
         match sample_id with
         | Some id when id <> _sample_id -> sample
         | _ ->
           Sample.map
             (fun sentence ->
                Sentence.mapi
                  (fun _user_id graph ->
                     match user_id with
                     | Some id when id <> _user_id -> graph
                     | _ ->
                       match Rewrite.onf_rewrite_opt ~config:conllx_config graph grs "Onf(p)" with
                       | None -> incr cpt_unchanged; graph
                       | Some new_graph -> incr cpt_rewritten; new_graph
                  ) sentence
             ) sample
      ) project in

  update_project project_id new_project;

  (* Storage *)
  Project.iter (fun sample_id _ -> save_sample project_id sample_id) project;

  `Assoc [("rewritten", `Int !cpt_rewritten); ("unchanged", `Int !cpt_unchanged)]

(* ================================================================================ *)
(* apply_rule *)
(* ================================================================================ *)
let apply_rule project_id ?sample_id ?user_id string_pattern string_commands =
  let json_rule_list = Yojson.Basic.to_string (`List [`String (sprintf "%s %s" string_pattern string_commands)]) in
  apply_rules project_id ?sample_id ?user_id json_rule_list











let export_project_to_tempfile project_id sample_id_list =
  let project = get_project project_id in

  (* export the most recent version of each sentences in the export_file *)
  let (export_file, out_ch) = Filename.open_temp_file "grew_" ".conll" in
  let test_sample_id sample_id = match sample_id_list with
    | [] -> true
    | l -> List.mem sample_id l in
  let _ =
    Project.fold_sentence
      (fun sample_id sent_id sentence acc ->
         if test_sample_id sample_id
         then
           match Sentence.most_recent sentence with
           | None -> acc
           | Some graph ->
             fprintf out_ch "%s\n" (graph |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config);
             (`String sent_id) :: acc
         else acc
      )
      project [] in
  close_out out_ch;
  export_file

(* ================================================================================ *)
(* export_project *)
(* ================================================================================ *)
let export_project project_id sample_ids =
  let open Yojson.Basic.Util in
  try
    let sample_id_list =sample_ids |> Yojson.Basic.from_string |> to_list |> List.map to_string in
    let temp_file = export_project_to_tempfile project_id sample_id_list in
    let base_name = Filename.basename temp_file in
    FileUtil.mv temp_file (Filename.concat (get_global "downloaddir") base_name);
    let url = sprintf "%s/export/%s" (get_global "base_url") base_name in
    `String url
  with
  | Type_error _ -> raise (Error "Ill-formed parameter sample_ids. It must be a list of strings")
  | Yojson.Json_error _ -> raise (Error "sample_ids parameter is not a valid JSON data.")

(* ================================================================================ *)
(* get_lexicon *)
(* ================================================================================ *)
let get_lexicon ?features project_id sample_ids =
  let open Yojson.Basic.Util in
  try
    let feature_cli = match features with
    | None -> " -t PronType -t Mood -t Gloss"
    | Some json -> json |> Yojson.Basic.from_string |> to_list |> List.map (fun x -> " -t "^ (to_string x)) |> String.concat "" in
    let sample_id_list = sample_ids |> Yojson.Basic.from_string |> to_list |> List.map to_string in
    let export_file = export_project_to_tempfile project_id sample_id_list in

    (* run the python script: the command [python3] must be available on the host *)
    let script = "treebank2lexicon.py" in
    let script_path = Filename.concat (get_global "extern") script in
    let out_file = Filename.temp_file "grew_server" "json" in
    let command = sprintf "python3 %s %s %s %s" script_path export_file out_file feature_cli in
    match Unix.system command with
    | WEXITED 127 -> raise (Error (sprintf "The script `%s` cannot be executed" script))
    | WSIGNALED _ | WSTOPPED _ -> raise (Error (sprintf "Something went wring while executing the script `%s`" script))
    | WEXITED i when i <> 0 -> raise (Error (sprintf "The script `%s` fails with error `%d`" script i))
    | _ -> Yojson.Basic.from_file out_file
  with
  | Type_error _ -> raise (Error "Ill-formed parameter sample_ids. It must be a list of strings")
  | Yojson.Json_error _ -> raise (Error "sample_ids parameter is not a valid JSON data.")

(* -----------------------------------------------------------------------*)
(* MAIN *)
(* -----------------------------------------------------------------------*)
let _ =

  try
    (* Accept large request cf: https://github.com/Arborator/arborator-frontend/issues/30 *)
    let _ = Ocsigen_config.set_maxrequestbodysizeinmemory 100000 in

    (* Read config *)
    let _ =
      let elements =
        List.map
          (fun item ->
             Ocsigen_extensions.Configuration.element
               ~name: item
               ~pcdata: (fun x -> printf " INFO:  ---> set `%s` config parameter to `%s`\n%!" item x; set_global item x)
               ()
          )
          ["storage"; "log"; "extern"; "downloaddir"; "base_url"] in

      Ocsigen_extensions.Configuration.process_elements
        ~in_tag:"eliommodule"
        ~elements
        (Eliom_config.get_config ()) in

    Log.init();

    (* create the storage directory or load the content if it already exits *)
    try Unix.mkdir (get_global "storage") 0o755
    with Unix.Unix_error(Unix.EEXIST, _, _) ->
      load_from_storage ();
      ()
  with
  | Error msg -> printf " ERROR: ================ Starting error: %s ================\n%!" msg; exit 0
