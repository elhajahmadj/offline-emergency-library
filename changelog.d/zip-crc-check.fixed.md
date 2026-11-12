- **Windows: a damaged download no longer unpacks silently.** The Windows installer and the
  desktop map helper now unpack zips with Windows' own `tar.exe`, which checks every file's
  checksum. A damaged zip is reported and deleted so the next run downloads it again, instead
  of writing broken files to the drive. Resolves #255.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #263._
