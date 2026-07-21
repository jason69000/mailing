import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import validators.pdf_signature_validate as signature_validator


def test_unsigned_pdf_emits_explicit_failure_reason(tmp_path, monkeypatch):
    pdf_dir = tmp_path / "output_pdf"
    pdf_dir.mkdir(parents=True, exist_ok=True)
    (pdf_dir / "INV-TEST.pdf").write_bytes(b"%PDF-1.4\n%fake pdf")

    monkeypatch.setattr(signature_validator, "PDF_DIR", pdf_dir)

    class FakeReader:
        def __init__(self, _pdf_file):
            self.embedded_signatures = []

    monkeypatch.setattr(signature_validator, "PdfFileReader", FakeReader)

    result = signature_validator.validate_invoice("INV-TEST", [])

    assert result["signed"] is False
    assert result["error"] == "PDF is not signed"
