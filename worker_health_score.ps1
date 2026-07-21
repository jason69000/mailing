$anomalyScorePath = Join-Path $PSScriptRoot 'anomaly_score.ps1'
if (Test-Path $anomalyScorePath) { . $anomalyScorePath }

function Normalize-History {
    param(
        [Parameter(Mandatory=$true)]$Values,
        [int]$Keep = 20
    )

    $history = @($Values)
    if ($history.Count -gt $Keep) {
        return $history[-$Keep..-1]
    }
    return $history
}

function Append-WorkerMetric {
    param(
        [Parameter(Mandatory=$true)]$Worker,
        [Parameter(Mandatory=$true)][string]$MetricName,
        [Parameter(Mandatory=$true)][double]$Value
    )
    if (-not $Worker.metrics) {
        $Worker.metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@(); baseline=[ordered]@{ latency_ms=300; errors_per_min=0.2; cpu_pct=50; mem_mb=200 } }
    }
    if (-not $Worker.metrics.$MetricName) {
        $Worker.metrics.$MetricName = @()
    }
    $Worker.metrics.$MetricName = @( $Worker.metrics.$MetricName + [double]$Value )
    $Worker.metrics.$MetricName = Normalize-History -Values $Worker.metrics.$MetricName -Keep 20
}

function Update-WorkerBaseline {
    param([Parameter(Mandatory=$true)]$Worker)

    if (-not $Worker.metrics) {
        $Worker.metrics = [ordered]@{ latency_ms=@(); errors_per_min=@(); cpu_pct=@(); mem_mb=@(); baseline=[ordered]@{ latency_ms=300; errors_per_min=0.2; cpu_pct=50; mem_mb=200 } }
    }
    if (-not $Worker.metrics.baseline) {
        $Worker.metrics.baseline = [ordered]@{ latency_ms=300; errors_per_min=0.2; cpu_pct=50; mem_mb=200 }
    }

    $prev = $Worker.metrics.baseline
    $latency = if ($Worker.metrics.latency_ms.Count) { [math]::Round(($Worker.metrics.latency_ms | Measure-Object -Average).Average, 1) } else { $prev.latency_ms }
    $errors = if ($Worker.metrics.errors_per_min.Count) { [math]::Round(($Worker.metrics.errors_per_min | Measure-Object -Average).Average, 2) } else { $prev.errors_per_min }
    $cpu = if ($Worker.metrics.cpu_pct.Count) { [math]::Round(($Worker.metrics.cpu_pct | Measure-Object -Average).Average, 1) } else { $prev.cpu_pct }
    $mem = if ($Worker.metrics.mem_mb.Count) { [math]::Round(($Worker.metrics.mem_mb | Measure-Object -Average).Average, 1) } else { $prev.mem_mb }

    $alpha = 0.2
    $Worker.metrics.baseline.latency_ms = [math]::Round(($prev.latency_ms * (1 - $alpha)) + ($latency * $alpha), 1)
    $Worker.metrics.baseline.errors_per_min = [math]::Round(($prev.errors_per_min * (1 - $alpha)) + ($errors * $alpha), 2)
    $Worker.metrics.baseline.cpu_pct = [math]::Round(($prev.cpu_pct * (1 - $alpha)) + ($cpu * $alpha), 1)
    $Worker.metrics.baseline.mem_mb = [math]::Round(($prev.mem_mb * (1 - $alpha)) + ($mem * $alpha), 1)
}

function Compute-WorkerHealthScore {
    param([Parameter(Mandatory=$true)]$Worker)

    Update-WorkerBaseline -Worker $Worker
    $m = $Worker.metrics
    $lat = if ($m.latency_ms.Count) { [math]::Round(($m.latency_ms | Measure-Object -Average).Average, 1) } else { $m.baseline.latency_ms }
    $err = if ($m.errors_per_min.Count) { [math]::Round(($m.errors_per_min | Measure-Object -Average).Average, 2) } else { $m.baseline.errors_per_min }
    $cpu = if ($m.cpu_pct.Count) { [math]::Round(($m.cpu_pct | Measure-Object -Average).Average, 1) } else { $m.baseline.cpu_pct }
    $mem = if ($m.mem_mb.Count) { [math]::Round(($m.mem_mb | Measure-Object -Average).Average, 1) } else { $m.baseline.mem_mb }

    $score = 0
    $score += Get-AnomalyScore $lat $m.baseline.latency_ms
    $score += Get-AnomalyScore $err $m.baseline.errors_per_min
    $score += Get-AnomalyScore $cpu $m.baseline.cpu_pct
    $score += Get-AnomalyScore $mem $m.baseline.mem_mb
    $health = 100 - $score

    if ([int]$Worker.fail_count -ge 1) {
        $health -= 8 * [int]$Worker.fail_count
    }
    if ($health -lt 0) { $health = 0 }
    if ($health -gt 100) { $health = 100 }

    return [math]::Round($health, 0)
}

function Assess-WorkerRisk {
    param([Parameter(Mandatory=$true)]$Worker)

    if ($Worker.health_score -lt 40) {
        $Worker.status = 'Quarantined'
        Write-Host "Predictive quarantine engaged for worker due to low health score ($($Worker.health_score))." -ForegroundColor Yellow
    } elseif ($Worker.health_score -lt 60) {
        $Worker.status = 'Degraded'
    } else {
        $Worker.status = 'Healthy'
    }
}

function Refresh-AllWorkerHealthScores {
    param([Parameter(Mandatory=$true)]$State)

    foreach ($entry in $State.workers.PSObject.Properties) {
        if (-not $entry.Value.health_score) { $entry.Value.health_score = 100 }
        $entry.Value.health_score = Compute-WorkerHealthScore -Worker $entry.Value
        Assess-WorkerRisk -Worker $entry.Value
    }
}

function Record-WorkerJobMetrics {
    param(
        [Parameter(Mandatory=$true)]$Job,
        [Parameter(Mandatory=$true)][bool]$Success,
        [Parameter(Mandatory=$true)][int]$LatencyMs,
        [Parameter(Mandatory=$true)][int]$CpuPct,
        [Parameter(Mandatory=$true)][int]$MemMb,
        [int]$ErrorCount = 0,
        [string]$StatePath = $null
    )

    if (-not $Job.target) { return }
    if (-not $StatePath) { $StatePath = $global:statePath }
    if (-not $StatePath) { return }

    $state = Get-Content -Path $StatePath -Raw | ConvertFrom-Json
    if (-not $state -or -not $state.workers.$($Job.target)) { return }

    $worker = $state.workers.$($Job.target)
    Append-WorkerMetric -Worker $worker -MetricName 'latency_ms' -Value $LatencyMs
    Append-WorkerMetric -Worker $worker -MetricName 'cpu_pct' -Value $CpuPct
    Append-WorkerMetric -Worker $worker -MetricName 'mem_mb' -Value $MemMb
    if ($ErrorCount -gt 0) { Append-WorkerMetric -Worker $worker -MetricName 'errors_per_min' -Value $ErrorCount }

    $worker.health_score = Compute-WorkerHealthScore -Worker $worker
    Assess-WorkerRisk -Worker $worker
    Save-State $state
}
