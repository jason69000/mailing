param(
    [Parameter(Mandatory=$true)]$Job
)

switch ($Job.type) {
    'signature' {
        Write-Host "Signature worker signing invoice $($Job.payload) with priority $($Job.priority)"
        Start-Sleep -Milliseconds 200
        $latency = Get-Random -Minimum 80 -Maximum 160
        $cpu = Get-Random -Minimum 20 -Maximum 50
        $mem = Get-Random -Minimum 120 -Maximum 210
        $errorCount = if ((Get-Random -Maximum 100) -le 3) { 1 } else { 0 }
        if ($errorCount -gt 0) { Write-Host "Signature worker anomaly on job $($Job.payload)" -ForegroundColor Yellow }
        return [pscustomobject]@{
            latency_ms = $latency
            cpu_pct = $cpu
            mem_mb = $mem
            error_count = $errorCount
        }
    }
    default {
        Write-Host "Unsupported job type for signature worker: $($Job.type)"
        return [pscustomobject]@{ latency_ms = 0; cpu_pct = 0; mem_mb = 0; error_count = 1 }
    }
}
