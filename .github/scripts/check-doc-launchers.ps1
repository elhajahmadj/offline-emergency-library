# Offline execution check for the shipped Windows manual reader launcher (#158).
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('doc-launchers-' + [guid]::NewGuid().ToString('N'))
$oldArch = $env:PROCESSOR_ARCHITECTURE
$oldArgs = $env:OEL_DOC_ARGS
try {
  $root = Join-Path $tmp 'original library'
  $ao = Join-Path $root 'AI-Offline'
  New-Item -ItemType Directory -Force (Join-Path $ao 'Manual-QA'),(Join-Path $ao 'models') | Out-Null
  Copy-Item (Join-Path $repo 'doc-qa\START-DOCS.bat') (Join-Path $ao 'Manual-QA')
  Set-Content (Join-Path $ao 'models\Llama-3.2-3B-Instruct-Q4_K_M.gguf') 'fixture model'
  $stub = Join-Path $tmp 'stub.exe'
  Add-Type -OutputAssembly $stub -OutputType ConsoleApplication -TypeDefinition @'
using System;
using System.IO;
public class DocLauncherFixture {
    public static void Main(string[] args) {
        File.WriteAllLines(Environment.GetEnvironmentVariable("OEL_DOC_ARGS"), args);
    }
}
'@
  # Windows zip assets unpack directly under the architecture directory.
  $moved = Join-Path $tmp 'moved here\Library copy'
  New-Item -ItemType Directory -Force (Split-Path $moved -Parent) | Out-Null
  Move-Item -LiteralPath $root -Destination $moved
  $here = Join-Path $moved 'AI-Offline\Manual-QA'
  $env:OEL_DOC_ARGS = Join-Path $tmp 'actual'
  $expected = @('-m',"$here\..\models\Llama-3.2-3B-Instruct-Q4_K_M.gguf",
    '-c','4096','-ngl','0','-t','4','--offline','--host','127.0.0.1','--port','8081','--path',"$here\..\..")
  foreach($arch in 'AMD64','ARM64'){
    $engineRoot = Join-Path $moved 'AI-Offline\engine'
    if(Test-Path -LiteralPath $engineRoot){ Remove-Item -LiteralPath $engineRoot -Recurse -Force }
    $engineArch = if($arch -eq 'ARM64'){ 'arm64' } else { 'x64' }
    $engine = Join-Path $engineRoot $engineArch
    New-Item -ItemType Directory -Force $engine | Out-Null
    Copy-Item $stub (Join-Path $engine 'llama-server.exe')
    $env:PROCESSOR_ARCHITECTURE = $arch
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /c ""' + (Join-Path $here 'START-DOCS.bat') + '""'
    $info.WorkingDirectory = $tmp
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $process = [Diagnostics.Process]::Start($info)
    try {
      # Satisfy the launcher's real pause without editing its executable line.
      $process.StandardInput.WriteLine()
      $process.StandardInput.Close()
      if(-not $process.WaitForExit(15000)){
        $process.Kill()
        $process.WaitForExit()
        throw 'START-DOCS.bat did not exit within 15 seconds'
      }
      if($process.ExitCode -ne 0){ throw "START-DOCS.bat exited $($process.ExitCode)" }
    } finally { $process.Dispose() }
    if(-not (Test-Path -LiteralPath $env:OEL_DOC_ARGS)){ throw "Engine was not executed for $arch" }
    $actual = [IO.File]::ReadAllLines($env:OEL_DOC_ARGS)
    if(($actual -join "`n") -cne ($expected -join "`n")){ throw "Server arguments changed for ${arch}: $actual" }
    Write-Host "PASS: START-DOCS.bat executes $arch engine after relocation; argv:"
    $actual | ForEach-Object { Write-Host $_ }
    Remove-Item -LiteralPath $env:OEL_DOC_ARGS
  }
} finally {
  $env:PROCESSOR_ARCHITECTURE = $oldArch
  $env:OEL_DOC_ARGS = $oldArgs
  if(Test-Path -LiteralPath $tmp){ Remove-Item -LiteralPath $tmp -Recurse -Force }
}
