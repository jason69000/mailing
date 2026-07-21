param(
    [Parameter(Mandatory=$true)]$Job
)

switch ($Job.type) {
    'render' {
        Write-Host "Render worker received invoice $($Job.payload)"
        Start-Sleep -Milliseconds 250
        $latency = Get-Random -Minimum 100 -Maximum 220
        $cpu = Get-Random -Minimum 25 -Maximum 55
        $mem = Get-Random -Minimum 150 -Maximum 260
        $errorCount = if ((Get-Random -Maximum 100) -le 4) { 1 } else { 0 }
        if ($errorCount -gt 0) { Write-Host "Render worker anomaly on job $($Job.payload)" -ForegroundColor Yellow }
        return [pscustomobject]@{
            latency_ms = $latency
            cpu_pct = $cpu
            mem_mb = $mem
            error_count = $errorCount
        }
    }
    default {
        Write-Host "Unsupported job type for render worker: $($Job.type)"
        return [pscustomobject]@{ latency_ms = 0; cpu_pct = 0; mem_mb = 0; error_count = 1 }
    }
}
