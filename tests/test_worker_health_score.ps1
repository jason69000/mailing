$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workersDir = Join-Path $repoRoot 'workers'
New-Item -ItemType Directory -Force -Path $workersDir | Out-Null

$statePath = Join-Path $workersDir 'worker_state.json'
$state = [ordered]@{
    workers = [ordered]@{
        worker_browser_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'browser'; capacity = 3; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(300, 320, 340); errors_per_min=@(0); cpu_pct=@(80, 82); mem_mb=@(280, 290) } }
        worker_signature_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'signature'; capacity = 2; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(90); errors_per_min=@(0); cpu_pct=@(35); mem_mb=@(160) } }
    }
}
$state | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding UTF8

$workerScript = Join-Path $workersDir 'worker_browser.ps1'
Set-Content -Path $workerScript -Value 'param($Job) Write-Host "browser:$($Job.payload)"' -Encoding UTF8

$dispatchResult = & (Join-Path $repoRoot 'dispatcher.ps1') -BasePath $repoRoot -Job @{ type = 'browser'; payload = 'INV-1005'; priority = 1 }
if (-not $dispatchResult -or [string]$dispatchResult.target -eq '') {
    throw 'Expected dispatcher to return a target worker.'
}

$updatedState = Get-Content -Path $statePath -Raw | ConvertFrom-Json
$selected = $updatedState.workers.$($dispatchResult.target)
if ($selected.health_score -gt 60) {
    Write-Host "PASS worker selected with health_score=$($selected.health_score)"
} else {
    throw "Expected selected worker health_score to remain above 60, got $($selected.health_score)."
}

$browserHealth = $updatedState.workers.worker_browser_1.health_score
if ($browserHealth -lt 60) {
    throw "Expected browser worker health score to stay stable, got $browserHealth"
}

Write-Host "PASS selected=$($dispatchResult.target) score=$browserHealth"
