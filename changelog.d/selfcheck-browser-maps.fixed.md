- **The self-check now covers browser maps.** If the map style and fonts, a viewer library or
  every map is missing from `Maps-Browser/`, the run ends with a FAIL line that says what is
  missing, instead of `Finished`. A damaged `base-assets.tar.gz` is kept by re-runs, so the line
  says to delete it first. Resolves #256.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #260._
