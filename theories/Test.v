
Load ProofDB.

ProofDB endpoint is "http://127.0.0.1:8000/api/coq-client".

Require Import Arith.

Theorem gaming : False -> False.
Proof.
auto.
Qed.

Require Import List.

Time NLSearch "list reverse" list.

Check (2+2).

Time NLSearch "list reverse" list.

Time NLSearch "list reverse".
