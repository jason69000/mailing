"""Validate canonical invoice JSON before rendering or PDF generation."""

import json
import sys
from pathlib import Path

from jsonschema import Draft7Validator, FormatChecker

BASE = Path(__file__).resolve().parents[1]
DATA_DIR = BASE / "data"
SCHEMA_PATH = BASE / "validator" / "invoice_schema.json"

with SCHEMA_PATH.open("r", encoding="utf-8") as schema_file:
    SCHEMA = json.load(schema_file)

VALIDATOR = Draft7Validator(SCHEMA, format_checker=FormatChecker())


def validate_invoice_schema(invoice: str) -> dict:
    data_path = DATA_DIR / f"{invoice}.json"
    result = {
        "invoice": invoice,
        "data_exists": data_path.exists(),
        "schema_ok": False,
        "errors": [],
        "error": None,
    }

    if not result["data_exists"]:
        result["error"] = "Invoice data JSON missing"
        return result

    try:
        with data_path.open("r", encoding="utf-8") as data_file:
            data = json.load(data_file)

        errors = sorted(VALIDATOR.iter_errors(data), key=lambda item: list(item.path))
        result["errors"] = [
            {
                "path": ".".join(str(part) for part in error.path),
                "message": error.message,
            }
            for error in errors
        ]
        result["schema_ok"] = not errors
        if errors:
            result["error"] = "; ".join(error["message"] for error in result["errors"])
    except json.JSONDecodeError as exc:
        result["error"] = f"Invalid invoice JSON: {exc.msg}"
    except Exception as exc:
        result["error"] = str(exc)

    return result


def main() -> int:
    invoices = sys.argv[1:]
    if not invoices:
        print(json.dumps({"error": "Provide one or more invoice numbers."}))
        return 1

    results = [validate_invoice_schema(invoice) for invoice in invoices]
    all_valid = all(item["schema_ok"] for item in results)
    print(json.dumps({"all_valid": all_valid, "invoices": results}, indent=2))
    return 0 if all_valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
