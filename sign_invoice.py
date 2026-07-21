"""Sign generated PDFs with a real certificate and emit a trust-root guidance note."""

import os
import sys
from pathlib import Path

from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
from pyhanko.sign import signers
from pyhanko.sign.signers import PdfSignatureMetadata

BASE = Path(__file__).resolve().parent
PDF_DIR = BASE / "output_pdf"


def sign_invoice(invoice: str, cert_path: str, key_path: str, password: str | None = None) -> str:
    pdf_path = PDF_DIR / f"{invoice}.pdf"
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    out_path = PDF_DIR / f"{invoice}.signed.pdf"
    with pdf_path.open("rb") as src:
        writer = IncrementalPdfFileWriter(src)
        signer = signers.SimpleSigner.load(
            cert_file=cert_path,
            key_file=key_path,
            key_passphrase=password.encode("utf-8") if password else None,
        )
        sig_meta = PdfSignatureMetadata(field_name="Signature1", name="Fintech Invoice Engine")
        # Write signature to a binary stream to satisfy pyHanko API expectations
        with out_path.open('w+b') as out_stream:
            signers.sign_pdf(writer, sig_meta, signer, output=out_stream)
    out_path.replace(pdf_path)
    return str(pdf_path)


def main() -> int:
    if len(sys.argv) < 4:
        print("Usage: python sign_invoice.py <invoice> <cert.pem> <key.pem> [password]")
        return 1

    invoice = sys.argv[1]
    cert_path = sys.argv[2]
    key_path = sys.argv[3]
    password = sys.argv[4] if len(sys.argv) > 4 else None

    try:
        output = sign_invoice(invoice, cert_path, key_path, password)
    except Exception as exc:  # pragma: no cover - CLI safety
        print(f"SIGNING_FAILED {exc}")
        return 1

    print(f"SIGNED {output}")
    print("Set PDF_SIGNATURE_TRUST_ROOTS to the path of the signing CA certificate root to enable verification.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
