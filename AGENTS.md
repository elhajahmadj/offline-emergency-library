# Offline Emergency Library

Portable installers assemble an offline reference library. Read
`.github/CONTRIBUTING.md` and the PR template before changing files.

## Current state
_Last verified: 2026-11-06_

- Status: issue 72 documents the tested chat context limit; issue 102 corrects state
  browser-map estimates and uses a conservative space budget; browser-only additions
  preserve existing OsmAnd region metadata (issue 125); issue 63 adds a ready-to-use
  manual Q&A reader (`doc-qa/`) that reuses the bundled llama.cpp server and model (the
  GPT4All database is deliberately not shipped because its stored paths do not survive
  relocation).
- Works: aria2 fallback, cancellation and partial-file protection have offline regression checks;
  an offline CLI regression covers existing and absent OsmAnd folders, selected browser maps and region size estimates.
- Works: the manual reader's source pairing (PDF hash to text hash), installer parity and
  relocation have an offline regression check; text freshness is checked in CI.
- In progress: maintainer review of the context-limit documentation, the estimator correction, the browser-only metadata fix and the manual reader.
- Known gaps: independent Swahili and Somali language review is still required.
- Deep docs: `evaluations/issue-73/README.md` describes the interpreter protocol;
  `evaluations/issue-76/README.md` describes the CPU model comparison.

## Checks

Repository checks and contribution requirements are maintained in
`.github/CONTRIBUTING.md` and `.github/workflows/ci.yml`.
The evaluation is a separate Windows PowerShell script, not part of installation.
Its invocation, limits, and raw result format are documented next to it.
Windows CI also runs `.github/scripts/check-fetch.ps1` with Windows PowerShell 5.1
to exercise the installer's real downloader against local executable fixtures, and
`.github/scripts/check-doc-qa.ps1` for reader source pairing and relocation.
`.github/scripts/check-doc-sources.sh` verifies that published manual text still matches
`sources.tsv`; a changed publisher file must be reviewed, not silently re-hashed.
Maintenance notes for the reader live in `doc-qa/README.md`.
