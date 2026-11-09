# Issue #107: execute the real generated Windows OffRoad launcher without network or Java.
# Verifies local NTFS junctions survive exFAT sources and are recreated after relocation.
param()
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('oel-offroad-' + [guid]::NewGuid().ToString('N'))
function Assert($ok, $message) { if(-not $ok){ throw $message }; Write-Host "PASS: $message" }
function JunctionTarget($path) { [string](Get-Item -LiteralPath $path -Force).Target }
try {
  $source = [IO.File]::ReadAllText((Join-Path $repo 'Get-OfflineLibrary.ps1')) -replace "`r`n", "`n"
  $prepMatch = [regex]::Match($source, '(?ms)^  \$prep = @''\n(.*?)^''@')
  $batchMatch = [regex]::Match($source, '(?ms)^  \$offbat = @"\n(.*?)^"@')
  Assert ($prepMatch.Success -and $batchMatch.Success) 'generated PowerShell map helpers found'

  $library = Join-Path $tmp 'Library with spaces'
  $maps = Join-Path $library 'OsmAnd'
  $viewer = Join-Path $maps 'MapViewer-Desktop'
  $obf = Join-Path $maps 'obf'
  $fakeBin = Join-Path $tmp 'fake-java'
  New-Item -ItemType Directory -Force $viewer,$obf,$fakeBin,(Join-Path $viewer 'offroad') | Out-Null
  [IO.File]::WriteAllText((Join-Path $viewer 'prepare-maps.ps1'), $prepMatch.Groups[1].Value)
  $batch = Join-Path $viewer 'VIEW-MAPS-OFFLINE.bat'
  [IO.File]::WriteAllText($batch, ($batchMatch.Groups[1].Value -replace "`n", "`r`n"), [Text.Encoding]::ASCII)
  [IO.File]::WriteAllText((Join-Path $viewer 'offroad\OffRoad.jar'), 'fixture')
  $sentinel = Join-Path $obf 'region.obf'
  [IO.File]::WriteAllText($sentinel, 'current map')
  $capture = Join-Path $tmp 'java-args.txt'
  $java = @'
@echo off
>%CAPTURE% echo %*
'@
  [IO.File]::WriteAllText((Join-Path $fakeBin 'java.cmd'), ($java -replace "`n", "`r`n"), [Text.Encoding]::ASCII)

  $env:LOCALAPPDATA = Join-Path $tmp 'local-app-data'
  $env:CAPTURE = $capture
  $env:PATH = $fakeBin + ';' + $env:PATH
  $offHome = Join-Path $env:LOCALAPPDATA 'OfflineLibrary-OffRoad'
  $state = Join-Path $offHome '.OffRoad'
  $link = Join-Path $state 'maps'
  $stale = Join-Path $tmp 'stale-map-target'
  New-Item -ItemType Directory -Force $state,$stale | Out-Null
  $staleSentinel = Join-Path $stale 'old-region.obf'
  [IO.File]::WriteAllText($staleSentinel, 'stale map')
  New-Item -ItemType Junction -Path $link -Target $stale | Out-Null

  & cmd.exe /c $batch
  Assert ($LASTEXITCODE -eq 0) 'launcher replaces a stale junction and exits successfully'
  Assert ((JunctionTarget $link) -eq $obf) 'junction targets the current OBF folder'
  Assert ((Test-Path -LiteralPath $capture) -and (([IO.File]::ReadAllText($capture)) -like "*-Duser.home=$offHome*")) 'Java launches with isolated local OffRoad state'
  Assert ((Test-Path -LiteralPath $sentinel) -and (Test-Path -LiteralPath $staleSentinel)) 'junction replacement preserves both map folders'

  $movedLibrary = Join-Path $tmp 'Moved library'
  Move-Item -LiteralPath $library -Destination $movedLibrary
  $movedMaps = Join-Path $movedLibrary 'OsmAnd'
  $movedObf = Join-Path $movedMaps 'obf'
  $movedBatch = Join-Path $movedMaps 'MapViewer-Desktop\VIEW-MAPS-OFFLINE.bat'
  Remove-Item -LiteralPath $capture -Force
  & cmd.exe /c $movedBatch
  Assert ($LASTEXITCODE -eq 0) 'launcher exits successfully after relocation'
  Assert ((JunctionTarget $link) -eq $movedObf) 'launcher recreates the junction for the moved OBF folder'
  Assert (Test-Path -LiteralPath $capture) 'Java launches again after relocation'
} finally {
  if($link){ & cmd.exe /c rmdir "$link" 2>$null }
  if(Test-Path -LiteralPath $tmp){ Remove-Item -LiteralPath $tmp -Recurse -Force }
  if(Test-Path -LiteralPath $tmp){ throw "Cleanup failed: $tmp" }
  Write-Host "CLEANUP: removed $tmp"
}
