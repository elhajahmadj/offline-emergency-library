- **Browser translator says when the server exits at once, not a false timeout.** When
  `llama-server` dies right after launch (for example Smart App Control blocking the exe or a
  DLL, or an unreadable model), the browser-translator launcher now prints "The translator
  server stopped right after it started (exit code N)" with the log, instead of the misleading
  "did not start within 120 seconds". The PowerShell launcher also notes that security software
  or Smart App Control can block `llama-server.exe` or its DLLs. A genuine slow start or an
  occupied port still shows the timeout message. Resolves #153.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
