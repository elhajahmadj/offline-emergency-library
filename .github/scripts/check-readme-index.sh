#!/usr/bin/env bash
# Build README.html with each installer's real index code (and build-readme-index.ps1) on a
# fixture drive whose file names hold ' # % & ; (#278), then check every link opens its file.
set -u
cd "$(dirname "$0")/../.."
REPO="$PWD"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
PY=""; for c in python3 python; do "$c" -c 'import sys' 2>/dev/null && { PY="$c"; break; }; done
[ -n "$PY" ] || { echo "FAIL: no python"; exit 1; }

# Names Windows also allows, so the same fixture works on every OS.
seed(){
  mkdir -p "$1/Manuals/odd & folder's #2" "$1/Wikipedia" "$1/Phone-Apps" "$1/docs"
  for f in "Manuals/odd Culpeper's #1 & 100% Herbal.pdf" "Manuals/odd & folder's #2/odd plain.pdf" \
           "Wikipedia/odd_wiki's_#1_2026-01.zim" "odd run & go's #1.sh" "Phone-Apps/odd app's #1 100%.apk" \
           "docs/odd tips & tricks's #1.html" "docs/odd tips & tricks's #1.md"; do printf 'x\n' > "$1/$f"; done
}
check(){ "$PY" .github/scripts/check-readme-index.py "$1" "$1/README.html" "$2" || fail=1; }

# --- bash installer
seed "$T/sh"
sed -n '/^# =* README index/,/^log "README.html index written."/p' get-offline-library.sh > "$T/index.sh"
tail -n 1 "$T/index.sh" | grep -q 'index written' || { echo "FAIL: README index section not found in get-offline-library.sh"; exit 1; }
( ROOT="$T/sh"; log(){ :; }; . "$T/index.sh" ) || { echo "FAIL bash: index section exited non-zero"; fail=1; }
check "$T/sh" "bash installer"

# --- PowerShell installer and build-readme-index.ps1
PS=""; command -v pwsh >/dev/null 2>&1 && PS=pwsh
[ -z "$PS" ] && command -v powershell.exe >/dev/null 2>&1 && PS=powershell.exe
ps_path(){ cygpath -wl "$1" 2>/dev/null || printf '%s' "$1"; }
if [ -n "$PS" ]; then
  seed "$T/ps"
  sed -n "/^Log '=== Building README.html/,/^}catch{ Log \"README index ERROR/p" Get-OfflineLibrary.ps1 | tr -d '\r' > "$T/index.ps1"
  tail -n 1 "$T/index.ps1" | grep -q 'README index ERROR' || { echo "FAIL: README index section not found in Get-OfflineLibrary.ps1"; exit 1; }
  printf '%s\n' '$ErrorActionPreference = "Stop"' 'function Log($m){ if($m -match "ERROR"){ Write-Host $m; exit 1 } }' "\$Root = '$(ps_path "$T/ps")'" > "$T/run.ps1"
  cat "$T/index.ps1" >> "$T/run.ps1"
  "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(ps_path "$T/run.ps1")" || { echo "FAIL PowerShell: index section failed"; fail=1; }
  check "$T/ps" "PowerShell installer"
  seed "$T/br"
  "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(ps_path "$REPO/build-readme-index.ps1")" -Root "$(ps_path "$T/br")" > /dev/null || { echo "FAIL build-readme-index.ps1 exited non-zero"; fail=1; }
  check "$T/br" "build-readme-index.ps1"
else echo "  skip PowerShell half: no pwsh or powershell.exe"; fi

[ "$fail" = 0 ] && echo "README index checks: OK"
exit "$fail"
