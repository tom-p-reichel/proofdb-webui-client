(* COPIED CODE FROM vernac/comSearch.ml*)
(* once coq 8.18 is out, these functions are exported in an mli file, and this entire section can be removed. until then, we enjoy lightly modified copy pasted code here.*)

(* MODIFICATION:
   for some inexplicable reason, I can't improt pretyping/recordops. recordops is also conspicuously missing from the docs. 
   recordops does something with canonical typeclasses, and after a couple of hours of fruitless searching,
   i simply resolved to let searches that look for canonical structures to be broken.
*)

open CErrors
open Names
open Util
open Pp
open Search
open Vernacexpr


let global_module qid =
  try Nametab.full_name_module qid
  with Not_found ->
    user_err ?loc:qid.CAst.loc
     (str "Module/section " ++ Ppconstr.pr_qualid qid ++ str " not found.")

let interp_search_restriction = function
  | SearchOutside l -> (List.map global_module l, true)
  | SearchInside l -> (List.map global_module l, false)

let kind_searcher = Decls.(function
  (* Kinds referring to the keyword introducing the object *)
  | IsAssumption _
  | IsDefinition (Definition | Example | Fixpoint | CoFixpoint | Method | StructureComponent | Let)
  | IsProof _
  | IsPrimitive as k -> Inl k
  (* Kinds referring to the status of the object *)
  | IsDefinition (Coercion | SubClass | IdentityCoercion as k') ->
    let coercions = Coercionops.coercions () in
    Inr (fun gr -> List.exists (fun c -> GlobRef.equal c.Coercionops.coe_value gr &&
                                      (k' <> SubClass && k' <> IdentityCoercion || c.Coercionops.coe_is_identity)) coercions)
  | IsDefinition CanonicalStructure -> user_err (str "Once coq 8.18 is regular, this will work. Until then, canonical structure searches are broken!!")
  | IsDefinition Scheme ->
    let schemes = DeclareScheme.all_schemes () in
    Inr (fun gr -> Indset.exists (fun c -> GlobRef.equal (GlobRef.IndRef c) gr) schemes)
  | IsDefinition Instance ->
    let instances = Typeclasses.all_instances () in
    Inr (fun gr -> List.exists (fun c -> GlobRef.equal c.Typeclasses.is_impl gr) instances))

let interp_search_item env sigma =
  function
  | SearchSubPattern ((where,head),pat) ->
      let _,pat = Constrintern.intern_constr_pattern env sigma pat in
      GlobSearchSubPattern (where,head,pat)
  | SearchString ((Anywhere,false),s,None)
      when Id.is_valid_ident_part s && String.equal (String.drop_simple_quotes s) s ->
      GlobSearchString s
  | SearchString ((where,head),s,sc) ->
      (try
        let ref =
          Notation.interp_notation_as_global_reference
            ~head:false (fun _ -> true) s sc in
        GlobSearchSubPattern (where,head,Pattern.PRef ref)
      with UserError _ ->
        user_err 
          (str "Unable to interpret " ++ quote (str s) ++ str " as a reference."))
  | SearchKind k ->
     match kind_searcher k with
     | Inl k -> GlobSearchKind k
     | Inr f -> GlobSearchFilter f

let rec interp_search_request env sigma = function
  | b, SearchLiteral i -> b, GlobSearchLiteral (interp_search_item env sigma i)
  | b, SearchDisjConj l -> b, GlobSearchDisjConj (List.map (List.map (interp_search_request env sigma)) l)




(* END STOLEN CODE *)
