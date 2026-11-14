#!/usr/bin/env bash
# A Kiwix re-run after a new monthly edition must leave one copy of each archive (#275):
# runs both installers' real fetch_zim / Fetch-Zim against a local file:// source, offline.
set -u
cd "$(dirname "$0")/../.."
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
p="$(cd "$T" && { pwd -W 2>/dev/null || pwd; })"
case "$p" in /*) SRC="file://$p/src" ;; *) SRC="file:///$p/src" ;; esac
mkdir -p "$T/src"
printf 'new edition\n' > "$T/src/wikipedia_en_all_nopic_2026-06.zim"

# The folder a previous run left: an older edition, a part-done one with its aria2 control
# file, and files that are not older editions of this archive and must stay.
seed(){
  rm -rf "$1"; mkdir -p "$1"
  for f in wikipedia_en_all_nopic_2026-03.zim wikipedia_en_all_nopic_2025-12.zim wikipedia_en_all_nopic_2025-12.zim.aria2 \
           wikipedia_en_all_maxi_2026-03.zim wikipedia_en_medicine_maxi_2026-03.zim notes.txt; do printf 'old\n' > "$1/$f"; done
}
verify(){ # dir label
  got="$(cd "$1" && ls | LC_ALL=C sort | tr '\n' ' ')"
  want="notes.txt wikipedia_en_all_maxi_2026-03.zim wikipedia_en_all_nopic_2026-06.zim wikipedia_en_medicine_maxi_2026-03.zim "
  if [ "$got" = "$want" ] && cmp -s "$T/src/wikipedia_en_all_nopic_2026-06.zim" "$1/wikipedia_en_all_nopic_2026-06.zim"; then echo "  OK   $2"
  else echo "FAIL $2: folder has: $got"; echo "     expected:       $want"; fail=1; fi
}

# --- bash
awk '/^fetch\(\)\{/ {on=1} on {print} on && /^}/ {exit}' get-offline-library.sh > "$T/helpers.sh"
awk '/^fetch_zim\(\)\{/ {on=1} on {print} on && /^}/ {exit}' get-offline-library.sh >> "$T/helpers.sh"
grep -q '^fetch_zim()' "$T/helpers.sh" || { echo "FAIL: fetch_zim not found in get-offline-library.sh"; exit 1; }
seed "$T/sh"
( USE_ARIA=0; DL_TTY=0; log(){ echo "$*"; }; . "$T/helpers.sh"
  fetch_zim "$SRC/wikipedia_en_all_nopic_2026-06.zim" "$T/sh/wikipedia_en_all_nopic_2026-06.zim" ) > "$T/sh.log" 2>&1 \
  || { echo "FAIL bash: exited non-zero"; sed 's/^/    /' "$T/sh.log"; fail=1; }
verify "$T/sh" "bash fetch_zim keeps only the new edition"

# --- PowerShell
PS=""; command -v pwsh >/dev/null 2>&1 && PS=pwsh
[ -z "$PS" ] && command -v powershell.exe >/dev/null 2>&1 && PS=powershell.exe
ps_path(){ cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; }
if [ -n "$PS" ]; then
  cat > "$T/run.ps1" <<'EOF'
param($url, $out)
$ErrorActionPreference = 'Stop'
$ast = [System.Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText($env:OEL_INSTALLER), [ref]$null, [ref]$null)
foreach($n in 'Fetch','Fetch-Zim'){
  $f = $ast.Find({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq $n }, $true)
  if(-not $f){ Write-Host "FAIL: $n not found in Get-OfflineLibrary.ps1"; exit 2 }
  Invoke-Expression $f.Extent.Text
}
# Off Windows there is no curl.exe; point the installer's call at curl.
if($IsLinux -or $IsMacOS){ $c = (Get-Command curl -CommandType Application | Select-Object -First 1).Source; function curl.exe { & $c @args } }
$UseAria = $false; $DlTty = $false
function Log($m){ Write-Host $m }
Fetch-Zim $url $out
exit 0
EOF
  seed "$T/ps"
  OEL_INSTALLER="$(ps_path "$PWD/Get-OfflineLibrary.ps1")" "$PS" -NoProfile -ExecutionPolicy Bypass -File "$(ps_path "$T/run.ps1")" \
    "$SRC/wikipedia_en_all_nopic_2026-06.zim" "$(ps_path "$T/ps/wikipedia_en_all_nopic_2026-06.zim")" > "$T/ps.log" 2>&1 \
    || { echo "FAIL PowerShell: exited non-zero"; sed 's/^/    /' "$T/ps.log"; fail=1; }
  verify "$T/ps" "PowerShell Fetch-Zim keeps only the new edition"
else echo "  skip PowerShell half: no pwsh or powershell.exe"; fi

# Every Kiwix download goes through the helper: no plain fetch of a .zim name is left.
n_sh=$(grep -cE 'log "zim: [^"]*"; fetch_zim ' get-offline-library.sh)
n_ps=$(grep -cE 'Log "zim: [^"]*"; Fetch-Zim ' Get-OfflineLibrary.ps1)
left=$(grep -nE '(log|Log) "zim: [^"]*"; (fetch|Fetch) ' get-offline-library.sh Get-OfflineLibrary.ps1)
[ -z "$left" ] || { echo "FAIL: Kiwix downloads that skip the old-edition cleanup:"; echo "$left"; fail=1; }
echo "  zim call sites: bash $n_sh, PowerShell $n_ps"
[ "$fail" = 0 ] && echo "ZIM edition checks: OK"
exit "$fail"
