- **Tighten the MedlinePlus page CSP and close a CSP-check gap.** `medlineplus/MedlinePlus.html`
  now allows its one inline `<style>` block by `sha256-` hash instead of `style-src 'unsafe-inline'`,
  so the page's styling can no longer be swapped at load time. `.github/scripts/check-csp-hash.sh`
  now also reads `style-src`: it hashes every inline `<style>`, rejects `'unsafe-inline'` in
  `script-src` or `style-src`, and flags un-hashable inline `style="..."` attributes, so a stale
  style hash or a re-opened inline hole fails CI. Resolves #106 and #157.
  _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
