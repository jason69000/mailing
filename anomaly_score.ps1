function Get-AnomalyScore {
    param(
        [Parameter(Mandatory=$true)][double]$metric,
        [Parameter(Mandatory=$true)][double]$baseline
    )

    if ($baseline -eq 0) { return 0 }
    $ratio = $metric / $baseline
    if ($ratio -lt 1) { return 0 }
    if ($ratio -lt 1.5) { return 10 }
    if ($ratio -lt 2) { return 25 }
    if ($ratio -lt 3) { return 50 }
    return 80
}
