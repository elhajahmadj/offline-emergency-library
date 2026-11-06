- **Launchers no longer add the current directory to the library search path.** The macOS/Linux
  launchers and the engine self-check set `LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH` to
  `"$LIBDIR:${VAR:-}"`, which left a trailing empty entry — meaning the current directory — when
  the variable was unset. They now use `"$LIBDIR${VAR:+:$VAR}"`, so an unset variable leaves just
  the engine's own library folder. Covers every launcher template in both installers,
  `doc-qa/start-docs.sh`, and the self-check; `check-launchers.sh` now asserts the path has no
  empty entry. Resolves #161. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #174._
