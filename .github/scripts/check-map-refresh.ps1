# Issue #98: run the shipped map helpers against local ZIPs, without downloads or Java.
# Windows PowerShell 5.1; Bash checks also need Git Bash and unzip on PATH.
param([switch]$Baseline, [ValidateSet('PowerShell','Bash')][string[]]$Helpers = @('PowerShell','Bash'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ProgressPreference = 'SilentlyContinue'
foreach($file in @('Get-OfflineLibrary.ps1','build-readme-index.ps1','.github/scripts/check-map-refresh.ps1')){
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repo $file), [ref]$null, [ref]$errors)
  if($errors){ throw ($errors | Out-String) }
  Write-Host "PASS: parse $file"
}
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('oel-map-' + [guid]::NewGuid().ToString('N'))
function Assert($ok, $message) { if(-not $ok){ throw $message }; Write-Host "PASS: $message" }
function Source($file) {
  if($Baseline) {
    $text = & git -C $repo show "upstream/main:$file"
    if($LASTEXITCODE){ throw "Cannot read baseline $file" }
    return $text -join "`n"
  }
  [IO.File]::ReadAllText((Join-Path $repo $file)) -replace "`r`n", "`n"
}
function MakeZip($path, $text) {
  if(Test-Path -LiteralPath $path){ Remove-Item -LiteralPath $path -Force }
  $zip = [IO.Compression.ZipFile]::Open($path, 'Create')
  try {
    $entry = $zip.CreateEntry('Test region.obf')
    $entry.LastWriteTime = [DateTimeOffset]'2001-01-01T00:00:00Z'
    $writer = New-Object IO.StreamWriter($entry.Open())
    try { $writer.Write($text) } finally { $writer.Dispose() }
  } finally { $zip.Dispose() }
}
try {
  foreach($kind in $Helpers){
    $maps = Join-Path $tmp "$kind library with spaces\OsmAnd"
    $viewer = Join-Path $maps 'MapViewer'
    New-Item -ItemType Directory -Force $viewer | Out-Null
    if($kind -eq 'PowerShell'){
      $src = Source 'Get-OfflineLibrary.ps1'
      $match = [regex]::Match($src, '(?ms)^  \$prep = @''\n(.*?)^''@')
      Assert $match.Success 'PowerShell helper found'
      $helper = Join-Path $viewer 'prepare-maps.ps1'
      [IO.File]::WriteAllText($helper, $match.Groups[1].Value)
    } else {
      $src = Source 'get-offline-library.sh'
      $match = [regex]::Match($src, '(?ms)cat > "\$MVD/VIEW-MAPS-ON-PC\.sh" <<''EOS''\n(.*?)^EOS')
      Assert $match.Success 'Bash helper found'
      $helper = Join-Path $viewer 'VIEW-MAPS-ON-PC.sh'
      [IO.File]::WriteAllText($helper, $match.Groups[1].Value)
      New-Item -ItemType Directory -Force (Join-Path $viewer 'app'),(Join-Path $viewer 'jre') | Out-Null
      [IO.File]::WriteAllText((Join-Path $viewer 'app\OsmAndMapCreator.sh'), "exit 0`n")
    }
    function RunHelper {
      if($kind -eq 'PowerShell'){
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $helper
      } else {
        & bash ($helper.Replace('\','/'))
      }
      $script:helperExit = $LASTEXITCODE
    }
    $archive = Join-Path $maps 'Test region.obf.zip'
    $target = Join-Path $maps 'obf\Test region.obf'
    RunHelper
    Assert ($helperExit -eq 0) "$kind empty map folder succeeds"
    MakeZip $archive 'OLD'
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'OLD') "$kind initial extraction"
    MakeZip $archive 'NEW'
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'NEW') "$kind refreshes same-size edition with old ZIP dates"
    $sentinel = [datetime]::SpecifyKind([datetime]'2002-02-02', [DateTimeKind]::Utc)
    [IO.File]::SetLastWriteTimeUtc($target, $sentinel)
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::GetLastWriteTimeUtc($target) -eq $sentinel) "$kind unchanged archive skips rewriting"
    Get-ChildItem -LiteralPath (Split-Path $target) -File |
      Where-Object { $_.FullName -ne $target } | ForEach-Object { [IO.File]::WriteAllText($_.FullName, '') }
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'NEW') "$kind empty stamp safely regenerated"
    # Old installs have a map but no stamp. They must be refreshed once.
    Get-ChildItem -LiteralPath (Split-Path $target) -File |
      Where-Object { $_.FullName -ne $target } | Remove-Item -Force
    [IO.File]::WriteAllText($target, 'OLD')
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'NEW') "$kind legacy map without stamp refreshed"
    Remove-Item -LiteralPath $target -Force
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'NEW') "$kind missing target restored"
    [IO.File]::WriteAllText($archive, 'not a zip')
    RunHelper
    Assert ($helperExit -ne 0 -and [IO.File]::ReadAllText($target) -eq 'NEW') "$kind corrupt archive preserves previous map and reports failure"
    MakeZip $archive 'END'
    RunHelper
    Assert ($helperExit -eq 0 -and [IO.File]::ReadAllText($target) -eq 'END') "$kind recovers after invalid archive"
  }
} finally {
  if(Test-Path -LiteralPath $tmp){ Remove-Item -LiteralPath $tmp -Recurse -Force }
  if(Test-Path -LiteralPath $tmp){ throw "Cleanup failed: $tmp" }
  Write-Host "CLEANUP: removed $tmp"
}
