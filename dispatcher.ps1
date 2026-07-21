param(
    [Parameter(Mandatory = $true)]$Job,
    [string]$BasePath = 'C:\Users\chide\Downloads\mailing'
)

$statePath = Join-Path $BasePath 'workers\worker_state.json'
$workersDir = Join-Path $BasePath 'workers'
$clusterJson = Join-Path $BasePath 'web\cluster.json'
$clusterRiskJson = Join-Path $BasePath 'web\cluster_risk.json'

function Save-State {
    param([Parameter(Mandatory=$true)]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8

    if (-not (Test-Path (Split-Path $clusterJson))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $clusterJson) | Out-Null
    }
    if (-not (Test-Path (Split-Path $clusterRiskJson))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $clusterRiskJson) | Out-Null
    }

    if (Test-Path $clusterJson) {
        try {
            $payload = Get-Content -Path $clusterJson -Raw | ConvertFrom-Json
        } catch {
            $payload = [ordered]@{ workers = @{} }
        }
    } else {
        $payload = [ordered]@{ workers = @{} }
    }

    $payload.workers = $State.workers
    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $clusterJson -Encoding UTF8
}

function Save-ClusterRisk {
    param([Parameter(Mandatory=$true)]$State)

    $heatmap = [ordered]@{}
    foreach ($entry in $State.workers.PSObject.Properties) {
        $heatmap[$entry.Name] = [ordered]@{
            role = $entry.Value.role
            health = $entry.Value.health_score
            risk = 100 - [int]$entry.Value.health_score
        }
    }
    $heatmap | ConvertTo-Json -Depth 10 | Set-Content -Path $clusterRiskJson -Encoding UTF8
}

$healthHelperPath = Join-Path $BasePath 'worker_health_score.ps1'
if (Test-Path $healthHelperPath) {
    . $healthHelperPath
}

if (-not (Test-Path $statePath)) {
    $defaultState = [ordered]@{
        workers = [ordered]@{
            worker_browser_1   = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'browser'; capacity = 3; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@() } }
            worker_signature_1 = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'signature'; capacity = 2; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@() } }
            worker_email_1     = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'email'; capacity = 5; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@() } }
            worker_render_1    = [ordered]@{ status = 'Healthy'; fail_count = 0; role = 'render'; capacity = 2; load = 0; last_assigned_at = $null; health_score = 100; metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@() } }
        }
        anomalies = @()
    }
    New-Item -ItemType Directory -Force -Path $workersDir | Out-Null
    Save-State $defaultState
}

$state = Get-Content -Path $statePath -Raw | ConvertFrom-Json
$jobType = if ($Job.type) { [string]$Job.type } else { 'browser' }
$priority = if ($Job.priority) { [int]$Job.priority } else { 3 }

Refresh-AllWorkerHealthScores -State $state
Save-State $state
Save-ClusterRisk -State $state

$eligible = @($state.workers.PSObject.Properties | Where-Object {
    $_.Value.status -eq 'Healthy' -and $_.Value.role -eq $jobType -and ($_.Value.health_score -ge 60 -or -not $_.Value.health_score)
})

if ($eligible.Count -eq 0) {
    Write-Host "All workers degraded or quarantined for role $jobType — entering cluster fallback mode." -ForegroundColor Yellow
    $eligible = @($state.workers.PSObject.Properties | Where-Object {
        $_.Value.status -in @('Healthy', 'Degraded') -and $_.Value.role -eq $jobType
    })
    if ($eligible.Count -eq 0) {
        Write-Host "NO ELIGIBLE WORKERS AVAILABLE — QUEUING OR ESCALATING" -ForegroundColor Red
        return [pscustomobject]@{ target = $null; role = $jobType; status = 'queued'; priority = $priority }
    }
}

$weighted = @()
foreach ($entry in $eligible) {
    $capacity = [int]$entry.Value.capacity
    $load = [int]$entry.Value.load
    $remaining = $capacity - $load
    $weight = if ($remaining -gt 0) { $remaining } elseif ($priority -le 2) { 1 } else { 0 }

    if ($weight -gt 0) {
        1..$weight | ForEach-Object { $weighted += $entry }
    }
}

if ($weighted.Count -eq 0) {
    if ($priority -le 2) {
        $candidate = $eligible | Sort-Object {[int]$_.Value.load} | Select-Object -First 1
        $weighted += $candidate
    } else {
        Write-Host "All eligible workers are at capacity and job is low priority; queuing." -ForegroundColor Yellow
        return [pscustomobject]@{ target = $null; role = $jobType; status = 'queued'; priority = $priority }
    }
}

$selected = $weighted | Get-Random
$target = $selected.Name
$targetRole = [string]$selected.Value.role

$selected.Value.load = [int]$selected.Value.load + 1
$selected.Value.last_assigned_at = (Get-Date).ToString('o')
Save-State $state

$workerScript = Join-Path $workersDir ("worker_{0}.ps1" -f $targetRole)
if (-not (Test-Path $workerScript)) {
    Write-Host "Worker script not found for role $($targetRole): $workerScript" -ForegroundColor Red
    return [pscustomobject]@{ target = $target; role = $jobType; status = 'error'; error = 'Worker script missing' }
}

Write-Host "Dispatching job of type $jobType to $target ($targetRole) with priority $priority"

$workerResult = $null
$status = 'queued'
$jobErrorCount = 0
$jobLatencyMs = 120
$jobCpuPct = 35
$jobMemMb = 160

try {
    $workerResult = & $workerScript -Job $Job
    if ($workerResult -is [System.Management.Automation.PSCustomObject]) {
        if ($workerResult.latency_ms) { $jobLatencyMs = [int]$workerResult.latency_ms }
        if ($workerResult.cpu_pct) { $jobCpuPct = [int]$workerResult.cpu_pct }
        if ($workerResult.mem_mb) { $jobMemMb = [int]$workerResult.mem_mb }
        if ($workerResult.error_count) { $jobErrorCount = [int]$workerResult.error_count }
    }
    if ($selected.Value.fail_count -gt 0) { $selected.Value.fail_count = 0 }
    $status = 'completed'
} catch {
    $selected.Value.fail_count = [int]$selected.Value.fail_count + 1
    $jobErrorCount = 1
    if ($selected.Value.fail_count -ge 3) {
        $selected.Value.status = 'Unhealthy'
        Write-Host "Marking $($target) as Unhealthy after repeated failures." -ForegroundColor Red
    }
    Write-Host "Job execution failed on $($target): $($_.Exception.Message)" -ForegroundColor Red
    $status = 'failed'
} finally {
    Record-WorkerJobMetrics -Job ([pscustomobject]@{ target = $target }) -Success ($status -eq 'completed') -LatencyMs $jobLatencyMs -CpuPct $jobCpuPct -MemMb $jobMemMb -ErrorCount $jobErrorCount -StatePath $statePath
    $state = Get-Content -Path $statePath -Raw | ConvertFrom-Json
    if ($state.workers.$target) {
        $state.workers.$target.load = [math]::Max(0, [int]$state.workers.$target.load - 1)
    }
    Save-State $state
}

return [pscustomobject]@{ target = $target; role = $jobType; workerRole = $targetRole; status = $status; priority = $priority; assigned_at = (Get-Date).ToString('o') }
