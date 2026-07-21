$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'modules/cluster.ps1')

$state = Initialize-ClusterState -BasePath $repoRoot
$renderRoute = Get-ClusterAssignment -JobType 'render' -InvoiceNumber 'INV-1001' -State $state
$signRoute = Get-ClusterAssignment -JobType 'signature' -InvoiceNumber 'INV-1002' -State $state
$browserRoute = Get-ClusterAssignment -JobType 'browser' -InvoiceNumber 'INV-1003' -State $state

if (-not $renderRoute.worker -or -not $signRoute.worker -or -not $browserRoute.worker) {
    throw 'Expected worker assignment for each job type.'
}

if ($renderRoute.worker -eq $signRoute.worker -and $renderRoute.worker -eq $browserRoute.worker) {
    throw 'Expected distinct worker specialization for different job types.'
}

Write-Host ('PASS render={0} signature={1} browser={2}' -f $renderRoute.worker, $signRoute.worker, $browserRoute.worker)
