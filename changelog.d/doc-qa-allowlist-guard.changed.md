- **CI guards the manual-reader allowlist.** A new lint check (`check-doc-allowlist.sh`) fails the
  build if any folder a `doc-qa/sources.tsv` PDF lives in is missing from the manual Q&A helper
  allowlist in `doc-qa/install.sh` or `doc-qa/install.ps1`, or if the two allowlists disagree — so
  a content PR that adds a new PDF folder can no longer ship a reader that errors on a fresh drive.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
