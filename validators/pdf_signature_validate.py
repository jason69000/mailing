"""Strict PDF signature verification for generated invoices.

Configure PDF_SIGNATURE_TRUST_ROOTS with one or more PEM/DER root certificate
paths separated by the platform path separator before sending signed invoices.
"""

import json
import os
import sys
from pathlib import Path

from asn1crypto import x509 as asn1_x509
from cryptography import x509 as crypto_x509
from cryptography.hazmat.primitives.serialization import Encoding
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign.validation import validate_pdf_signature
from pyhanko.sign.validation.status import ModificationLevel
from pyhanko_certvalidator import ValidationContext

BASE = Path(__file__).resolve().parents[1]
PDF_DIR = BASE / "output_pdf"
TRUST_ROOTS_ENV = "PDF_SIGNATURE_TRUST_ROOTS"
ALLOWED_MODIFICATIONS = {ModificationLevel.NONE, ModificationLevel.LTA_UPDATES}
REVOCATION_MODE = "hard-fail"


def load_trust_roots() -> list[asn1_x509.Certificate]:
    configured_paths = [Path(value) for value in os.environ.get(TRUST_ROOTS_ENV, "").split(os.pathsep) if value]
    roots = []
    for path in configured_paths:
        raw = path.read_bytes()
        if b"-----BEGIN CERTIFICATE-----" in raw:
            certificate = crypto_x509.load_pem_x509_certificate(raw)
            raw = certificate.public_bytes(Encoding.DER)
        roots.append(asn1_x509.Certificate.load(raw))
    return roots


def validate_invoice(invoice: str, trust_roots: list[asn1_x509.Certificate]) -> dict:
    pdf_path = PDF_DIR / f"{invoice}.pdf"
    result = {
        "invoice": invoice,
        "pdf_exists": pdf_path.exists(),
        "signed": False,
        "valid_signature": False,
        "trusted_certificate": False,
        "tamper_detected": None,
        "revoked": None,
        "signature_count": 0,
        "signatures": [],
        "error": None,
    }
    if not result["pdf_exists"]:
        result["error"] = "PDF missing"
        return result
    try:
        with pdf_path.open("rb") as pdf_file:
            signatures = list(PdfFileReader(pdf_file).embedded_signatures)
            result["signature_count"] = len(signatures)
            if not signatures:
                result["error"] = "PDF is not signed"
                return result

            result["signed"] = True
            if not trust_roots:
                result["error"] = f"No trust roots configured; set {TRUST_ROOTS_ENV}."
                return result
            context = ValidationContext(
                trust_roots=trust_roots,
                allow_fetching=True,
                revocation_mode=REVOCATION_MODE,
            )
            for signature in signatures:
                status = validate_pdf_signature(signature, signer_validation_context=context)
                modification_level = status.modification_level
                tampered = not status.intact or modification_level not in ALLOWED_MODIFICATIONS
                revoked = bool(status.revoked)
                signature_result = {
                    "valid": bool(status.valid and status.intact),
                    "trusted": bool(status.trusted),
                    "tamper_detected": tampered,
                    "revoked": revoked,
                    "modification_level": modification_level.name if modification_level else None,
                }
                result["signatures"].append(signature_result)

            result["valid_signature"] = all(item["valid"] for item in result["signatures"])
            result["trusted_certificate"] = all(item["trusted"] for item in result["signatures"])
            result["tamper_detected"] = any(item["tamper_detected"] for item in result["signatures"])
            result["revoked"] = any(item["revoked"] for item in result["signatures"])
            if not result["valid_signature"]:
                result["error"] = "Signature validation failed"
            elif result["revoked"]:
                result["error"] = "Signing certificate revoked"
            elif not result["trusted_certificate"]:
                result["error"] = "Certificate trust validation failed"
            elif result["tamper_detected"]:
                result["error"] = "Post-signature tampering detected"
    except Exception as exc:
        result["error"] = str(exc)
    return result


def main() -> int:
    invoices = sys.argv[1:]
    if not invoices:
        print(json.dumps({"error": "Provide one or more invoice numbers."}))
        return 1
    try:
        trust_roots = load_trust_roots()
    except Exception as exc:
        print(json.dumps({"error": f"Could not load trust roots: {exc}"}))
        return 1

    results = [validate_invoice(invoice, trust_roots) for invoice in invoices]
    all_valid = all(
        item["signed"] and item["valid_signature"] and item["trusted_certificate"]
        and not item["tamper_detected"] and not item["revoked"] and not item["error"]
        for item in results
    )
    print(json.dumps({"all_valid": all_valid, "invoices": results}, indent=2))
    return 0 if all_valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
