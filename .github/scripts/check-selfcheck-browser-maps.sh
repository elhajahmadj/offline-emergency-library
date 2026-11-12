#!/usr/bin/env bash
# Browser-maps self-check (#256): runs the real "7. Browser maps" self-check block of both
# installers on fixture drives. A missing style/fonts folder must FAIL and name
# base-assets.tar.gz when browser maps were part of the run, and both installers must print
# the same line (path separators aside).
# Needs bash and pwsh. Used by CI (lint job). OEL_PS=powershell.exe uses Windows PowerShell 5.1.
set -u
cd "$(dirname "$0")/../.." || exit 1
PS="${OEL_PS:-pwsh}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
die(){ echo "FAIL: $*"; exit 1; }
sed -n '/^# 7\. Browser maps/,/^if \[ "\$GUIDED" = 1 \]/p' get-offline-library.sh | sed '$d' > "$T/bm.sh"
grep -q 'sc_fail' "$T/bm.sh" || die "browser maps self-check block not found in get-offline-library.sh"
cat > "$T/run.ps1" <<'EOF'
param($Root, $Ran)
$src = [IO.File]::ReadAllText((Join-Path $PWD 'Get-OfflineLibrary.ps1')) -replace "`r`n", "`n"
$m = [regex]::Match($src, '(?ms)^# 7\. Browser maps.*?(?=^if\(\$Guided\))')
if(-not $m.Success){ Write-Host 'browser maps self-check block not found in Get-OfflineLibrary.ps1'; exit 1 }
function ScPass($s){ Write-Output "PASS  $s" }; function ScWarn($s){ Write-Output "WARN  $s" }; function ScFail($s){ Write-Output "FAIL  $s" }
$SkipMaps = $false; $BmOnly = $false; $BrowserMaps = ($Ran -eq '1')
Invoke-Expression $m.Value
EOF
run_sh(){ # drive ran(0/1)
  ( set +u; ROOT="$1"; SKIP_MAPS=0; BM_ONLY=0; BROWSER_MAPS="$2"
    sc_pass(){ echo "PASS  $*"; }; sc_warn(){ echo "WARN  $*"; }; sc_fail(){ echo "FAIL  $*"; }
    . "$T/bm.sh" ) || die "bash self-check block failed"
}
run_ps(){ "$PS" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$T/run.ps1" "$1" "$2" | tr -d '\r' | tr '\\' / || die "PowerShell self-check block failed"; }
make_drive(){ # dir: a complete browser-maps folder
  rm -rf "$1"; mkdir -p "$1/Maps-Browser/viewer/lib" "$1/Maps-Browser/assets" "$1/Maps-Browser/pmtiles"
  for f in viewer/lib/maplibre-gl.js viewer/lib/maplibre-gl.css viewer/lib/pmtiles.js assets/nomad-base-styles.json pmtiles/global_2025-01.pmtiles; do
    echo x > "$1/Maps-Browser/$f"
  done
}
D="$T/drive"
check(){ # name ran expected-regex
  s="$(run_sh "$D" "$2")"; p="$(run_ps "$D" "$2")"
  [ "$s" = "$p" ] || die "$1: installers differ
  bash: $s
  ps:   $p"
  printf '%s\n' "$s" | grep -qE "$3" || die "$1: expected /$3/, got: '$s'"
  echo "  ok: $1"
}
make_drive "$D"; check "complete" 1 '^PASS  browser maps'
rm -rf "$D/Maps-Browser/assets"; check "damaged base-assets, maps in run" 1 '^FAIL  .*assets/nomad-base-styles.json.*delete Maps-Browser/base-assets.tar.gz'
check "damaged base-assets, maps not in run" 0 '^WARN  .*base-assets.tar.gz'
make_drive "$D"; rm -f "$D/Maps-Browser/pmtiles/"*; rm "$D/Maps-Browser/viewer/lib/pmtiles.js"
check "no maps, no viewer library" 1 '^FAIL  .*missing: viewer/lib/pmtiles.js pmtiles/\*.pmtiles - re-run'
rm -rf "$D/Maps-Browser"; check "no browser maps folder" 1 '^$'
echo "Browser maps self-check: OK"
