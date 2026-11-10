- **Fix the phone docs pack build failing on archive.org connection drops.** The pack
  builder now downloads each manual with `curl --retry 6 --retry-all-errors`, the same tool
  the installer uses, instead of three `urllib` tries, so a dropped TLS connection from
  archive.org no longer stops the release run.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #235._
