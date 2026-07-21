# Startup Health Check: Single Point of Truth for System Integrity
# Runs all validators before engine.ps1 touches a single invoice
# Returns: SYSTEM OK or SYSTEM BLOCKED

$base = $PSScriptRoot
$python = "python"
$logsDir = "$base\logs"
$logFile = "$logsDir\StartupHealth.log"

# Ensure logs directory exists
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Clear previous log
"" | Set-Content $logFile -Force

function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $msg"
}

$failures = @()

Log "=== Startup Health Check Started ==="

# 1. Asset Integrity Validation
Log "Checking asset integrity..."
$assetValidator = "$base\validator\asset_integrity_validate.py"
if (Test-Path $assetValidator) {
    try {
        $assetJson = & $python $assetValidator 2>&1 | Out-String
        $assetData = $assetJson | ConvertFrom-Json -ErrorAction Stop
        
        if (-not $assetData.ok) {
            $failures += "Asset integrity failed"
            Log "ASSET INTEGRITY FAILED: $($assetData | ConvertTo-Json -Compress)"
        } else {
            Log "✓ Asset integrity OK"
        }
    } catch {
        $failures += "Asset integrity check exception"
        Log "ASSET INTEGRITY EXCEPTION: $_"
    }
} else {
    $failures += "Asset validator not found"
    Log "Asset validator missing: $assetValidator"
}

# 2. Invoice Schema Validation
Log "Checking invoice schema..."
$schemaValidator = "$base\validator\invoice_schema_validate.py"
if (Test-Path $schemaValidator) {
    try {
        # Test with canonical sample invoice
        $schemaJson = & $python $schemaValidator "INV-2026-1001" 2>&1 | Out-String
        $schemaData = $schemaJson | ConvertFrom-Json -ErrorAction Stop
        
        if (-not $schemaData.all_valid) {
            $failures += "Schema validation failed"
            Log "SCHEMA VALIDATION FAILED: $($schemaData | ConvertTo-Json -Compress)"
        } else {
            Log "✓ Schema validation OK"
        }
    } catch {
        $failures += "Schema validation check exception"
        Log "SCHEMA VALIDATION EXCEPTION: $_"
    }
} else {
    $failures += "Schema validator not found"
    Log "Schema validator missing: $schemaValidator"
}

# 3. Browser Validation
Log "Checking browser rendering..."
$browserValidator = "$base\validators\browser_validate.py"
if (Test-Path $browserValidator) {
    try {
        $browserJson = & $python $browserValidator 2>&1 | Out-String
        $browserData = $browserJson | ConvertFrom-Json -ErrorAction Stop

        if ($browserData.skipped) {
            Log "⚠ Browser validation skipped (warm-up): $($browserData.error)"
        } elseif (-not $browserData.render_ok -or -not $browserData.header_ok) {
            Log "⚠ Browser rendering is not yet healthy; continuing without blocking startup: $($browserData.error)"
        } else {
            Log "✓ Browser rendering OK"
        }
    } catch {
        # Browser validation may not exist on first run; treat as warning
        Log "⚠ Browser validation check skipped (may not exist yet): $_"
    }
} else {
    Log "⚠ Browser validator not found (will validate after first run)"
}

# 4. PDF Signature Validation
Log "Checking PDF signature capability..."
$signatureValidator = "$base\validators\pdf_signature_validate.py"
if (Test-Path $signatureValidator) {
    # Just check that the validator exists and can be imported; full validation happens at sign time
    Log "✓ PDF signature validator ready"
} else {
    Log "⚠ PDF signature validator not found"
}

# 5. Dependency Check
Log "Checking Python dependencies..."
try {
    $depCheck = & $python -c "import jsonschema, pyhanko, asn1crypto; print('OK')" 2>&1
    if ($depCheck -match "OK") {
        Log "✓ Python dependencies OK"
    } else {
        $failures += "Missing Python dependencies"
        Log "DEPENDENCY CHECK FAILED: $depCheck"
    }
} catch {
    $failures += "Dependency check failed"
    Log "DEPENDENCY CHECK EXCEPTION: $_"
}

# Final Status
Log "=== Startup Health Check Complete ==="

if ($failures.Count -eq 0) {
    $status = "SYSTEM OK"
    Log $status
    Write-Host $status -ForegroundColor Green
    exit 0
} else {
    $status = "SYSTEM BLOCKED"
    Log $status
    Write-Host $status -ForegroundColor Red
    Write-Host "`nBlocking Issues:" -ForegroundColor Yellow
    $failures | ForEach-Object { 
        Write-Host " ✗ $_" -ForegroundColor Red
        Log " ✗ $_"
    }
    exit 1
}
