- **`--select` / `-Selection` polish.** Four fixes to the fresh-install-from-a-selection-file
  flow (#139 milestone 1): `--select` no longer swallows a following flag as the file name (it
  now says "needs a selection file"); the `Resolved:` line prints `region=-` instead of a
  default region when maps are skipped; the `Lite preset` and `LITE MAP SIZE` notes (which give
  flag-removal advice) are no longer shown for a selection install; and a UTF-16 selection file
  is now refused in PowerShell too, matching bash, so the same file behaves the same on every
  OS. `check-catalog.sh` covers the new cases. Resolves #167.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
