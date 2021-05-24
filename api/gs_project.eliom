open Libgrew
open Gs_utils
open Gs_sample

(* ================================================================================ *)
module Project = struct
  (* a [key] is a sample_id *)
  type t = {
    samples: Sample.t String_map.t;
    config: Yojson.Basic.t;
  }

  let empty = { samples = String_map.empty; config = `Null }

  let iter fct t = String_map.iter fct t.samples

  let map fct t  = { t with samples = String_map.map fct t.samples }

  let mapi fct t = { t with samples = String_map.mapi fct t.samples }

  let fold_sentence fct t init =
    String_map.fold (fun sample_id sample acc ->
        String_map.fold (fun sent_id sentence acc2 ->
            fct sample_id sent_id sentence acc2
          ) sample.Sample.data acc
      ) t.samples init

  type size = {
    number_samples: int;
    number_sentences: int;
    number_tokens: int;
    number_trees: int;
  }

  let json_of_size ?project_id size =
    let sizes = [
      ("number_samples", `Int size.number_samples);
      ("number_sentences", `Int size.number_sentences);
      ("number_tokens", `Int size.number_tokens);
      ("number_trees", `Int size.number_trees);
    ] in
    match project_id with
    | None -> `Assoc sizes
    | Some id -> `Assoc (("name", `String id) :: sizes)

  let size_of_json json =
    let open Yojson.Basic.Util in
    {  number_samples = json |> member "number_samples" |> to_int;
       number_sentences= json |> member "number_sentences" |> to_int;
       number_tokens= json |> member "number_tokens" |> to_int;
       number_trees= json |> member "number_trees" |> to_int;
    }

  let get_size t =
    let (number_sentences, number_tokens, number_trees) =
      String_map.fold
        (fun sample_id sample (acc_sentences, acc_tokens, acc_trees) ->
           let sample_size = Sample.get_size sample in
           (
             acc_sentences + sample_size.number_sentences,
             acc_tokens + sample_size.number_tokens,
             acc_trees + sample_size.number_trees
           )
        ) t.samples (0,0,0) in
    {
      number_samples = String_map.cardinal t.samples;
      number_sentences;
      number_tokens;
      number_trees;
    }

  let to_json project =
    `List
      (String_map.fold
         (fun sample_id sample acc ->
            let sample_size = Sample.get_size sample in
            (`Assoc [
                ("name", (`String sample_id));
                ("number_sentences", `Int sample_size.number_sentences);
                ("number_tokens", `Int sample_size.number_tokens);
                ("number_trees", `Int sample_size.number_trees);
                ("users", String_set.to_json (Sample.users sample));
              ]
            ) :: acc
         ) project.samples []
      )

  let users t =
    String_map.fold
      (fun _ sample acc -> String_set.union acc (Sample.users sample)
      ) t.samples String_set.empty

  let sent_ids t =
    String_map.fold
      (fun _ sample acc -> (Sample.sent_ids sample) @ acc
      ) t.samples []
end

