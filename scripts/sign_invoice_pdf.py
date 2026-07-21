import sys
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from asn1crypto import x509 as asn1_x509
from asn1crypto import keys as asn1_keys
from asn1crypto import pem as asn1_pem
from pyhanko.pdf_utils import writer as pdf_writer
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign import signers
from pyhanko.sign.signers import PdfSignatureMetadata
from pyhanko_certvalidator.registry import SimpleCertificateStore

BASE = Path(__file__).resolve().parents[1]
PDF_DIR = BASE / "output_pdf"
CERT_DIR = BASE / "certs"
CERT_DIR.mkdir(exist_ok=True)


def generate_self_signed_certificate(cert_path: Path, key_path: Path) -> None:
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, "Fintech Invoice Test CA"),
    ])
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(__import__('datetime').datetime.utcnow() - __import__('datetime').timedelta(days=1))
        .not_valid_after(__import__('datetime').datetime.utcnow() + __import__('datetime').timedelta(days=30))
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=0),
            critical=True,
        )
        .sign(key, hashes.SHA256())
    )
    cert_path.write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    key_path.write_bytes(key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ))


def sign_pdf(invoice: str, cert_path: Path, key_path: Path, output_path: Path | None = None) -> Path:
    if output_path is None:
        output_path = PDF_DIR / f"{invoice}.pdf"
    if not output_path.exists():
        raise FileNotFoundError(output_path)

    if not cert_path.exists() or not key_path.exists():
        generate_self_signed_certificate(cert_path, key_path)

    cert_bytes = cert_path.read_bytes()
    key_bytes = key_path.read_bytes()
    cert = x509.load_pem_x509_certificate(cert_bytes)
    asn1_cert = asn1_x509.Certificate.load(cert.public_bytes(serialization.Encoding.DER))
    _, _, key_der = asn1_pem.unarmor(key_bytes)
    key = asn1_keys.PrivateKeyInfo.load(key_der)

    signer = signers.SimpleSigner(
        signing_cert=asn1_cert,
        signing_key=key,
        cert_registry=SimpleCertificateStore.from_certs([asn1_cert]),
    )
    signature_meta = PdfSignatureMetadata(
        field_name="Signature1",
        reason="Fintech invoice signature",
        contact_info="",
        location="",
        name="Fintech Invoice Engine",
    )
    with output_path.open('rb') as src:
        pdf = PdfFileReader(src)
        writer = pdf_writer.PdfFileWriter(stream_xrefs=True, init_page_tree=True)

        root = pdf.root
        pages_ref = root.raw_get('/Pages')
        pages_obj = pdf.get_object(pages_ref)
        kid_refs = pages_obj.raw_get('/Kids')
        for kid_ref in kid_refs:
            child_obj = pdf.get_object(kid_ref)
            imported_page = writer.import_object(child_obj)
            imported_page.pop('/Parent', None)
            writer.insert_page(imported_page)

    with output_path.open('w+b') as output_stream:
        signers.sign_pdf(writer, signature_meta, signer, output=output_stream)
    return output_path


if __name__ == '__main__':
    invoice = sys.argv[1] if len(sys.argv) > 1 else "INV-2026-1001"
    cert_path = CERT_DIR / f"{invoice}.crt.pem"
    key_path = CERT_DIR / f"{invoice}.key.pem"
    output_path = PDF_DIR / f"{invoice}.pdf"
    sign_pdf(invoice, cert_path, key_path, output_path)
    print(output_path)
    print(cert_path)
