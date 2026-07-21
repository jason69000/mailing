$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workersDir = Join-Path $repoRoot 'workers'
New-Item -ItemType Directory -Force -Path $workersDir | Out-Null

$statePath = Join-Path $workersDir 'worker_state.json'
$state = [ordered]@{
    workers = [ordered]@{
        worker_browser_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'browser'; capacity = 3; load = 0; last_assigned_at = $null }
        worker_signature_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'signature'; capacity = 2; load = 0; last_assigned_at = $null }
        worker_email_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'email'; capacity = 1; load = 0; last_assigned_at = $null }
        worker_render_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'render'; capacity = 2; load = 0; last_assigned_at = $null }
    }
}
$state | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath -Encoding UTF8

$workerScript = Join-Path $workersDir 'worker_browser.ps1'
Set-Content -Path $workerScript -Value 'param($Job) Write-Host "browser:$($Job.payload)"' -Encoding UTF8

$dispatchResult1 = & (Join-Path $repoRoot 'dispatcher.ps1') -BasePath $repoRoot -Job @{ type = 'browser'; payload = 'INV-1001'; priority = 1 }
$dispatchResult2 = & (Join-Path $repoRoot 'dispatcher.ps1') -BasePath $repoRoot -Job @{ type = 'render'; payload = 'INV-1002'; priority = 2 }
$dispatchResult3 = & (Join-Path $repoRoot 'dispatcher.ps1') -BasePath $repoRoot -Job @{ type = 'email'; payload = 'INV-1003'; priority = 1 }

foreach ($result in @($dispatchResult1, $dispatchResult2, $dispatchResult3)) {
    if (-not $result -or [string]$result.target -eq '') {
        throw 'Expected dispatcher to return a target worker.'
    }
}

$updatedState = Get-Content -Path $statePath -Raw | ConvertFrom-Json
foreach ($result in @($dispatchResult1, $dispatchResult2, $dispatchResult3)) {
    if ($updatedState.workers.$($result.target).status -ne 'Healthy') {
        throw "Expected selected worker $($result.target) to remain healthy."
    }
}

Write-Host ('PASS target1={0} target2={1} target3={2}' -f $dispatchResult1.target, $dispatchResult2.target, $dispatchResult3.target)
