- **Translator early-exit message keeps the port-in-use hint.** When `llama-server` exits at once
  because port 8087 is already taken, the browser-translator launchers now add "If it says it
  could not bind, another program is using port 8087." to the early-exit message, restoring the
  hint the old timeout message carried. Both launchers in both installers. Resolves #180.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
