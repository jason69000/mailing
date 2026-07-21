# Self-Healing Fintech Pipeline Architecture

## Overview

Your system now implements **autonomous self-healing**: when validators detect failures, the system automatically attempts repairs before blocking. This transforms your pipeline from "detect problems" into "detect → repair → continue safely."

---

## Execution Flow

```
┌─────────────────────────────────────────────────────────┐
│ engine.ps1 (Main Orchestrator)                          │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ startup_health_check.ps1 (Gatekeeper)                   │
│ • Asset Integrity (SHA-256)                             │
│ • Schema Validation (JSON)                              │
│ • Browser Rendering (Chromium)                          │
│ • PDF Signature Capability                              │
│ • Python Dependencies                                   │
└─────────────────────────────────────────────────────────┘
                        ↓
                   ┌──────────┐
                   │ Result?  │
                   └──────────┘
                    /        \
              PASS /          \ FAIL
                  /            \
                 ↓              ↓
          ┌─────────────┐   ┌──────────────────────────────┐
          │ Proceed →   │   │ self_heal.ps1 (Orchestrator) │
          │ Invoices    │   │                              │
          └─────────────┘   │ 1. Asset Repair              │
                            │    └─ Restore from backup/   │
                            │                              │
                            │ 2. Schema Repair             │
                            │    └─ Restore definitions    │
                            │                              │
                            │ 3. Browser Repair            │
                            │    ├─ Clear cache            │
                            │    └─ Reinstall Chromium     │
                            │                              │
                            │ 4. Signature Repair          │
                            │    ├─ Restore CA bundle      │
                            │    └─ Restore PyHanko config │
                            │                              │
                            │ 5. Dependency Repair         │
                            │    └─ Reinstall packages     │
                            │                              │
                            │ Re-validate all subsystems   │
                            └──────────────────────────────┘
                                    ↓
                           ┌─────────────────┐
                           │ Repairs OK?     │
                           └─────────────────┘
                            /              \
                       YES /                \ NO
                          /                  \
                         ↓                    ↓
              ┌──────────────────┐  ┌─────────────────────┐
              │ Re-validate →    │  │ Quarantine Failed   │
              │ Health Check     │  │ Subsystems         │
              └──────────────────┘  │                    │
                         ↓          │ Mark in:           │
              ┌──────────────────┐  │ quarantine/        │
              │ STILL PASSING?   │  │                    │
              └──────────────────┘  │ Exit with status   │
                /              \    │ SYSTEM BLOCKED     │
           YES /                \ NO └─────────────────────┘
              /                  \
             ↓                    ↓
    ┌──────────────────┐  ┌─────────────────────┐
    │ Export health.json   │ Export health.json  │
    │ + self_heal.json │  │ + self_heal.json   │
    │ Status: RECOVERED│  │ Status: FAILED     │
    │ Proceed to       │  │ Exit engine (1)    │
    │ invoices         │  │ Require manual fix  │
    └──────────────────┘  └─────────────────────┘
             ↓
    ┌──────────────────┐
    │ Process invoices │
    │ Render HTML/PDF  │
    │ Send to queue    │
    └──────────────────┘
```

---

## Component Details

### 1. Gatekeeper: `startup_health_check.ps1`

**Purpose**: Detect failures before invoice processing

**Checks**:
1. **Asset Integrity** → SHA-256 validation against `validator/asset_manifest.json`
2. **Schema Validation** → JSON structure check via `validator/invoice_schema_validate.py`
3. **Browser Rendering** → Chromium headless capability via `validators/browser_validate.py`
4. **PDF Signature** → Validator availability check
5. **Python Dependencies** → `jsonschema`, `pyhanko`, `asn1crypto`

**Output**:
- Exit code `0` → `SYSTEM OK` (proceed)
- Exit code `1` → `SYSTEM BLOCKED` (trigger self-heal)
- Log file: `logs/StartupHealth.log`

---

### 2. Self-Heal Orchestrator: `self_heal.ps1`

**Purpose**: Attempt automatic repair of failed subsystems

**Repair Strategies**:

#### Asset Corruption
```
Failure: Asset hash mismatch
Repair: cp backup/web/* → web/
Re-validate: Run asset_integrity_validate.py
```

#### Schema Corruption
```
Failure: Invoice schema validation failure
Repair: cp backup/validator/* → validator/
Re-validate: Run invoice_schema_validate.py
```

#### Browser Failure
```
Failure: Render errors / console errors / asset errors
Repair: 
  1. Remove-Item browser_cache/*
  2. playwright install chromium
  3. Remove Playwright cache
Re-validate: Run browser_validate.py
```

#### Signature System Failure
```
Failure: CA bundle missing / PyHanko misconfigured
Repair:
  1. cp backup/certs/* → certs/
  2. pip install --upgrade pyhanko asn1crypto
Re-validate: Test signature validator
```

#### Missing Dependencies
```
Failure: Import errors (jsonschema, pyhanko, asn1crypto)
Repair: pip install --upgrade [packages]
Re-validate: python -c "import [packages]"
```

**Output**:
- Exit code `0` → All repairs successful → Re-validate health check
- Exit code `1` → Some repairs failed → Quarantine subsystems
- Log file: `logs/SelfHeal.log`
- JSON export: `web/self_heal.json`

---

### 3. Backup Layer: `backup/` Directory

**Structure**:
```
backup/
├── web/                     # Frontend files
│   ├── index.html
│   └── invoice_template.html
├── validator/               # Validator configs
│   └── asset_manifest.json
└── certs/                   # Certificate bundles
    └── ca-bundle.pem        # (placeholder for CA certs)
```

**Management**:
- Updated when you make intentional code changes
- Restored by `self_heal.ps1` on asset corruption

**How to Update**:
```powershell
# After modifying web/index.html or validators
cp web/index.html backup/web/index.html -Force
cp validator/asset_manifest.json backup/validator/asset_manifest.json -Force
```

---

### 4. Quarantine System: `quarantine/` Directory

**Purpose**: Isolate persistent failures that self-healing cannot fix

**Files**:
- `asset_integrity.quarantined` → Asset restoration failed
- `schema_validation.quarantined` → Schema restoration failed
- `browser_rendering.quarantined` → Browser repair failed
- `pdf_signatures.quarantined` → Signature system repair failed
- `dependencies.quarantined` → Dependency installation failed

**Action Required**:
When quarantine files appear, self-healing has failed. Manual intervention required:
1. Check `logs/SelfHeal.log` for detailed error messages
2. Investigate root cause
3. Apply manual fix
4. Delete `.quarantined` file to clear quarantine
5. Re-run `.\engine.ps1` to re-test

---

### 5. Dashboard Integration

#### Health Status: `web/health.json`
```json
{
  "status": "SYSTEM OK",
  "ok": true,
  "blocked": false,
  "entries": [...],  // Last 30 log lines
  "timestamp": "2026-07-21T11:41:22Z"
}
```

#### Self-Heal Status: `web/self_heal.json`
```json
{
  "status": "SYSTEM RECOVERED",
  "result": "Success",
  "ok": true,
  "blocked": false,
  "entries": [...],  // Last 40 log lines
  "timestamp": "2026-07-21T11:46:51Z"
}
```

#### Dashboard Display: `web/index.html`
- **Health Panel** → Shows `SYSTEM OK` / `SYSTEM BLOCKED` status
- **Self-Heal Panel** → Shows `RECOVERED` / `FAILED` status (NEW)
- Auto-refreshes every 3 seconds
- Color-coded: Green (OK), Red (Failed)

---

## Audit Trail

### Health Check Log: `logs/StartupHealth.log`
```
[2026-07-21 11:41:01] === Startup Health Check Started ===
[2026-07-21 11:41:01] Checking asset integrity...
[2026-07-21 11:41:01] ✓ Asset integrity OK
[2026-07-21 11:41:02] === Startup Health Check Complete ===
[2026-07-21 11:41:02] SYSTEM OK
```

### Self-Heal Log: `logs/SelfHeal.log`
```
[2026-07-21 11:46:51] === Self-Heal Orchestrator Started ===
[2026-07-21 11:46:51] 1. ASSET INTEGRITY HEALING
[2026-07-21 11:46:51] Asset integrity failed — attempting repair
[2026-07-21 11:46:51]   → Restoring web assets from backup...
[2026-07-21 11:46:51] ✓ Asset integrity HEALED
[2026-07-21 11:46:51] === Self-Heal Summary ===
[2026-07-21 11:46:57] ✅ SELF-HEAL COMPLETE — SYSTEM RECOVERED
```

---

## Production Operations

### Deploy Engine with Self-Healing
```powershell
cd C:\Users\chide\Downloads\mailing
.\engine.ps1
```

**What Happens**:
1. Runs `startup_health_check.ps1`
2. If OK → Processes invoices
3. If BLOCKED → Runs `self_heal.ps1`
4. If healed → Revalidates and processes invoices
5. If healing fails → Exits with quarantine report

### Monitor Dashboard
```powershell
python -m http.server 8000
# Open http://localhost:8000/web/
```

**View**:
- Real-time health status
- Latest self-heal attempt
- Failure logs (browser, schema, signature, assets)
- Screenshots of render failures

### Update Backups After Code Changes
```powershell
# Modify web/index.html, then:
cp web/index.html backup/web/index.html -Force

# Regenerate asset manifest:
python validator/generate_asset_hashes.py

# Update backup manifest:
cp validator/asset_manifest.json backup/validator/asset_manifest.json -Force
```

### Clear Quarantine
```powershell
# After fixing root cause manually:
Remove-Item quarantine/*.quarantined -Force
.\engine.ps1  # Re-test
```

---

## Key Guarantees

✅ **Fail-Closed Semantics**: Never attempts to process invoices when health checks fail

✅ **Audit Trail**: Every operation logged with timestamps for compliance

✅ **Autonomous**: Self-repairs happen automatically without human intervention

✅ **Detectable Failures**: Quarantine marks indicate what couldn't be auto-fixed

✅ **Dashboard Visibility**: Operators see real-time status of health & healing

✅ **Backup Protection**: Critical assets protected in `backup/` directory

✅ **Enterprise-Grade**: Matches hardened fintech pipeline standards

---

## Troubleshooting

### Problem: `SYSTEM BLOCKED` persists after self-healing
- Check `logs/SelfHeal.log` for error details
- Review `quarantine/` directory for failed subsystems
- Manually investigate root cause
- Apply fix
- Delete `.quarantined` file
- Re-run engine

### Problem: Self-heal restores old files
- Update backups after code changes: `cp web/index.html backup/web/ -Force`
- Verify backup timestamps are recent

### Problem: Asset hash mismatch on startup
- Regenerate manifest: `python validator/generate_asset_hashes.py`
- Update backup: `cp validator/asset_manifest.json backup/validator/ -Force`

### Problem: Browser rendering fails after self-heal
- Check Playwright installation: `python -m playwright install chromium`
- Clear cache: `Remove-Item $env:LOCALAPPDATA\ms-playwright\* -Recurse -Force`
- Re-run engine

---

## Architecture in Context

```
┌────────────────────────────────────────────────────────┐
│ Your Complete Fintech Invoice Engine                  │
├────────────────────────────────────────────────────────┤
│                                                        │
│ Layer 1: Gatekeeper                                   │
│ └─ startup_health_check.ps1                          │
│    (Detects failures via 5 validators)               │
│                                                        │
│ Layer 2: Self-Healing                                │
│ └─ self_heal.ps1                                     │
│    (Repairs failures automatically)                  │
│                                                        │
│ Layer 3: Backup System                               │
│ └─ backup/ directory                                 │
│    (Restores corrupted assets)                       │
│                                                        │
│ Layer 4: Quarantine System                           │
│ └─ quarantine/ directory                             │
│    (Isolates permanent failures)                     │
│                                                        │
│ Layer 5: Audit Trail                                 │
│ ├─ logs/StartupHealth.log                            │
│ └─ logs/SelfHeal.log                                 │
│    (Compliance & troubleshooting)                    │
│                                                        │
│ Layer 6: Dashboard                                   │
│ ├─ web/index.html                                    │
│ ├─ web/health.json                                   │
│ └─ web/self_heal.json                                │
│    (Operator visibility)                             │
│                                                        │
│ Layer 7: Invoice Processing                          │
│ └─ Only runs if SYSTEM OK                           │
│    (Safe execution guaranteed)                       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

This is the architecture of a **production-grade fintech pipeline** with enterprise-level resilience.
