Set-Location $PSScriptRoot

Write-Host "Running invoice engine..." -ForegroundColor Cyan

$enginePath = Join-Path $PSScriptRoot 'engine.ps1'
if (-not (Test-Path $enginePath)) {
    Write-Error "Missing engine.ps1: $enginePath"
    exit 1
}

& $enginePath

if ($LASTEXITCODE -ne 0) {
    Write-Error "engine.ps1 failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Invoice engine completed." -ForegroundColor Green
