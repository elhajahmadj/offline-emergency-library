- **Clean console on the manual Q&A reader.** The reader page no longer requests a `data:` favicon that its `img-src 'none'` content security policy blocked, so the browser stops logging a CSP error on every load. Resolves #156.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #166._
