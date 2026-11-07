#!/usr/bin/env bash
# CHECKSUMS-SHA256.txt parity (#195): runs the real drive-check section of both installers on
# the same fixture drive and requires byte-identical lists, for a full run and for --only.
# --only must re-hash only what its pieces write, keep every other line as it was, add files
# the old list lacks and drop files that are gone.
# Needs bash and pwsh. Used by CI (lint job). OEL_PS=powershell.exe uses Windows PowerShell 5.1.
set -u
cd "$(dirname "$0")/../.." || exit 1
PS="${OEL_PS:-pwsh}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
die(){ echo "FAIL: $*"; exit 1; }
sed -n '/^# =* drive check (#28)/,/^# =* self-check/p' get-offline-library.sh > "$T/sums.sh"
[ "$(grep -c . "$T/sums.sh")" -ge 10 ] || die "drive check section not found in get-offline-library.sh"
eval "$(grep -m1 '^TR_MODEL=' get-offline-library.sh)"
Z="0000000000000000000000000000000000000000000000000000000000000000"

make_drive(){ # dir: the same files every time
  rm -rf "$1"; mkdir -p "$1/AI-Offline/engine" "$1/AI-Offline/models" "$1/Medical/MedlinePlus" "$1/a b"
  echo build > "$1/AI-Offline/engine/BUILD.txt"
  echo launcher > "$1/AI-Offline/TRANSLATE.bat"
  echo model > "$1/AI-Offline/models/$TR_MODEL"
  echo core > "$1/AI-Offline/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
  echo topics > "$1/Medical/MedlinePlus/MedlinePlus-Health-Topics.html"
  echo index > "$1/README.html"
  echo kept > "$1/a b/space file.txt"
  echo log > "$1/_download.log"
  # The old list: stale (zero) hashes for every file but the new MedlinePlus page, plus a gone file.
  printf '%s  %s\n' "$Z" ./AI-Offline/TRANSLATE.bat "$Z" ./AI-Offline/engine/BUILD.txt \
    "$Z" "./AI-Offline/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf" "$Z" "./AI-Offline/models/$TR_MODEL" \
    "$Z" ./README.html "$Z" "./a b/space file.txt" "$Z" ./gone.txt > "$1/CHECKSUMS-SHA256.txt"
}
run_sh(){ # dir only
  ( set +u; ROOT="$1"; ONLY="$2"; log(){ :; }; . "$T/sums.sh" ) || die "bash checksum section failed"
  tr -d '\r' < "$1/CHECKSUMS-SHA256.txt" > "$T/sh.txt"; cp "$1/CHECKSUMS-SHA256.txt" "$T/sh.raw"
}
cat > "$T/run.ps1" <<'EOF'
param($Root, $Only, $TrModel)
$src = [IO.File]::ReadAllText((Join-Path $PWD 'Get-OfflineLibrary.ps1')) -replace "`r`n", "`n"
$m = [regex]::Match($src, '(?ms)^# =+ drive check \(#28\).*?(?=^# =+ self-check)')
if(-not $m.Success){ Write-Host 'drive check section not found in Get-OfflineLibrary.ps1'; exit 1 }
function Log($s){ }
$Only = if($Only){ @($Only -split ' ') } else { $null }
Invoke-Expression $m.Value
EOF
run_ps(){ # dir only
  "$PS" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$T/run.ps1" "$1" "$2" "$TR_MODEL" || die "PowerShell checksum section failed"
  cp "$1/CHECKSUMS-SHA256.txt" "$T/ps.raw"
}
D="$T/drive"
for only in "" "translate medlineplus"; do
  make_drive "$D"; run_sh "$D" "$only"
  make_drive "$D"; run_ps "$D" "$only"
  cmp -s "$T/sh.raw" "$T/ps.raw" || { diff "$T/sh.raw" "$T/ps.raw"; die "bash and PowerShell lists differ (only='$only')"; }
  echo "  ok: identical lists (only='${only:-full run}')"
done

# The --only list: what translate and medlineplus write is re-hashed, the rest is kept.
L="$T/sh.txt"; hash(){ (cd "$D" && { sha256sum "$1" 2>/dev/null || shasum -a 256 "$1"; }); }
for f in ./AI-Offline/TRANSLATE.bat "./AI-Offline/models/$TR_MODEL" ./README.html ./Medical/MedlinePlus/MedlinePlus-Health-Topics.html; do
  grep -qxF "$(hash "$f")" "$L" || die "not re-hashed: $f"
done
for f in ./AI-Offline/engine/BUILD.txt ./AI-Offline/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf "./a b/space file.txt"; do
  grep -qxF "$Z  $f" "$L" || die "line not kept: $f"
done
grep -qF ./gone.txt "$L" && die "a file that is gone is still listed"
grep -qF _download.log "$L" && die "the log is listed"
[ "$(grep -c . "$L")" = 7 ] || { cat "$L"; die "expected 7 lines"; }
echo "Checksum list parity: OK"
