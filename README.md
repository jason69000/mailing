# Fintech Invoice Generator

This repository contains a modular PowerShell invoice generator that reads recipient data from `recipients.csv`, fills a branded HTML invoice template, and optionally exports PDF files using `wkhtmltopdf`.

## Structure

- `engine.ps1` - main orchestration script
- `modules/` - reusable token modules for fintech branding and security features
- `templates/invoice_template.html` - responsive invoice HTML template
- `recipients.csv` - sample recipient data
- `assets/` - placeholder image assets for seals, watermarks, and icons
- `output_html/` - generated HTML invoices
- `output_pdf/` - generated PDF invoices

## Usage

- Open PowerShell in the repository root.
- Run:

    ```powershell
    .\engine.ps1
    ```

- View generated HTML in `output_html/`.
- Generated PDFs appear in `output_pdf/` when `wkhtmltopdf` is installed.
- Every run validates the HTML, PDF metadata, page count, and Chromium browser rendering before placing invoices in `email_queue.txt`.
- Every run validates the canonical `data/<invoice>.json` record against `validator/invoice_schema.json` before rendering HTML or generating PDFs. Install the schema dependency with `python -m pip install jsonschema`.
- Chromium validation captures console errors, warnings, logs, uncaught page errors, and failed resource requests. Console errors and uncaught page errors block queueing; the complete per-invoice result is saved in `web/browser_runtime.json`.
- A failed browser check also saves a full-page PNG under `web/screenshots/`; its relative path appears in `web/browser_validation.json` and the dashboard displays it as a thumbnail.
- PDF signatures are mandatory before queueing. Configure `PDF_SIGNATURE_TRUST_ROOTS` with PEM/DER root or intermediate CA certificate paths (separated by `;` on Windows); unsigned PDFs, untrusted certificates, invalid signatures, revoked certificates, and disallowed post-signature modifications are blocked. Revocation checking uses OCSP/CRL fetching in hard-fail mode. The policy is documented in `validator/pyhanko.yml`; the installed PyHanko version applies it through `ValidationContext` because it does not expose the YAML config loader API.
- To sign a real invoice, generate or obtain a signing certificate and private key, then run `python sign_invoice.py <invoice> <cert.pem> <key.pem> [password]`. The produced file is written to `output_pdf/<invoice>.signed.pdf`; point `PDF_SIGNATURE_TRUST_ROOTS` at the CA/root certificate used to issue the signing certificate so verification passes.
- On a failed validation, no invoices are queued and details are written to `validation_errors.log`.
- Schema failures are logged with `SCHEMA VALIDATION FAILED` and displayed in the admin dashboard.
- Every run validates frontend assets (`web/index.html`, `templates/invoice_template.html`) against SHA-256 checksums in `validator/asset_manifest.json`. Assets must not change outside the controlled build process.
- To regenerate the asset manifest after intentional code changes, run `python validator/generate_asset_hashes.py`. This updates the checked-in baseline.
- Asset integrity failures are logged with `ASSET INTEGRITY FAILED` and displayed in the admin dashboard.

## Startup Health Check

Before processing any invoices, the engine runs a comprehensive system integrity gate:

```powershell
.\startup_health_check.ps1
```

This script verifies:
- Asset integrity (SHA-256 manifest validation)
- Invoice schema validation (JSON structure enforcement)
- Browser rendering capability (Chromium/headless browser)
- PDF signature validator availability
- Python dependency availability (jsonschema, pyhanko, asn1crypto)

**Output:**
- `SYSTEM OK` — all checks passed; engine proceeds with invoice processing
- `SYSTEM BLOCKED` — one or more checks failed; engine halts with detailed error log

Details are logged to `logs/StartupHealth.log` and displayed in the **Health** panel of the admin dashboard.

## Self-Healing System

When startup health check reports **SYSTEM BLOCKED**, the engine automatically attempts self-healing before giving up:

```powershell
.\self_heal.ps1
```

This orchestrator:

1. **Detects** which subsystems failed
2. **Repairs** failures where possible:
   - Restores corrupted assets from `backup/web/` and `backup/validator/`
   - Clears browser cache and reinstalls Chromium
   - Restores CA certificate bundles and PyHanko config
   - Reinstalls Python dependencies
3. **Re-validates** each subsystem after repair
4. **Quarantines** persistent failures (marked in `quarantine/` directory)
5. **Logs everything** to `logs/SelfHeal.log` with audit trail

**Output:**
- `✅ SYSTEM RECOVERED` — all repairs successful; engine proceeds
- `❌ SYSTEM BLOCKED` — repairs failed; engine halts with quarantine report

Details are logged to `logs/SelfHeal.log` and displayed in the **Self-Heal** panel of the admin dashboard.

### Backup System

The self-healing layer depends on backups of critical assets:

```
backup/
├── web/                    # Baseline frontend files
│   ├── index.html
│   └── invoice_template.html
├── validator/              # Baseline validator configs
│   └── asset_manifest.json
└── certs/                  # CA certificate bundles
```

After intentional code changes, refresh backups with:

```powershell
cp web/index.html backup/web/index.html -Force
cp templates/invoice_template.html backup/web/invoice_template.html -Force
cp validator/asset_manifest.json backup/validator/asset_manifest.json -Force
```

### Quarantine Directory

Failed subsystems that cannot be auto-repaired are marked in `quarantine/`:

```
quarantine/
├── asset_integrity.quarantined
├── schema_validation.quarantined
├── browser_rendering.quarantined
├── pdf_signatures.quarantined
└── dependencies.quarantined
```

Each `.quarantined` file indicates a subsystem that requires manual investigation.

## Browser validation dashboard

The static dashboard in `web/index.html` displays browser-render failures from
`web/browser_validation.json`, which the engine refreshes at the end of each run.
Serve the project directory locally, then open the dashboard:

```powershell
python -m http.server 8000
```

Open `http://localhost:8000/web/` in a browser. The dashboard refreshes every three seconds and includes:
- **Startup Health** — Latest startup health check status
- **Self-Heal** — Latest self-healing attempt (if triggered)
- **Browser Render Failures** — Render-time errors
- **JavaScript Console Errors** — Runtime JS errors
- **Browser Failure Screenshots** — Visual capture of failures
- **PDF Signature Failures** — Signature/revocation errors
- **Invoice Schema Failures** — Data structure violations
- **Asset Integrity** — Frontend file hash verification

## Installing wkhtmltopdf

If you have `winget`, install with:

```powershell
winget install --id wkhtmltopdf.wkhtmltox --accept-package-agreements --accept-source-agreements
```

If you install manually, make sure the executable is available at:

```text
C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe
```

## Notes

- The script will skip PDF export if `wkhtmltopdf` is not found.
- The email and invoice verification URLs are generated from the CSV row data.
- Asset image files are referenced in the template but not required for HTML generation.
# mailing
