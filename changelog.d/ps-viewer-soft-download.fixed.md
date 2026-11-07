- **Windows installer keeps fetching the Java runtime when the map viewer download is skipped.**
  In `Get-OfflineLibrary.ps1` one `try` covered both the OsmAndMapCreator and Java downloads, so a
  soft (rebuilt-nightly) failure of the viewer also skipped Java that run. Each download now has its
  own `try`, matching bash, and the soft failure is logged as `note:` instead of `mapviewer ERROR:`.
  Resolves #179. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #182._
