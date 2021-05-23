open Conllx
open Libgrew
open Gs_utils

(* ================================================================================ *)
module Sentence = struct
  type t = Graph.t String_map.t  (* keys are user_id *)

  let empty = String_map.empty

  let add_graph user_id graph t = String_map.add user_id graph t

  let remove_graph user_id t = String_map.remove user_id t

  let get_users t =
    String_map.fold
      (fun user_id _ acc -> String_set.add user_id acc)
      t String_set.empty

  let find_opt = String_map.find_opt

  let fold = String_map.fold

  let map = String_map.map

  let mapi = String_map.mapi

  let most_recent t =
    fold
      (fun user_id graph acc ->
         match (Graph.get_meta_opt "timestamp" graph, acc) with
         | (None, _) -> acc
         | (Some string_ts, None) -> Some (graph,float_of_string string_ts)
         | (Some string_new_ts, Some (old_graph,old_ts)) ->
           let new_ts = float_of_string string_new_ts in
           if new_ts > old_ts
           then Some (graph, new_ts)
           else Some (old_graph, old_ts)
      ) t None |> CCOpt.map fst |> fun (x : Graph.t option) -> x

  let save out_ch t =
    String_map.iter
      (fun user_id graph ->
         graph
         |> Graph.set_meta "user_id" user_id
         |> Graph.to_json |> Conllx.of_json |> Conllx.to_string ~config:conllx_config
         |> Printf.fprintf out_ch "%s\n"
      ) t
end
