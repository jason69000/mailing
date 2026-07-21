# Fintech Invoice Engine - modular runner
# Adjust these paths if you place the project elsewhere.
$basePath         = "c:\Users\chide\Downloads\mailing"
$modulesPath      = "$basePath\modules"
$templatePath     = "$basePath\templates\invoice_template.html"
$csvPath          = "$basePath\recipients.csv"
$outputHtmlFolder = "$basePath\output_html"
$outputPdfFolder  = "$basePath\output_pdf"
$wkhtmltopdfPath  = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
$validatorScriptPath = Join-Path $basePath 'validate_output.py'
$emailQueuePath = Join-Path $basePath 'email_queue.txt'
$validationErrorsPath = Join-Path $basePath 'validation_errors.log'
$browserValidationExporterPath = Join-Path $basePath 'web\update_browser_validation.ps1'
$assetIntegrityValidatorPath = Join-Path $basePath 'validator\asset_integrity_validate.py'
$schemaValidatorScriptPath = Join-Path $basePath 'validator\invoice_schema_validate.py'
$signatureValidatorScriptPath = Join-Path $basePath 'validators\pdf_signature_validate.py'
$startupHealthCheckPath = Join-Path $basePath 'startup_health_check.ps1'
$updateHealthExporterPath = Join-Path $basePath 'web\update_health.ps1'
$browserValidationExporterPath = Join-Path $basePath 'web\update_browser_validation.ps1'

# Wrapper to update browser validation dashboard from multiple places in this script
function Update-BrowserValidationDashboard {
    param()
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
        return $?
    } else {
        Write-Verbose "Browser validation exporter not found: $browserValidationExporterPath"
        return $false
    }
}
$selfHealPath = Join-Path $basePath 'self_heal.ps1'
$updateSelfHealPath = Join-Path $basePath 'web\update_self_heal.ps1'

# ========== STARTUP HEALTH CHECK + SELF-HEALING ==========
# Run gatekeeper before any invoice processing
if (Test-Path $startupHealthCheckPath) {
    Write-Host "`n>>> Running startup health check..." -ForegroundColor Cyan
    & $startupHealthCheckPath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "System startup check FAILED — attempting self-healing..." -ForegroundColor Yellow
        
        # Attempt self-healing
        if (Test-Path $selfHealPath) {
            Write-Host ">>> Running self-heal orchestrator..." -ForegroundColor Cyan
            & $selfHealPath -BasePath $basePath
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ">>> Self-healing SUCCESSFUL — revalidating system..." -ForegroundColor Green
                
                # Re-run health check after healing
                & $startupHealthCheckPath
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ">>> Revalidation PASSED — system recovered. Proceeding with invoice processing." -ForegroundColor Green
                } else {
                    Write-Host ">>> Revalidation FAILED — system remains blocked." -ForegroundColor Red
                    if (Test-Path $updateHealthExporterPath) {
                        & $updateHealthExporterPath -HealthLogPath "$basePath\logs\StartupHealth.log" -OutputPath "$basePath\web\health.json"
                    }
                    if (Test-Path $updateSelfHealPath) {
                        & $updateSelfHealPath -HealthLogPath "$basePath\logs\SelfHeal.log" -OutputPath "$basePath\web\self_heal.json"
                    }
                    exit 1
                }
            } else {
                Write-Host ">>> Self-healing FAILED — system remains blocked." -ForegroundColor Red
                if (Test-Path $updateHealthExporterPath) {
                    & $updateHealthExporterPath -HealthLogPath "$basePath\logs\StartupHealth.log" -OutputPath "$basePath\web\health.json"
                }
                if (Test-Path $updateSelfHealPath) {
                    & $updateSelfHealPath -HealthLogPath "$basePath\logs\SelfHeal.log" -OutputPath "$basePath\web\self_heal.json"
                }
                exit 1
            }
        } else {
            Write-Host "Self-healing script not found. Aborting engine." -ForegroundColor Red
            if (Test-Path $updateHealthExporterPath) {
                & $updateHealthExporterPath -HealthLogPath "$basePath\logs\StartupHealth.log" -OutputPath "$basePath\web\health.json"
            }
            exit 1
        }
    }
    
    Write-Host ">>> Startup health check passed. Proceeding with invoice processing." -ForegroundColor Green
    
    # Export health data to dashboard
    if (Test-Path $updateHealthExporterPath) {
        & $updateHealthExporterPath -HealthLogPath "$basePath\logs\StartupHealth.log" -OutputPath "$basePath\web\health.json"
    }
    if (Test-Path $updateSelfHealPath) {
        & $updateSelfHealPath -HealthLogPath "$basePath\logs\SelfHeal.log" -OutputPath "$basePath\web\self_heal.json"
    }
} else {
    Write-Warning "Startup health check script not found: $startupHealthCheckPath"
}
# ====================================================

# Ensure folders exist
foreach ($folder in @($outputHtmlFolder, $outputPdfFolder)) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

# Load modules
. "$modulesPath\cluster.ps1"
. "$modulesPath\recipients.ps1"
. "$modulesPath\accents.ps1"
. "$modulesPath\micro.ps1"
. "$modulesPath\depth.ps1"
. "$modulesPath\holographic.ps1"
. "$modulesPath\watermark.ps1"
. "$modulesPath\payment.ps1"
. "$modulesPath\seals.ps1"
. "$modulesPath\serial.ps1"
. "$modulesPath\blockchain.ps1"
. "$modulesPath\tamper.ps1"
. "$modulesPath\qr.ps1"
. "$modulesPath\audit.ps1"
. "$modulesPath\revocation.ps1"
. "$modulesPath\chainviewer.ps1"

$templateHtml = Get-Content -Path $templatePath -Raw
$recipients   = Import-Csv -Path $csvPath | Where-Object { $_.InvoiceNumber -ne 'InvoiceNumber' -and $_.Name -ne 'Name' }
$clusterState = Initialize-ClusterState -BasePath $basePath

$jobPlan = @()
foreach ($r in $recipients) {
    $invoiceNumber = [string]$r.InvoiceNumber
    $renderAssignment = Get-ClusterAssignment -JobType 'render' -InvoiceNumber $invoiceNumber -State $clusterState
    $signatureAssignment = Get-ClusterAssignment -JobType 'signature' -InvoiceNumber $invoiceNumber -State $clusterState
    $browserAssignment = Get-ClusterAssignment -JobType 'browser' -InvoiceNumber $invoiceNumber -State $clusterState
    $pdfAssignment = Get-ClusterAssignment -JobType 'pdf' -InvoiceNumber $invoiceNumber -State $clusterState
    $emailAssignment = Get-ClusterAssignment -JobType 'email' -InvoiceNumber $invoiceNumber -State $clusterState

    $jobPlan += [pscustomobject]@{
        invoice = $invoiceNumber
        render_worker = $renderAssignment.worker
        signature_worker = $signatureAssignment.worker
        browser_worker = $browserAssignment.worker
        pdf_worker = $pdfAssignment.worker
        email_worker = $emailAssignment.worker
    }
}

$jobPlan | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $basePath 'cluster_plan.json') -Encoding UTF8
Write-Host "Cluster plan generated for $($jobPlan.Count) invoice(s)." -ForegroundColor Cyan

$clusterExportPath = Join-Path $basePath 'web\cluster.json'
$workerState = $null
if (Test-Path (Join-Path $basePath 'workers\worker_state.json')) {
    $workerState = Get-Content -Path (Join-Path $basePath 'workers\worker_state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
}
$clusterExport = [ordered]@{
    workers = if ($workerState) { $workerState.workers } else { @{} }
    plan = $jobPlan
    cluster = $clusterState
}
$clusterExport | ConvertTo-Json -Depth 5 | Set-Content -Path $clusterExportPath -Encoding UTF8

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    $pythonCommand = Get-Command py -ErrorAction SilentlyContinue
}

$dispatcherScript = Join-Path $basePath 'dispatcher.ps1'
$workersDir = Join-Path $basePath 'workers'
New-Item -ItemType Directory -Force -Path $workersDir | Out-Null

if (-not $pythonCommand) {
    Write-Warning "Python was not found. Invoice schema validation could not be run."
    Set-Content -Path $validationErrorsPath -Value @("SCHEMA VALIDATION FAILED", "Python runtime not found.") -Encoding UTF8
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    exit 1
}

if (-not (Test-Path $schemaValidatorScriptPath)) {
    Set-Content -Path $validationErrorsPath -Value @("SCHEMA VALIDATION FAILED", "Schema validator not found: $schemaValidatorScriptPath") -Encoding UTF8
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    exit 1
}

$pythonExecutable = if ($pythonCommand.Path) { $pythonCommand.Path } else { $pythonCommand.Source }
$schemaOutput = & $pythonExecutable $schemaValidatorScriptPath @($recipients | ForEach-Object { [string]$_.InvoiceNumber }) 2>&1
$schemaExitCode = $LASTEXITCODE
if ($schemaExitCode -ne 0) {
    Set-Content -Path $validationErrorsPath -Value (@("SCHEMA VALIDATION FAILED") + $schemaOutput) -Encoding UTF8
    if (Test-Path $emailQueuePath) {
        Remove-Item -Path $emailQueuePath -Force
    }
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Warning "Invoice schema validation failed. No invoices were rendered or queued."
    exit 1
}

$staleFile = Join-Path $outputHtmlFolder 'InvoiceNumber.html'
if (Test-Path $staleFile) {
    Remove-Item -Path $staleFile -Force
}

$wkhtmltopdfPath = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
if (-not (Test-Path $wkhtmltopdfPath)) {
    $command = Get-Command wkhtmltopdf.exe -ErrorAction SilentlyContinue
    if ($command) { $wkhtmltopdfPath = $command.Source }
}

$canGeneratePdf = Test-Path $wkhtmltopdfPath
if (-not $canGeneratePdf) {
    Write-Warning "wkhtmltopdf not found. PDF export will be skipped unless you install wkhtmltopdf or set `$$wkhtmltopdfPath` in the script."
}

$generatedInvoiceNumbers = @()
foreach ($r in $recipients) {
    $tokens = @{ }
    $tokens += Get-RecipientBaseTokens $r
    $tokens += Get-Accents $r
    $tokens += Get-Micro $r
    $tokens += Get-Depth $r
    $tokens += Get-Holographic $r
    $tokens += Get-Watermark $r
    $tokens += Get-PaymentMethod $r
    $tokens += Get-Seal $r
    $tokens += Get-Serial $r
    $tokens += Get-Blockchain $r
    $tokens += Get-Tamper $r
    $tokens += Get-QR $r $tokens.SerialCode $tokens.BlockchainHashValue
    $tokens += Get-AuditTrail $r
    $tokens += Get-Revocation $r
    $tokens += Get-RevocationChain $r

    $html = $templateHtml
    foreach ($key in $tokens.Keys) {
        $html = $html.Replace("{{$key}}", [string]$tokens[$key])
    }

    $invoiceNumber = [string]$r.InvoiceNumber
    $generatedInvoiceNumbers += $invoiceNumber

    $htmlOutputPath = Join-Path $outputHtmlFolder "$invoiceNumber.html"
    Set-Content -Path $htmlOutputPath -Value $html -Encoding UTF8

    $pdfOutputPath = Join-Path $outputPdfFolder "$invoiceNumber.pdf"
    # Do not allow an earlier PDF to make a failed conversion look valid.
    if (Test-Path $pdfOutputPath) {
        Remove-Item -Path $pdfOutputPath -Force
    }
    if ($canGeneratePdf) {
        & $wkhtmltopdfPath `
            --quiet `
            --dpi 300 `
            --image-dpi 300 `
            --image-quality 100 `
            --enable-local-file-access `
            --margin-top 10mm `
            --margin-bottom 10mm `
            --margin-left 10mm `
            --margin-right 10mm `
            "$htmlOutputPath" `
            "$pdfOutputPath"
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "wkhtmltopdf failed for $htmlOutputPath. Check installation and HTML content."
        }
    }
}

Write-Host "Invoices generated as HTML in $outputHtmlFolder and PDF in $outputPdfFolder"

if (Test-Path $dispatcherScript) {
    foreach ($inv in $generatedInvoiceNumbers) {
        $renderJob = [pscustomobject]@{ type = 'render'; payload = $inv; priority = 2 }
        $browserJob = [pscustomobject]@{ type = 'browser'; payload = $inv; priority = 2 }
        $signatureJob = [pscustomobject]@{ type = 'signature'; payload = $inv; priority = 1 }

        Write-Host "Dispatching cluster jobs for invoice $inv" -ForegroundColor Cyan
        & $dispatcherScript -BasePath $basePath -Job $renderJob | Out-Null
        & $dispatcherScript -BasePath $basePath -Job $browserJob | Out-Null
        & $dispatcherScript -BasePath $basePath -Job $signatureJob | Out-Null
    }
} else {
    Write-Host "Dispatcher not found; processing jobs locally." -ForegroundColor Yellow
}

# Signature jobs are dispatched through the worker dispatcher when available.
# If dispatcher is not available, the engine will fall back to local signing below.
$signerScript1 = Join-Path $basePath 'sign_invoice.py'
$signerScript2 = Join-Path $basePath 'scripts\sign_invoice_pdf.py'
if (-not (Test-Path $dispatcherScript) -and ((Test-Path $signerScript1) -or (Test-Path $signerScript2))) {
    Write-Host "Signing generated PDFs using available signing helper..." -ForegroundColor Cyan
    $pythonExecutable = if ($pythonCommand.Path) { $pythonCommand.Path } else { $pythonCommand.Source }
    foreach ($inv in $generatedInvoiceNumbers) {
        try {
            $certPath = Join-Path $basePath "certs\$inv.crt.pem"
            $keyPath = Join-Path $basePath "certs\$inv.key.pem"
            if ((Test-Path $signerScript1) -and (Test-Path $certPath) -and (Test-Path $keyPath)) {
                & $pythonExecutable $signerScript1 $inv $certPath $keyPath 2>&1 | Write-Host
            } elseif (Test-Path $signerScript2) {
                & $pythonExecutable $signerScript2 $inv 2>&1 | Write-Host
            } else {
                Write-Host "No suitable signer found for $inv; skipping signing." -ForegroundColor Yellow
            }
        } catch {
            Write-Warning ("Signing failed for {0}: {1}" -f $inv, $_.Exception.Message)
        }
    }
} elseif (-not (Test-Path $dispatcherScript)) {
    Write-Host "No signing helper found; PDFs may remain unsigned." -ForegroundColor Yellow
}

if (-not (Test-Path $validatorScriptPath)) {
    Write-Warning "Validator script not found at $validatorScriptPath. Skipping automated validation."
    exit 0
}

if (-not (Test-Path $assetIntegrityValidatorPath)) {
    Set-Content -Path $validationErrorsPath -Value @("ASSET INTEGRITY FAILED", "Asset validator not found: $assetIntegrityValidatorPath") -Encoding UTF8
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    exit 1
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$assetOutput = & $pythonExecutable $assetIntegrityValidatorPath 2>&1
$assetExitCode = $LASTEXITCODE
if ($assetExitCode -ne 0) {
    Set-Content -Path $validationErrorsPath -Value (@("ASSET INTEGRITY FAILED") + $assetOutput) -Encoding UTF8
    if (Test-Path $emailQueuePath) {
        Remove-Item -Path $emailQueuePath -Force
    }
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Warning "Asset integrity validation failed. No invoices were rendered or queued."
    exit 1
}

if (-not $pythonCommand) {
    $pythonCommand = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $pythonCommand) {
    Write-Warning "Python was not found. Validation could not be run."
    Set-Content -Path $validationErrorsPath -Value @("Python runtime not found; validation skipped.") -Encoding UTF8
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    exit 1
}

if (Test-Path $validationErrorsPath) {
    Remove-Item -Path $validationErrorsPath -Force
}

$validatorOutput = @()
$validatorExitCode = 0
if ($generatedInvoiceNumbers.Count -gt 0) {
    $pythonExecutable = if ($pythonCommand.Path) { $pythonCommand.Path } else { $pythonCommand.Source }
    $validatorOutput = & $pythonExecutable $validatorScriptPath $generatedInvoiceNumbers 2>&1
    $validatorExitCode = $LASTEXITCODE
}

$validatorOutput | ForEach-Object { $_.ToString() } | Write-Host

if ($validatorExitCode -ne 0) {
    Set-Content -Path $validationErrorsPath -Value $validatorOutput -Encoding UTF8
    if (Test-Path $emailQueuePath) {
        Remove-Item -Path $emailQueuePath -Force
    }
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Warning "Validation failed. See $validationErrorsPath and no email jobs were queued."
    exit 1
}

if (-not (Test-Path $signatureValidatorScriptPath)) {
    Set-Content -Path $validationErrorsPath -Value @("SIGNATURE/REVOCATION FAILED", "Signature validator not found: $signatureValidatorScriptPath") -Encoding UTF8
    if (Test-Path $emailQueuePath) {
        Remove-Item -Path $emailQueuePath -Force
    }
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Warning "Signature validation could not run. No email jobs were queued."
    exit 1
}

$certFiles = Get-ChildItem -Path (Join-Path $basePath 'certs') -Filter '*.crt.pem' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if ($certFiles -and $certFiles.Count -gt 0) {
    $env:PDF_SIGNATURE_TRUST_ROOTS = ($certFiles -join [System.IO.Path]::PathSeparator)
    Write-Host "Configured PDF_SIGNATURE_TRUST_ROOTS with $($certFiles.Count) cert(s)" -ForegroundColor Cyan
}
$signatureOutput = & $pythonExecutable $signatureValidatorScriptPath $generatedInvoiceNumbers 2>&1
$signatureExitCode = $LASTEXITCODE
$signatureOutput | ForEach-Object { $_.ToString() } | Write-Host
if ($signatureExitCode -ne 0) {
    Set-Content -Path $validationErrorsPath -Value (@("SIGNATURE/REVOCATION FAILED") + $signatureOutput) -Encoding UTF8
    if (Test-Path $emailQueuePath) {
        Remove-Item -Path $emailQueuePath -Force
    }
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Warning "Signature validation failed. See $validationErrorsPath and no email jobs were queued."
    exit 1
}

Set-Content -Path $emailQueuePath -Value $generatedInvoiceNumbers -Encoding UTF8
if (Test-Path $dispatcherScript) {
    foreach ($inv in $generatedInvoiceNumbers) {
        $emailJob = [pscustomobject]@{ type = 'email'; payload = $inv; priority = 1 }
        Write-Host "Dispatching email job for invoice $inv" -ForegroundColor Cyan
        & $dispatcherScript -BasePath $basePath -Job $emailJob | Out-Null
    }
    Write-Host "Validation passed. Dispatched $($generatedInvoiceNumbers.Count) email jobs." -ForegroundColor Green
} else {
    if (Test-Path $browserValidationExporterPath) {
        & $browserValidationExporterPath -BasePath $basePath
    }
    Write-Host "Validation passed. Queued $($generatedInvoiceNumbers.Count) invoice(s) for email delivery." -ForegroundColor Green
}
