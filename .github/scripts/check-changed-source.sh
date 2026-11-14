#!/usr/bin/env bash
# A publisher can replace a PDF or model under the same URL. A re-run must then fetch the
# new file whole, never resume it onto the old copy (#274). Runs both installers' real
# download helpers against a local file:// source, offline, in seconds.
set -u
cd "$(dirname "$0")/../.."
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
p="$(cd "$T" && { pwd -W 2>/dev/null || pwd; })"
case "$p" in /*) URL="file://$p/src/manual.pdf" ;; *) URL="file:///$p/src/manual.pdf" ;; esac
mkdir -p "$T/src" "$T/sh" "$T/ps"
put(){ { printf '%%PDF-%s\n' "$1"; head -c "$2" /dev/zero | tr '\0' "$3"; } > "$T/src/manual.pdf"; }

# --- bash: the real fetch, remote_size, fetch_sized, fetch_remote and get_pdf_url
for f in fetch remote_size fetch_sized fetch_remote get_pdf_url; do
  # A one-line function ends on its own line; a longer one at the first line that is "}".
  awk -v f="$f" '!on && $0 ~ "^"f"\\(\\)" {on=1; print; if (/; }$/) exit; next} on {print} on && /^}/ {exit}' get-offline-library.sh
done > "$T/helpers.sh"
for f in fetch remote_size fetch_sized fetch_remote get_pdf_url; do
  grep -q "^$f()" "$T/helpers.sh" || { echo "FAIL: $f not found in get-offline-library.sh"; exit 1; }
done
sh_run(){ ( USE_ARIA=0; DL_TTY=0; UA=test; log(){ echo "$*"; }; . "$T/helpers.sh"; get_pdf_url "$URL" manual.pdf "$T/sh" ) > "$T/sh.log" 2>&1; }

# --- PowerShell: the real Fetch, Remote-Size, Fetch-Sized and Fetch-Remote
cat > "$T/run.ps1" <<'EOF'
param($url, $out)
$ErrorActionPreference = 'Stop'
$src = [IO.File]::ReadAllText($env:OEL_INSTALLER)
$ast = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
foreach($n in 'Fetch','UA','Remote-Size','Fetch-Sized','Fetch-Remote'){
  $f = $ast.Find({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq $n }, $true)
  if(-not $f){ Write-Host "FAIL: $n not found in Get-OfflineLibrary.ps1"; exit 2 }
  Invoke-Expression $f.Extent.Text
}
# Off Windows there is no curl.exe; point the installer's calls at curl.
if($IsLinux -or $IsMacOS){ $c = (Get-Command curl -CommandType Application | Select-Object -First 1).Source; function curl.exe { & $c @args } }
$UseAria = $false; $DlTty = $false
function Log($m){ Write-Host $m }
Fetch-Remote $url $out
exit 0
EOF
PS=""; command -v pwsh >/dev/null 2>&1 && PS=pwsh
[ -z "$PS" ] && command -v powershell.exe >/dev/null 2>&1 && PS=powershell.exe
ps_path(){ cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; }
ps_run(){ OEL_INSTALLER="$(ps_path "$PWD/Get-OfflineLibrary.ps1")" "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(ps_path "$T/run.ps1")" "$URL" "$(ps_path "$T/ps/manual.pdf")" > "$T/ps.log" 2>&1; }

check(){ # name
  sh_run || { echo "FAIL [$1] bash: exited non-zero"; sed 's/^/    /' "$T/sh.log"; fail=1; }
  cmp -s "$T/src/manual.pdf" "$T/sh/manual.pdf" && echo "  OK   [$1] bash" || { echo "FAIL [$1] bash: drive copy differs from the source"; fail=1; }
  [ -z "$PS" ] && return
  ps_run || { echo "FAIL [$1] PowerShell: exited non-zero"; sed 's/^/    /' "$T/ps.log"; fail=1; }
  cmp -s "$T/src/manual.pdf" "$T/ps/manual.pdf" && echo "  OK   [$1] PowerShell" || { echo "FAIL [$1] PowerShell: drive copy differs from the source"; fail=1; }
}
put v1 200 a; check "first download"
put v2 600 b; check "publisher replaced it with a bigger file"
put v3 50 c;  check "publisher replaced it with a smaller file"
check "unchanged re-run"
[ -z "$PS" ] && echo "  skip PowerShell half: no pwsh or powershell.exe"

# The PDFs and models must go through the helper in both installers.
for pat in '^  fetch_remote "\$1" "\$out"' '^if \[ -z "\$ONLY" \]; then fetch_remote "\$M3B"' '^  fetch_remote "\$M8B"' '^  fetch_remote "\$MQ7"' '^  fetch_remote "\$MTR"'; do
  grep -qE "$pat" get-offline-library.sh || { echo "FAIL: get-offline-library.sh has no line matching: $pat"; fail=1; }
done
for pat in 'Fetch-Remote \$url \$out' 'Fetch-Remote \$m\.u' 'Fetch-Remote "https://huggingface\.co/bartowski/Qwen_Qwen3'; do
  grep -qE "$pat" Get-OfflineLibrary.ps1 || { echo "FAIL: Get-OfflineLibrary.ps1 has no line matching: $pat"; fail=1; }
done
[ "$fail" = 0 ] && echo "Changed-source checks: OK"
exit "$fail"
