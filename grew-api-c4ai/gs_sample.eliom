open Libgrew
open Gs_utils
open Gs_sentence

(* ================================================================================ *)
module Sample = struct
  (* the list always contains the same set as the data keys *)
  type t = {
    rev_order: string list;
    data: Sentence.t String_map.t; (* keys are sent_id *)
  }

  let insert sent_id user_id graph t =
    match String_map.find_opt sent_id t.data with
    | None -> { rev_order = sent_id :: t.rev_order; data = String_map.add sent_id (Sentence.add_graph user_id graph Sentence.empty) t.data }
    | Some sent -> { t with data = String_map.add sent_id (Sentence.add_graph user_id graph sent) t.data }

  let empty = { rev_order = []; data = String_map.empty }

  let swap t = { t with rev_order = List.rev t.rev_order }

  let users t =
    String_map.fold
      (fun _ sentence acc -> String_set.union acc (Sentence.get_users sentence)
      ) t.data String_set.empty

  type size = {
    number_sentences: int;
    number_tokens: int;
    number_trees: int;
  }

  let get_size t =
    let (number_tokens, number_trees) =
        String_map.fold
          (fun _ sentence (acc_tokens, acc_trees) ->
            let users = Sentence.get_users sentence in
            match String_set.choose_opt users with
            | None -> (acc_tokens, acc_trees)
            | Some user ->
              match Sentence.find_opt user sentence with
              | None -> assert false
              | Some graph -> (acc_tokens + Graph.size graph, acc_trees + (String_set.cardinal users))
          ) t.data (0,0) in
    {
      number_sentences = String_map.cardinal t.data;
      number_tokens;
      number_trees;
    }

  let sent_ids t = List.rev t.rev_order

  let save out_ch t =
    List.iter
      (fun sent_id ->
         Sentence.save out_ch (String_map.find sent_id t.data)
      ) (List.rev t.rev_order)

  let rec list_remove_item item = function
    | [] -> []
    | h::t when h=item -> t
    | h::t -> h :: (list_remove_item item t)

  let remove_sent id t =
    {
      rev_order = list_remove_item id t.rev_order;
      data = String_map.remove id t.data;
    }

  let map fct t = { t with data = String_map.map fct t.data }
end
