#!/usr/bin/env bash
# Emit web/catalog.js (window.CATALOG = {...}) from catalog.json so the picker page can load
# the catalog with a <script> tag (#139, #188). A page opened from file:// cannot fetch() a
# local JSON file, so the same data is shipped as JavaScript next to catalog.json.
#
#   build-catalog-js.sh            regenerate web/catalog.js from catalog.json
#   build-catalog-js.sh --check    fail if web/catalog.js does not match catalog.json
#                                  (CI lint job; #151 left this check for this milestone)
#
# No network. Needs bash. The JS is catalog.json verbatim, wrapped in an assignment, so the
# page and the installers always read the exact same numbers. The --check ignores CR/LF so a
# Windows checkout (autocrlf) does not false-fail.
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || cd "$(dirname "$0")/../.." || exit 1

SRC="catalog.json"
OUT="web/catalog.js"
[ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }

build() {
  printf '// Generated from catalog.json by .github/scripts/build-catalog-js.sh — do not edit.\n'
  printf '// A file:// page cannot fetch() local JSON, so the catalog is shipped as this script.\n'
  printf 'window.CATALOG = '
  cat "$SRC"
  printf ';\n'
}

mkdir -p web
if [ "${1:-}" = "--check" ]; then
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  build > "$tmp"
  if ! diff -q <(tr -d '\015' < "$tmp") <(tr -d '\015' < "$OUT") >/dev/null 2>&1; then
    echo "FAIL: $OUT is out of date with $SRC."
    echo "Run: bash .github/scripts/build-catalog-js.sh  (then commit $OUT)"
    diff -u <(tr -d '\015' < "$OUT") <(tr -d '\015' < "$tmp") 2>/dev/null | head -40
    exit 1
  fi
  echo "OK: $OUT matches $SRC."
else
  build > "$OUT"
  echo "Wrote $OUT from $SRC."
fi
