open Libgrew
open Gs_utils

module Cluster_output = struct
  (* The type [cluster_output] handles mutli clustering output *)
  (* NB: the cluster key are not stored in this data type *)
  type t =
    | L of Yojson.Basic.t list (* [json_matching...] *)
    | C of t String_opt_map.t

  (* builds the needed init structure from the key list *)
  let init = function
    | [] -> L []
    | _ -> C String_opt_map.empty

  let rec to_json = function
    | L l -> `List l
    | C som ->
      `Assoc (
        String_opt_map.fold (fun key sub acc ->
            let jkey = match key with | None -> "_none_" | Some k -> k in
            (jkey, to_json sub) :: acc
          ) som []
      )

  (* insert a new matching into the cluster outut structure *)
  let rec insert prefix clust_keys pattern graph matching t =
    let new_item = match Matching.to_json pattern graph matching with
      | `Assoc l -> `Assoc (prefix @ l)
      | _ -> assert false in
    match (clust_keys, t) with
    | ([], L l) -> L (new_item :: l)
    | (clust_key::tail, C som) ->
      let key = Matching.get_value_opt ~config:conllx_config clust_key pattern graph matching in
      let old = match String_opt_map.find_opt key som with
        | None -> init tail
        | Some o -> o in
      C (String_opt_map.add key (insert prefix tail pattern graph matching old) som)
    | _ -> assert false
end (* module Cluster_output *)
