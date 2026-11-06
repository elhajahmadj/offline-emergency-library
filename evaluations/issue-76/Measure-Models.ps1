# Windows CPU evaluation only. Never changes the installed library or model lineup.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$EngineDir,
  [Parameter(Mandatory=$true)][string]$ModelDir,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [ValidateRange(1,32)][int]$Threads = 4,
  [ValidateRange(1024,65535)][int]$Port = 18076
)
$ErrorActionPreference = 'Stop'
$engine = Join-Path $EngineDir 'llama-server.exe'
$models = @(
  'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
  'Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
  'Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf',
  'Qwen2.5-7B-Instruct-Q4_K_M.gguf'
)
$questions = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'questions.json') -Raw | ConvertFrom-Json
foreach ($path in @($engine) + @($models | ForEach-Object { Join-Path $ModelDir $_ })) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file missing: $path" }
}
if (Test-Path -LiteralPath $OutputDir) { throw "OutputDir must be a new directory: $OutputDir" }
$listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
try { $listener.Start() } finally { $listener.Stop() }
[void](New-Item -ItemType Directory -Path $OutputDir)
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
$base = "http://127.0.0.1:$Port"
$system = 'You are an offline emergency planning assistant. Answer concisely. Do not invent facts or source quotations. State when necessary information is missing.'
$versionInfo = New-Object Diagnostics.ProcessStartInfo
$versionInfo.FileName = $engine
$versionInfo.Arguments = '--version'
$versionInfo.UseShellExecute = $false
$versionInfo.CreateNoWindow = $true
$versionInfo.RedirectStandardOutput = $true
$versionInfo.RedirectStandardError = $true
$versionProcess = New-Object Diagnostics.Process
$versionProcess.StartInfo = $versionInfo
[void]$versionProcess.Start()
if (-not $versionProcess.WaitForExit(10000)) { $versionProcess.Kill(); throw 'Engine version command timed out' }
if ($versionProcess.ExitCode -ne 0) { throw "Engine version command failed: $($versionProcess.ExitCode)" }
$engineVersion = ($versionProcess.StandardOutput.ReadToEnd() + $versionProcess.StandardError.ReadToEnd()).Trim()
$versionProcess.Dispose()
$manifest = [ordered]@{
  date_utc = [DateTime]::UtcNow.ToString('o')
  os = [Environment]::OSVersion.VersionString
  powershell = $PSVersionTable.PSVersion.ToString()
  cpu = @((Get-CimInstance Win32_Processor).Name)
  logical_processors = [Environment]::ProcessorCount
  physical_ram_bytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
  free_ram_before_bytes = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1024
  engine_sha256 = (Get-FileHash -LiteralPath $engine -Algorithm SHA256).Hash.ToLowerInvariant()
  engine_version = $engineVersion
  questions_sha256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'questions.json') -Algorithm SHA256).Hash.ToLowerInvariant()
  settings = @{ threads=$Threads; context=4096; gpu_layers=0; parallel=1; temperature=0; seed=76; max_tokens=384; cache_prompt=$false; system=$system }
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDir 'manifest.json') -Encoding UTF8
foreach ($model in $models) {
  $modelPath = Join-Path $ModelDir $model
  $stem = [IO.Path]::GetFileNameWithoutExtension($model)
  $process = $null
  $record = [ordered]@{
    model = $model
    model_bytes = (Get-Item -LiteralPath $modelPath).Length
    model_sha256 = (Get-FileHash -LiteralPath $modelPath -Algorithm SHA256).Hash.ToLowerInvariant()
    server_arguments = @('-m', $model, '-c', '4096', '-ngl', '0', '-t', "$Threads", '-tb', "$Threads", '-np', '1', '--offline', '--no-cache-prompt', '--cache-ram', '0', '--host', '127.0.0.1', '--port', "$Port")
    answers = @()
    cleanup = $null
  }
  try {
    Write-Host "START $model"
    $load = [Diagnostics.Stopwatch]::StartNew()
    $arguments = @('-m', "`"$modelPath`"", '-c', '4096', '-ngl', '0', '-t', "$Threads", '-tb', "$Threads", '-np', '1', '--offline', '--no-cache-prompt', '--cache-ram', '0', '--host', '127.0.0.1', '--port', "$Port")
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $OutputDir "$stem.stdout.log") -RedirectStandardError (Join-Path $OutputDir "$stem.stderr.log")
    $ready = $false
    for ($attempt=0; $attempt -lt 120; $attempt++) {
      if ($process.HasExited) { throw "Server exited while loading $model; read its stderr log." }
      try {
        $health = Invoke-WebRequest -UseBasicParsing -Uri "$base/health" -TimeoutSec 2
        if ($health.StatusCode -eq 200) { $ready = $true; break }
      } catch [Net.WebException] {
        Start-Sleep -Milliseconds 500
      }
    }
    if (-not $ready) { throw "Server readiness budget exhausted for $model" }
    $load.Stop()
    $record.load_seconds = $load.Elapsed.TotalSeconds
    $record.health_status = [int]$health.StatusCode
    # Warm up once with the same request for every model. It is not a scored question.
    $warmup = @{ messages=@(@{role='user';content='Reply with only OK.'}); temperature=0; seed=76; max_tokens=16; cache_prompt=$false; stream=$false } | ConvertTo-Json -Depth 6 -Compress
    [void](Invoke-WebRequest -UseBasicParsing -Uri "$base/v1/chat/completions" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($warmup)) -TimeoutSec 180)
    foreach ($question in $questions) {
      $body = @{
        messages = @(@{role='system';content=$system}, @{role='user';content=$question.prompt})
        temperature=0; seed=76; max_tokens=384; cache_prompt=$false; stream=$false
      } | ConvertTo-Json -Depth 6 -Compress
      $watch = [Diagnostics.Stopwatch]::StartNew()
      $response = Invoke-WebRequest -UseBasicParsing -Uri "$base/v1/chat/completions" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 180
      $watch.Stop()
      $parsed = $response.Content | ConvertFrom-Json
      if ($response.StatusCode -ne 200 -or [string]::IsNullOrWhiteSpace($parsed.choices[0].message.content)) { throw "Empty or unsuccessful answer: $model/$($question.id)" }
      if ($parsed.timings.predicted_per_second -le 0) { throw "Missing generation timing: $model/$($question.id)" }
      $process.Refresh()
      $record.answers += [ordered]@{
        question_id = $question.id
        status = [int]$response.StatusCode
        content_type = $response.Headers['Content-Type']
        wall_seconds = $watch.Elapsed.TotalSeconds
        peak_working_set_bytes = $process.PeakWorkingSet64
        working_set_bytes = $process.WorkingSet64
        response = $parsed
      }
      $record | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $OutputDir "$stem.json") -Encoding UTF8
      Write-Host "ANSWER $model $($question.id) status=$($response.StatusCode)"
    }
  } finally {
    if ($null -ne $process) {
      if (-not $process.HasExited) { $process.Kill() }
      if (-not $process.WaitForExit(10000)) { throw "Server did not exit: $($process.Id)" }
      $record.cleanup = @{ pid=$process.Id; exited=$process.HasExited }
      $record | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $OutputDir "$stem.json") -Encoding UTF8
      $process.Dispose()
      # Prove the task's port is released before starting the next model.
      try { $listener.Start() } finally { $listener.Stop() }
    }
  }
  Write-Host "DONE $model"
}
Write-Host 'EVALUATION PASS'
