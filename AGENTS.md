# Offline Emergency Library

Portable installers assemble an offline reference library. Read
`.github/CONTRIBUTING.md` and the PR template before changing files.

## Current state
_Last verified: 2026-11-05_

- Status: issue 76 adds a reproducible CPU model comparison; no lineup change.
- Works: the existing installers and their platform smoke checks are unchanged.
- In progress: maintainer review of the measured comparison.
- Known gaps: independent Swahili and Somali language review is still required.
- Deep docs: `evaluations/issue-76/README.md` describes the measurement protocol.

## Checks

Repository checks and contribution requirements are maintained in
`.github/CONTRIBUTING.md` and `.github/workflows/ci.yml`.
The evaluation is a separate Windows PowerShell script, not part of installation.
Its invocation, limits, and raw result format are documented next to it.
