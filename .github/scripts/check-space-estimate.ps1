# Run the installer's real space-estimate block offline (#276): the estimate must be logged
# even when the free space cannot be read (a network share has no PSDrive).
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$src = [IO.File]::ReadAllText((Join-Path $repo 'Get-OfflineLibrary.ps1'))
$start = $src.IndexOf('# Space estimate for the chosen flags (#68): Get-SpaceEstimate, defined above.')
$end = $src.IndexOf('# ---------------------------------------------------------------- folder tree')
if($start -lt 0 -or $end -le $start){ throw 'space-estimate block markers not found' }
$block = $src.Substring($start, $end - $start)
$gb = [regex]::Match($src, '(?m)^function Gb\(.*$').Value
if(-not $gb){ throw 'Gb function not found' }

function Run-Block($root, [switch]$NoDrive){
  $script:out = New-Object System.Collections.Generic.List[string]
  $code = $gb + "`n" + @'
function Log($m){ $script:out.Add("$m") }
function Get-SpaceEstimate($m){ [ordered]@{ 'core' = 1.5 } }
$SkipMaps = $true; $BmOnly = $false; $Kolibri = $false; $sel = @()
'@ + "`n"
  if($NoDrive){ $code += "function Get-Item { [pscustomobject]@{ PSDrive = `$null } }`n" }
  $code += "`$Root = '$root'`n" + $block
  & ([scriptblock]::Create($code))
  $script:out
}

$fail = 0
function Expect($name, $lines, $pattern){
  if(-not ($lines | Where-Object { $_ -match $pattern })){ Write-Host "FAIL ${name}: no line matches '$pattern'"; $lines | ForEach-Object { Write-Host "    $_" }; $script:fail++ }
  else { Write-Host "  OK   ${name}: $pattern" }
}

$unc = Run-Block '\\nas\share\OfflineLibrary' -NoDrive
Expect 'network share' $unc 'free space: unknown'
Expect 'network share' $unc '^Space estimate for this selection: about 1\.5 GB'
Expect 'network share' $unc '^\s+1\.5 GB  core'

$local = Run-Block ([IO.Path]::GetTempPath())
Expect 'local drive' $local 'free space: \d+\.\d GB'
Expect 'local drive' $local '^Space estimate for this selection: about 1\.5 GB'
Expect 'local drive' $local '^Conservative space budget: 1\.5 GB\. Free: '

if($fail){ exit 1 }
Write-Host 'Space estimate checks: OK'
