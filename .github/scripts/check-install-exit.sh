#!/usr/bin/env bash
# The double-click launchers must tell a finished install whose self-check failed (installer
# exit 4) apart from a failed or stopped one, which a re-run resumes (#271). Runs install.sh,
# install.command and, where cmd.exe exists, install.bat against a stub installer, offline.
set -u
cd "$(dirname "$0")/../.."
REPO="$PWD"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
expect(){ # label output pattern
  if printf '%s' "$2" | grep -q "$3"; then echo "  OK   $1"; else echo "FAIL $1: no '$3' in:"; printf '%s\n' "$2" | sed 's/^/    /'; fail=1; fi
}

# Both installers end a run with a failed self-check with exit 4.
for f in get-offline-library.sh Get-OfflineLibrary.ps1; do
  tr -d '\r' < "$f" | grep -A14 'FINISHED WITH PROBLEMS' | grep -qE '^\s*exit 4\b' \
    && echo "  OK   $f exits 4 after a failed self-check" || { echo "FAIL: $f does not exit 4 after FINISHED WITH PROBLEMS"; fail=1; }
done

for l in install.sh install.command; do
  for c in 0 1 4; do
    d="$T/$l-$c"; mkdir -p "$d"; cp "$l" "$d/"
    printf '#!/bin/bash\nexit %s\n' "$c" > "$d/get-offline-library.sh"
    out="$(cd "$d" && printf 'A\n\n' | bash "./$l" 2>&1)"
    case $c in
      0) expect "$l, installer exit 0" "$out" '^Done\.' ;;
      1) expect "$l, installer exit 1" "$out" 're-run to resume' ;;
      4) expect "$l, installer exit 4" "$out" 'self-check found a problem'
         printf '%s' "$out" | grep -q 're-run to resume' && { echo "FAIL $l, installer exit 4: still says re-run to resume"; fail=1; } ;;
    esac
  done
done

if command -v cmd.exe >/dev/null 2>&1; then
  for c in 0 1 4; do
    d="$T/bat-$c"; mkdir -p "$d"; cp install.bat "$d/"
    printf 'exit %s\r\n' "$c" > "$d/Get-OfflineLibrary.ps1"
    out="$(printf 'A\r\n\r\n' | MSYS2_ARG_CONV_EXCL='*' cmd.exe /c "$(cygpath -w "$d/install.bat")" 2>&1 | tr -d '\r')"
    case $c in
      0) expect "install.bat, installer exit 0" "$out" '^Done\.' ;;
      1) expect "install.bat, installer exit 1" "$out" 're-run to resume' ;;
      4) expect "install.bat, installer exit 4" "$out" 'self-check found a problem'
         printf '%s' "$out" | grep -q 're-run to resume' && { echo "FAIL install.bat, installer exit 4: still says re-run to resume"; fail=1; } ;;
    esac
  done
else echo "  skip install.bat: no cmd.exe"; fi

[ "$fail" = 0 ] && echo "Launcher exit checks: OK"
exit "$fail"
