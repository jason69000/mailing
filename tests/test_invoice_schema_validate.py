import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import validator.invoice_schema_validate as schema_validator


def test_valid_invoice_schema(tmp_path, monkeypatch):
    data_dir = tmp_path / "data"
    data_dir.mkdir()
    invoice = {
        "invoice_number": "INV-TEST",
        "customer_name": "Test Customer",
        "customer_email": "customer@example.com",
        "issue_date": "2026-07-21",
        "due_date": "2026-08-20",
        "currency": "USD",
        "line_items": [
            {"description": "Service", "quantity": 1, "unit_price": 10, "amount": 10}
        ],
        "total_amount": 10,
    }
    (data_dir / "INV-TEST.json").write_text(json.dumps(invoice), encoding="utf-8")
    monkeypatch.setattr(schema_validator, "DATA_DIR", data_dir)

    result = schema_validator.validate_invoice_schema("INV-TEST")

    assert result["data_exists"] is True
    assert result["schema_ok"] is True
    assert result["errors"] == []


def test_invalid_invoice_schema_reports_field_error(tmp_path, monkeypatch):
    data_dir = tmp_path / "data"
    data_dir.mkdir()
    invoice = {"invoice_number": "INV-TEST", "customer_email": "not-an-email"}
    (data_dir / "INV-TEST.json").write_text(json.dumps(invoice), encoding="utf-8")
    monkeypatch.setattr(schema_validator, "DATA_DIR", data_dir)

    result = schema_validator.validate_invoice_schema("INV-TEST")

    assert result["data_exists"] is True
    assert result["schema_ok"] is False
    assert result["error"]
    assert result["errors"]