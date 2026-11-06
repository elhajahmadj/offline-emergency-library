# Offline Emergency Library

Portable installers assemble an offline reference library. Read
`.github/CONTRIBUTING.md` and the PR template before changing files.

## Current state
_Last verified: 2026-11-06_

- Status: issue 72 documents the tested chat context limit; issue 102 corrects state
  browser-map estimates and uses a conservative space budget.
- Works: aria2 fallback, cancellation and partial-file protection have offline regression checks.
- In progress: maintainer review of the context-limit documentation and the estimator correction.
- Known gaps: independent Swahili and Somali language review is still required.
- Deep docs: `evaluations/issue-73/README.md` describes the interpreter protocol;
  `evaluations/issue-76/README.md` describes the CPU model comparison.

## Checks

Repository checks and contribution requirements are maintained in
`.github/CONTRIBUTING.md` and `.github/workflows/ci.yml`.
The evaluation is a separate Windows PowerShell script, not part of installation.
Its invocation, limits, and raw result format are documented next to it.
Windows CI also runs `.github/scripts/check-fetch.ps1` with Windows PowerShell 5.1
to exercise the installer's real downloader against local executable fixtures.
