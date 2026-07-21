# Export startup health check log to JSON for admin dashboard
# Called by engine.ps1 after startup_health_check.ps1 completes

param(
    [string]$HealthLogPath = "$PSScriptRoot\..\logs\StartupHealth.log",
    [string]$OutputPath = "$PSScriptRoot\health.json"
)

$healthData = @{
    timestamp = Get-Date -Format "o"
    status = "UNKNOWN"
    entries = @()
    ok = $false
    blocked = $false
}

if (Test-Path $HealthLogPath) {
    $lines = @(Get-Content $HealthLogPath -ErrorAction SilentlyContinue)
    
    # Parse log for final status
    $lastStatus = $lines | Where-Object { $_ -match "(SYSTEM OK|SYSTEM BLOCKED)" } | Select-Object -Last 1
    if ($lastStatus -match "SYSTEM OK") {
        $healthData.status = "SYSTEM OK"
        $healthData.ok = $true
    } elseif ($lastStatus -match "SYSTEM BLOCKED") {
        $healthData.status = "SYSTEM BLOCKED"
        $healthData.blocked = $true
    }
    
    # Add last 30 log lines
    $healthData.entries = @($lines | Select-Object -Last 30)
} else {
    $healthData.entries = @("No startup health log found. Run startup_health_check.ps1 first.")
}

$healthData | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Force
