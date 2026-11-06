- **A rebuilt nightly no longer aborts the whole install over the optional desktop viewer.**
  When the OsmAndMapCreator nightly (or its bundled Java runtime) is rebuilt between the size
  check and the download, the size no longer matches and the installer used to stop with
  "Re-run the installer". These two downloads are optional (maps-on-PC), so they are now soft:
  the mismatch is logged and the run continues with any existing viewer kept, the same way an
  unpack failure already does. Required downloads still stop hard. Both installers. Resolves #99.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #172._
