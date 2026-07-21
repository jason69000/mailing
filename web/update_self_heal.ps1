#!/usr/bin/env pwsh
<#
.SYNOPSIS
Export Self-Heal Log to JSON for Admin Dashboard

Converts SelfHeal.log into structured JSON format for real-time dashboard display

.PARAMETER HealthLogPath
Path to SelfHeal.log

.PARAMETER OutputPath
Where to write self_heal.json
#>

param(
    [string]$HealthLogPath = "logs\SelfHeal.log",
    [string]$OutputPath = "web\self_heal.json"
)

try {
    if (-not (Test-Path $HealthLogPath)) {
        # No self-heal log yet (hasn't failed)
        $data = @{
            status = "Not Run"
            result = "N/A"
            ok = $true
            blocked = $false
            entries = @()
            timestamp = (Get-Date -Format o)
        } | ConvertTo-Json -Compress
        
        Set-Content -Path $OutputPath -Value $data -Encoding UTF8
        return
    }

    $content = Get-Content $HealthLogPath -Raw
    $lines = $content -split "`n" | Where-Object { $_.Trim() -ne '' }
    
    # Find final status
    $status = "Unknown"
    $result = "Unknown"
    $ok = $false
    $blocked = $false
    
    foreach ($line in $lines) {
        if ($line -match "SYSTEM RECOVERED") {
            $status = "SYSTEM RECOVERED"
            $result = "Success"
            $ok = $true
            $blocked = $false
        }
        elseif ($line -match "SYSTEM BLOCKED") {
            $status = "SYSTEM BLOCKED"
            $result = "Failed"
            $ok = $false
            $blocked = $true
        }
        elseif ($line -match "Self-Heal Orchestrator Started") {
            if ($status -eq "Unknown") {
                $status = "In Progress"
                $result = "Running"
            }
        }
    }
    
    # Build JSON output with last 40 log entries
    $entries = @($lines | Select-Object -Last 40)
    
    $data = @{
        status = $status
        result = $result
        ok = $ok
        blocked = $blocked
        entries = $entries
        timestamp = (Get-Date -Format o)
    }
    
    $json = $data | ConvertTo-Json -Compress
    Set-Content -Path $OutputPath -Value $json -Encoding UTF8
    
} catch {
    Write-Error "Failed to export self-heal log: $_"
    exit 1
}
