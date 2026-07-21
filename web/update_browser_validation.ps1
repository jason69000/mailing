param(
    [string]$BasePath = (Split-Path -Parent $PSScriptRoot)
)

$logFile = Join-Path $BasePath 'validation_errors.log'
$runtimeReportFile = Join-Path $PSScriptRoot 'browser_runtime.json'
$outputFile = Join-Path $PSScriptRoot 'browser_validation.json'
$lines = if (Test-Path $logFile) { Get-Content -Path $logFile -Encoding UTF8 } else { @() }

$runtime = if (Test-Path $runtimeReportFile) {
    Get-Content -Path $runtimeReportFile -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    [pscustomobject]@{ invoices = @() }
}

$runtimeInvoices = @($runtime | Select-Object -ExpandProperty invoices)
$browserErrors = @($lines | Where-Object { $_ -match '^BROWSER_' })
$jsErrors = @($runtimeInvoices | ForEach-Object { @($_.console_errors) + @($_.page_errors) } | Where-Object { $_ })
$jsWarnings = @($runtimeInvoices | ForEach-Object { @($_.console_warnings) } | Where-Object { $_ })
$consoleLogs = @($runtimeInvoices | ForEach-Object { @($_.console_logs) } | Where-Object { $_ })
$screenshots = @($runtimeInvoices | ForEach-Object { $_.screenshot } | Where-Object { $_ })
$assetErrors = @($lines | Where-Object { $_ -match '^ASSET INTEGRITY FAILED' })
$schemaErrors = @($lines | Where-Object { $_ -match '^SCHEMA VALIDATION FAILED' })
$signatureErrors = @($lines | Where-Object { $_ -match '^SIGNATURE(?:_VALIDATION_FAILED|/REVOCATION FAILED)' })

if ($signatureErrors.Count -gt 0) {
    $signatureMarker = 0
    while ($signatureMarker -lt $lines.Count -and $lines[$signatureMarker] -notmatch '^SIGNATURE(?:_VALIDATION_FAILED|/REVOCATION FAILED)') {
        $signatureMarker++
    }

    if ($signatureMarker -ge 0 -and $signatureMarker -lt ($lines.Count - 1)) {
        try {
            $signatureResult = (($lines[($signatureMarker + 1)..($lines.Count - 1)]) -join "`n") | ConvertFrom-Json
            $signatureErrors = @($signatureResult.invoices | ForEach-Object {
                "{0}: signed={1}; valid={2}; trusted={3}; tamper_detected={4}; revoked={5}; error={6}" -f `
                    $_.invoice, $_.signed, $_.valid_signature, $_.trusted_certificate, $_.tamper_detected, $_.revoked, $_.error
            })
        } catch {
            # Preserve the marker if the validator's output cannot be parsed.
        }
    }
}

$data = [ordered]@{
    generated_at      = (Get-Date).ToUniversalTime().ToString('o')
    validation_failed = $lines.Count -gt 0
    browser_errors    = $browserErrors
    js_errors         = $jsErrors
    js_warnings       = $jsWarnings
    console_logs      = $consoleLogs
    screenshots       = $screenshots
    asset_errors      = $assetErrors
    schema_errors     = $schemaErrors
    signature_errors  = $signatureErrors
    invoices          = $runtimeInvoices
    validation_errors = @($lines)
}

$data | ConvertTo-Json -Depth 4 | Set-Content -Path $outputFile -Encoding UTF8
