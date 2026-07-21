param(
    [Parameter(Mandatory=$true)]$Job
)

switch ($Job.type) {
    'email' {
        Write-Host "Email worker queueing invoice $($Job.payload) for delivery with priority $($Job.priority)"
        Start-Sleep -Milliseconds 150
        $latency = Get-Random -Minimum 60 -Maximum 110
        $cpu = Get-Random -Minimum 10 -Maximum 30
        $mem = Get-Random -Minimum 80 -Maximum 140
        $errorCount = if ((Get-Random -Maximum 100) -le 2) { 1 } else { 0 }
        if ($errorCount -gt 0) { Write-Host "Email dispatch anomaly on job $($Job.payload)" -ForegroundColor Yellow }
        return [pscustomobject]@{
            latency_ms = $latency
            cpu_pct = $cpu
            mem_mb = $mem
            error_count = $errorCount
        }
    }
    default {
        Write-Host "Unsupported job type for email worker: $($Job.type)"
        return [pscustomobject]@{ latency_ms = 0; cpu_pct = 0; mem_mb = 0; error_count = 1 }
    }
}
