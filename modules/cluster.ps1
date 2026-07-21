function Initialize-ClusterState {
    param(
        [string]$BasePath = (Get-Location).Path
    )

    $statePath = Join-Path $BasePath 'cluster_state.json'
    if (Test-Path $statePath) {
        return Get-Content $statePath -Raw | ConvertFrom-Json
    }

    $state = [ordered]@{
        workers = @(
            [ordered]@{ name = 'render-worker-01'; role = 'render'; capacity = 'high'; healthy = $true; latency = 120; last_error = $null },
            [ordered]@{ name = 'signature-worker-01'; role = 'signature'; capacity = 'crypto'; healthy = $true; latency = 90; last_error = $null },
            [ordered]@{ name = 'browser-worker-01'; role = 'browser'; capacity = 'headless'; healthy = $true; latency = 140; last_error = $null },
            [ordered]@{ name = 'pdf-worker-01'; role = 'pdf'; capacity = 'pdf'; healthy = $true; latency = 110; last_error = $null },
            [ordered]@{ name = 'email-worker-01'; role = 'email'; capacity = 'smtp'; healthy = $true; latency = 80; last_error = $null }
        )
        assignments = @()
        anomalies = @()
    }

    $state | ConvertTo-Json -Depth 5 | Set-Content $statePath -Encoding UTF8
    return $state
}

function Save-ClusterState {
    param(
        [Parameter(Mandatory=$true)]$State,
        [string]$BasePath = (Get-Location).Path
    )

    $statePath = Join-Path $BasePath 'cluster_state.json'
    $State | ConvertTo-Json -Depth 5 | Set-Content $statePath -Encoding UTF8
}

function Get-ClusterAssignment {
    param(
        [Parameter(Mandatory=$true)][string]$JobType,
        [Parameter(Mandatory=$true)][string]$InvoiceNumber,
        [Parameter(Mandatory=$true)]$State
    )

    $roleMap = @{ render = 'render'; signature = 'signature'; browser = 'browser'; pdf = 'pdf'; email = 'email' }
    $role = if ($roleMap.ContainsKey($JobType)) { $roleMap[$JobType] } else { 'render' }

    $eligible = @($State.workers | Where-Object { $_.role -eq $role -and $_.healthy })
    if (-not $eligible -or $eligible.Count -eq 0) {
        $eligible = @($State.workers | Where-Object { $_.healthy })
    }

    $selected = $eligible | Sort-Object latency | Select-Object -First 1
    $assignment = [ordered]@{
        invoice = $InvoiceNumber
        job_type = $JobType
        worker = $selected.name
        role = $role
        assigned_at = (Get-Date).ToString('o')
    }

    $State.assignments = @($State.assignments + [pscustomobject]$assignment)
    Save-ClusterState -State $State -BasePath (Get-Location).Path
    return [pscustomobject]$assignment
}

function Update-ClusterAnomaly {
    param(
        [Parameter(Mandatory=$true)]$State,
        [Parameter(Mandatory=$true)][string]$Metric,
        [Parameter(Mandatory=$true)][double]$Value,
        [Parameter(Mandatory=$true)][string]$Severity,
        [string]$Detail = ''
    )

    $anomaly = [ordered]@{
        metric = $Metric
        value = $Value
        severity = $Severity
        detail = $Detail
        observed_at = (Get-Date).ToString('o')
    }

    $State.anomalies = @($State.anomalies + [pscustomobject]$anomaly)
    Save-ClusterState -State $State -BasePath (Get-Location).Path
    return [pscustomobject]$anomaly
}
