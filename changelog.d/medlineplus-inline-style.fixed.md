- **MedlinePlus: no CSP console errors when a topic has inline styles.** A health topic whose
  summary carries inline `style="..."` attributes (for example `style="width:55%"` on a table)
  logged one "Applying inline style violates ... style-src" error per attribute under the hashed
  CSP from #169. The reader now strips `style="..."` from each summary before `DOMParser` parses
  it, so the inline styles never reach the CSP-governed document. `clean()` already drops every
  attribute but `href`, so the rendered page is identical — only the console is quiet now.
  Resolves #171. _[@elhajahmadj](https://github.com/elhajahmadj) - PR #PENDING._
