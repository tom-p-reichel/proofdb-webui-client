# ProofDB Local Client

Meant to be used with [ProofDB](https://github.com/tom-p-reichel/proofdb-webui), a natural language Coq theorem search engine.

Currently we support Coq 8.16. Good support for newer versions is pending some issues[^1][^2].

This software is of prototype quality. Expect sharp edges and inconveniences, and let us know what breaks!


# Installation

```bash
$ opam switch create proofdb --packages="coq.8.16.1, ocaml.4.14.1" --repos="default" # add coq-released if you want.
$ git clone https://github.com/tom-p-reichel/proofdb-webui-client.git
$ cd proofdb-webui-client
$ opam install .
```

# Server Setup

We try to provide an instance of proofdb at https://proofdb.tompreichel.com. This is the one that is configured by default. **We don't guarantee perfect uptime.**

If you want to host your own server and use it with this client, you can issue the command `ProofDB Endpoint Is "...".` to change the API endpoint used.

# Usage
In a Coq session, one should be able to simply:

```coq
Load ProofDB.
```

Note that we can't "Require Import" it, because we're working around a Coq import bug[^1].

Then, natural language searches can be sent using the `NLSearch` command.

```coq
NLSearch "list reverse".
```

One can also add additional search items (non-natural-language filters) similar to the built-in search command.

```coq
NLSearch "list reverse" list. (* results must contain the term `list` *)
```

# Performance

All search results must be embedded on the server side. If the server was just set up, it has no cache. It might take *minutes* to run your first search! After that, searches should be much faster.

There is also a client side cache. The first search of a session will be before this is populated.

If you want to decrease delays associated with populating caches, just add additional filters to searches as in the usage section above. This will result in fewer theorems being considered for embedding.


[^1]: https://github.com/coq/coq/issues/18647
[^2]:  https://github.com/coq/coq/issues/19012
