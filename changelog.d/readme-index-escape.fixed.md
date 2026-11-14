- **Drive index links with odd file names.** README.html now escapes file and folder names
  and encodes `'`, `#`, `%` and `?` in its links, the same way in both installers and
  `build-readme-index.ps1`, so a file such as `Culpeper's Herbal.pdf` gets a working link.
  Resolves #278.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #287._
