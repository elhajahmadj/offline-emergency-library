- **Clearer message when `--only` is run on a drive the installer hasn't filled.** `--only` /
  `-Only` still stops (without downloading or creating anything) when the destination has no
  `CHECKSUMS-SHA256.txt`, but now also says that a drive made before the installer started
  writing that file needs one full re-run (without `--only`) first — the real reason an older,
  otherwise-complete drive is rejected. Both installers. Resolves #126.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
