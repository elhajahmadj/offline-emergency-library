- **`--only translate` refreshes the translator guide it ships.** Adding the browser
  translator to a finished drive with `--only translate` / `-Only translate` now also updates
  `AI-Offline/HOW-TO-TRANSLATE` (`.md` + `.html`), so the guide names the `TRANSLATE-BROWSER.bat`
  / `translate-browser.command` / `translate-browser.sh` launchers written in the same run.
  Every other doc is still left untouched, so the `--only` rule from #74 holds for the rest.
  Resolves #152. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
