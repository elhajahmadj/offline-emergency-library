- **Bash names a UTF-16 selection file instead of printing a `tr` error.** On macOS, feeding a
  UTF-16 selection file to `get-offline-library.sh --select` printed `tr: Illegal byte sequence`
  before the generic "not a selection file". It now detects a UTF-16 byte order mark up front and
  stops with the same words PowerShell uses — "looks like UTF-16; save it as UTF-8" — so both
  installers behave the same. Resolves #177. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
