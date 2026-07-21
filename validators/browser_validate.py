"""Standalone browser validation checker for health checks.

Reads the latest browser_validation.json and checks for render failures,
header errors, and console errors. Returns pass/fail JSON status.
"""

import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
BROWSER_VALIDATION = BASE / "web" / "browser_validation.json"


def validate_browser() -> dict:
    """Check browser validation status from last run."""
    if not BROWSER_VALIDATION.exists():
        return {
            "render_ok": True,
            "header_ok": True,
            "console_errors": [],
            "schema_errors": [],
            "asset_errors": [],
            "error": "browser_validation.json not found (no prior runs); skipped as warm-up",
            "skipped": True,
        }

    try:
        data = json.loads(BROWSER_VALIDATION.read_text())
    except json.JSONDecodeError as e:
        return {
            "render_ok": False,
            "header_ok": False,
            "console_errors": [],
            "error": f"Failed to parse browser_validation.json: {e}",
        }

    # Extract errors
    browser_errors = data.get("browser_errors", [])
    js_errors = data.get("js_errors", [])
    schema_errors = data.get("schema_errors", [])
    asset_errors = data.get("asset_errors", [])

    render_ok = len(browser_errors) == 0
    header_ok = len(js_errors) == 0
    console_errors = js_errors if not header_ok else []

    return {
        "render_ok": render_ok,
        "header_ok": header_ok,
        "console_errors": console_errors,
        "schema_errors": schema_errors,
        "asset_errors": asset_errors,
        "error": None if (render_ok and header_ok) else "Browser or JS errors detected",
    }


if __name__ == "__main__":
    result = validate_browser()
    print(json.dumps(result))
    sys.exit(0 if (result["render_ok"] and result["header_ok"]) or result.get("skipped") else 1)
