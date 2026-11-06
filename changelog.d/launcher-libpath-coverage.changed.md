- **CI catches an empty library-path entry in every launcher, not just the translator.** The
  guard added for #161 only exercised the browser-translator launcher, so a regression in
  `doc-qa/start-docs.sh`, the chat launcher template or the engine self-check would still pass.
  `check-doc-launchers.sh` now records the server's `LD_LIBRARY_PATH` and fails on an empty entry,
  and `check-launchers.sh` statically rejects the `"$LIBDIR:${VAR:-}"` form across both installers
  and `start-docs.sh`. Resolves #178. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #182._
