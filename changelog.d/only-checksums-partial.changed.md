- **Adding a piece no longer re-checks the whole drive.** `--only` / `-Only` updates the drive
  check list for just the files it added, instead of re-reading every file (about 40 minutes
  on a full drive over a network share). The README index says "Offline maps (OsmAnd)" instead
  of "Offline US maps" for every region. Resolves #195.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #206._
