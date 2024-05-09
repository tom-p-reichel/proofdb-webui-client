



open Shims


open Vernacexpr
open Search
open Format
open Constr

external similarity : bytes -> bytes -> int = "similarity"

(* This chunk of code from my advisor, Dr. Talia Ringer ************************** *)

(* Using pp, prints directly to a string *)
let print_to_string (pp : formatter -> 'a -> unit) (trm : 'a) : string =
  Format.asprintf "%a" pp trm

(* Pretty prints a term using Coq's pretty printer *)
let print_constr (fmt : formatter) (c : constr) : unit  =
  Pp.pp_with fmt (Printer.pr_constr_env (Global.env ()) Evd.empty c)
 
(* End chunk ********************************************************************* *)

let term_as_string (c:constr) : string =
  print_to_string print_constr c





(* 
let with_output_to_list (x : string list ref) = 
  Format.make_formatter (fun buf pos len ->  x := List.cons (String.sub buf pos len) (!x)) (fun () -> ())


let capture_output (f:unit -> unit) : string  = 
  let content = ref [] in 
  let stdout_formatter = !Topfmt.std_ft in
  Topfmt.std_ft := with_output_to_list content;
  f ();
  Topfmt.std_ft := stdout_formatter;
  String.concat "" @@ List.rev !content
*)

(*
let capture_search : 
let search_dummy_printer : display_function = fun a b c d -> ()
*)


(*   let results = capture_output (fun () -> ComSearch.interp_search env sigma (Search filters_raw) restriction) in
 *)


let endpoint : string ref = ref "https://proofdb.tompreichel.com/api/coq-client"

let embed_cache : (string, bytes) Hashtbl.t =  Hashtbl.create(15000)

let cache_has (t:string) : bool = match Hashtbl.find_opt embed_cache t with
| None -> false
| Some _ -> true


(* SWAR popcount technique taken from chessprogramming.org/Population_Count *)

let rec range (n:int) : int list  =  if n > 0 then List.cons n (range (n-1)) else []


let get_similarity (search : bytes) (b:string) : int = match cache_has b with
  | false -> 0
  | true -> let b_embed = Hashtbl.find embed_cache b in
              similarity search b_embed

(*
List.fold_left (fun acc -> fun x -> acc + (popcount @@ Int64.lognot @@ Int64.logxor (Bytes.get_int64_ne a_embed x) (Bytes.get_int64_ne b_embed x))) 0
              (range ((Bytes.length a_embed)/8))   
*)

let rec take (n:int) (a : 't list) : 't list = if n <= 0 then [] else
  match a with [] -> [] | h :: t -> List.cons h (take (n-1) t)


let string_of_global x = Libnames.string_of_path @@ Nametab.path_of_global x 

open Yojson.Basic.Util

let search (s:string) (filters_raw:(bool * Vernacexpr.search_request) list) (restriction:search_restriction option) : unit =
  let env = Global.env () in
  let sigma = Evd.from_env env in 
  let restriction = (match restriction with | None -> (SearchOutside []) | Some x -> x) in
  (* to be populated with client side filtered theorems  *)
  let results : (Names.GlobRef.t * types) list ref = ref [] in
  let dummy_print : display_function = fun a b c d -> results := List.cons (a,d) !results in 
  (* the search command we ran for the user *)
  let search_cmd : string = Pp.string_of_ppcmds @@ Ppvernac.pr_vernac_expr (VernacSearch (Search filters_raw,None,restriction)) in 
  Search.search env sigma (List.map (Shims.interp_search_request env sigma) filters_raw ) (interp_search_restriction restriction) dummy_print; (* populate results *)
  let missing_embeds = List.filter (fun x -> (String.length @@ term_as_string @@ (snd x)) < 2048 && not @@ cache_has @@ string_of_global @@ fst x ) !results in
  Feedback.msg_notice @@ Pp.str @@ sprintf "Using %d cached theorems, fetching %d theorem embeddings and one search embedding..." ((List.length !results) - (List.length missing_embeds) )(List.length missing_embeds);
  let json  : Yojson.Basic.t =  `Assoc [ 
    ("theorems", `List (
    List.map 
      (fun (name,constr) -> `List [ `String (string_of_global name); `String (term_as_string constr)  ] ) missing_embeds));
    ("search_cmd", `String search_cmd);
    ("query", `String s)
  ] in 
  let json_string = Yojson.Basic.to_string json in 
  (*Feedback.msg_info @@ Pp.str @@ json_string;
  Feedback.msg_info @@ Pp.str  @@ !endpoint; *)
  let response_wrapper = Ezcurl.post ?content:(Some (`String (json_string))) ~url:(!endpoint) ~params:[] () in match response_wrapper with
    | Error (_,_) -> Feedback.msg_info @@ Pp.str "Couldn't connect to the server."
    | Ok c -> let response = Yojson.Basic.from_string c.body in
  Feedback.msg_info @@ Pp.str @@ (response |> member "info" |> to_string);
  (* update cache *)
  Hashtbl.add_seq embed_cache @@ List.to_seq @@ List.map (fun p -> (fst p,Bytes.of_string @@ Base64.decode_exn @@ to_string (snd p))) (response |> member "theorems" |> to_assoc);
  let query_embed = Bytes.of_string @@ Base64.decode_exn (response |> member "query" |> to_string) in 
  let _ = List.map (fun x -> Feedback.msg_info @@ Pp.str @@ String.concat ":" [string_of_global @@ fst x; term_as_string @@ snd x]) @@ take 80 @@ List.sort (fun a -> fun b -> (get_similarity query_embed @@ string_of_global @@ fst b) - (get_similarity query_embed @@ string_of_global @@ fst a) ) !results in ()
