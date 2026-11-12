#!/usr/bin/env bash
# Offline checks that hand-kept lists still agree (no network; runs in the lint job):
#   1. every manual download (archive.org id or direct URL + file name) is the same in both
#      installers, and .github/scripts/check-links.sh watches it (#194);
#   2. every guide in docs/ has both .md and .html;
#   3. both installers place the same guides, and each one exists in docs/.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0
bad(){ echo "  FAIL $*"; fail=1; }

echo "== Manual downloads: both installers and check-links.sh =="
sh_list="$(tr -d '\r' < get-offline-library.sh | sed -nE \
  -e 's/^get_pdf +"([^"]+)" +"([^"]+)".*/\1|\2/p' \
  -e 's/^get_pdf_url +"([^"]+)" +"([^"]+)".*/\1|\2/p' \
  -e 's/^get_html_doc +"([^"]+)" +"([^"]+)" +"([^"]+)".*/\1\/\2|\3/p' | LC_ALL=C sort)"
ps_list="$(tr -d '\r' < Get-OfflineLibrary.ps1 | sed -nE "s/^ *@\{(id|u)='([^']+)'; *n='([^']+)'.*/\2|\3/p" | LC_ALL=C sort)"
[ -n "$sh_list" ] || bad "no get_pdf lines found in get-offline-library.sh (did the helper names change?)"
[ -n "$ps_list" ] || bad "no @{id=...} / @{u=...} rows found in Get-OfflineLibrary.ps1 (did the table change?)"
# The Emergency Childbirth HTML is fetched by its own code in PowerShell, not the PDF table.
only_sh="$(LC_ALL=C comm -23 <(printf '%s\n' "$sh_list") <(printf '%s\n' "$ps_list") | grep -v '^https://www.gutenberg.org/')"
only_ps="$(LC_ALL=C comm -13 <(printf '%s\n' "$sh_list") <(printf '%s\n' "$ps_list"))"
[ -z "$only_sh" ] || bad "only in get-offline-library.sh (source|file name):"$'\n'"$only_sh"
[ -z "$only_ps" ] || bad "only in Get-OfflineLibrary.ps1 (source|file name):"$'\n'"$only_ps"
while IFS='|' read -r src _; do
  [ -n "$src" ] || continue
  case "$src" in https://*) want="\"$src\"";; *) want="\"https://archive.org/metadata/$src\"";; esac
  grep -qF "$want" .github/scripts/check-links.sh || bad "check-links.sh does not check $want"
done <<< "$sh_list"
[ "$fail" = 1 ] || echo "  OK   $(printf '%s\n' "$sh_list" | grep -c .) manual sources match and are link-checked"

echo "== Guides: .md and .html pairs =="
for f in docs/*.md docs/*.html; do
  b="${f%.*}"
  [ -f "$b.md" ] && [ -f "$b.html" ] || bad "$f has no matching .md/.html twin"
done
# A literal ** in a guide's HTML means the .md was converted line by line (#254): regenerate it
# with a CommonMark converter that joins wrapped lines, keeping the file's <head>.
for f in docs/*.html; do
  ! grep -q '\*\*' "$f" || bad "$f shows literal ** (bold not converted):"$'\n'"$(grep -n -m3 '\*\*' "$f" | cut -c1-160)"
done

echo "== Guides placed by both installers =="
sh_docs="$(sed -nE 's/^ *place_doc +"([^"]+)".*/\1/p' get-offline-library.sh | LC_ALL=C sort -u)"
ps_docs="$(tr -d '\r' < Get-OfflineLibrary.ps1 | sed -nE "s/^ *PlaceDoc +'([^']+)\.md'.*/\1/p" | LC_ALL=C sort -u)"
[ "$sh_docs" = "$ps_docs" ] || bad "installers place different guides:"$'\n'"$(diff <(printf '%s\n' "$sh_docs") <(printf '%s\n' "$ps_docs"))"
for d in $sh_docs; do [ -f "docs/$d.md" ] || bad "installers place docs/$d.md, which does not exist"; done
[ "$fail" = 1 ] || echo "  OK   guides are paired and placed by both installers"

if [ "$fail" != 0 ]; then
  echo ""
  echo "Fix the lists above: a download or guide added to one place must be added to the others."
  exit 1
fi
