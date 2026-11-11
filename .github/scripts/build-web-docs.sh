#!/usr/bin/env bash
# Publish the on-drive guides to the website so the Docs page can show them in place (#205).
# docs/*.html are the source (they ship on the drive). The published site serves web/ only, so
# this copies them verbatim into web/docs/ — the same relative path works on the live site and
# from a local file:// open, and the Docs page shows each one in an iframe instead of sending
# people to GitHub.
#   build-web-docs.sh            copy docs/*.html -> web/docs/
#   build-web-docs.sh --check    verify web/docs/ is in sync (CI); exit non-zero if not
# Comparison ignores CR/LF so a Windows (CRLF) checkout passes the same as Linux.
set -eu
cd "$(dirname "$0")/../.." || exit 1
src="docs"; dst="web/docs"
check=0; [ "${1:-}" = "--check" ] && check=1

if [ "$check" = 1 ]; then
  status=0
  for f in "$src"/*.html; do
    b="$(basename "$f")"
    if [ ! -f "$dst/$b" ] || ! diff -q <(sed 's/\r$//' "$f") <(sed 's/\r$//' "$dst/$b") >/dev/null; then
      echo "FAIL: web/docs/$b is missing or out of date"; status=1
    fi
  done
  for f in "$dst"/*.html; do
    b="$(basename "$f")"
    [ -f "$src/$b" ] || { echo "FAIL: web/docs/$b has no source in docs/ (stale copy)"; status=1; }
  done
  if [ "$status" -ne 0 ]; then
    echo "web/docs/ is out of date. Run: bash .github/scripts/build-web-docs.sh"
    exit 1
  fi
  echo "OK: web/docs/ matches docs/*.html ($(ls "$src"/*.html | wc -l | tr -d ' ') guides)."
else
  mkdir -p "$dst"
  rm -f "$dst"/*.html
  for f in "$src"/*.html; do cp "$f" "$dst/$(basename "$f")"; done
  echo "Wrote $(ls "$dst"/*.html | wc -l | tr -d ' ') guides to web/docs/."
fi
