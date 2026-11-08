- **Installer start-up mistakes stop with a clear message.** A flag with no value no longer
  hangs the Mac/Linux installer, and a mistyped flag is refused instead of ignored. A region
  that matches no maps stops the run before anything downloads. An early stop on Windows no
  longer makes `install.bat` say "Done". When the drive is too small, the installer asks before
  it continues. Resolves #192.
  _[@EnragedAntelope](https://github.com/EnragedAntelope) - PR #206._
