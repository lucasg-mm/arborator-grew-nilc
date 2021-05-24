open Printf
open Conllx
open Libgrew

module String_set = struct
  include Set.Make (String)
  let to_json t = `List (List.map (fun x -> `String x) (elements t))
end

module String_map = Map.Make (String)


module String_opt_map = Map.Make (struct type t = string option let compare = compare end)

(* ================================================================================ *)
exception Error of string

let (warnings: Yojson.Basic.t list ref) = ref []
let warn s = warnings := (`String s) :: !warnings

let wrap fct last_arg =
  warnings := [];
  let json =
    try
      let data = fct last_arg in
      match !warnings with
      | [] -> `Assoc [ ("status", `String "OK"); ("data", data) ]
      | l -> `Assoc [ ("status", `String "WARNING"); ("messages", `List l); ("data", data) ]
    with
    | Error msg -> `Assoc [ ("status", `String "ERROR"); ("message", `String msg) ]
    | Conllx_error t -> `Assoc [ ("status", `String "ERROR"); ("message", t) ]
    | Libgrew.Error t -> `Assoc [ ("status", `String "ERROR"); ("message", `String   t) ]
    | exc -> `Assoc [ ("status", `String "UNEXPECTED_EXCEPTION"); ("exception", `String (Printexc.to_string exc)) ] in
  json

(* ================================================================================ *)
(* Utils *)
(* ================================================================================ *)
let folder_iter fct folder =
  let dh = Unix.opendir folder in
  try
    while true do
      match Unix.readdir dh with
      | "." | ".." -> ()
      | x -> fct x
    done;
    assert false
  with
  | End_of_file -> Unix.closedir dh

let folder_fold fct init folder =
  let dh = Unix.opendir folder in
  let acc = ref init in
  try
    while true do
      match Unix.readdir dh with
      | "." | ".." -> ()
      | file -> acc := fct file !acc
    done;
    assert false
  with
  | End_of_file -> Unix.closedir dh; !acc





(* ================================================================================ *)
(* storage folder *)
(* ================================================================================ *)
let (global : string String_map.t ref) = ref String_map.empty
let set_global key value = global := String_map.add key value !global
let get_global key =
  try String_map.find key !global
  with Not_found -> raise (Error (sprintf "Config error: global parameter `%s` is not set" key))

(* The configuration is temporarily hardcoded as "sud" *)
(* The notion of project config will be used instead in the future. *)
let conllx_config = Conllx_config.build "sud"



module Log = struct
  let out_ch = ref stdout

  let time_stamp () =
    let gm = Unix.localtime (Unix.time ()) in
    Printf.sprintf "%02d_%02d_%02d_%02d_%02d_%02d"
      (gm.Unix.tm_year - 100)
      (gm.Unix.tm_mon + 1)
      gm.Unix.tm_mday
      gm.Unix.tm_hour
      gm.Unix.tm_min
      gm.Unix.tm_sec

  let init () =
    let basename = Printf.sprintf "grew_server_%s.log" (time_stamp ()) in
    let filename = Filename.concat (get_global "log") basename in
    out_ch := open_out filename

  let _info s = Printf.fprintf !out_ch "[%s] %s\n%!" (time_stamp ()) s
  let info s = Printf.ksprintf _info s
end
