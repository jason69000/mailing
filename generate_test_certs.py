from pathlib import Path
from datetime import datetime, timedelta, timezone
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption

base = Path(__file__).resolve().parent
root_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
leaf_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

now = datetime.now(timezone.utc)
root_name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Invoice Test Root CA')])
leaf_name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Invoice Test Signer')])

root_builder = (
    x509.CertificateBuilder()
    .subject_name(root_name)
    .issuer_name(root_name)
    .public_key(root_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - timedelta(days=1))
    .not_valid_after(now + timedelta(days=30))
    .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
    .add_extension(x509.SubjectKeyIdentifier.from_public_key(root_key.public_key()), critical=False)
)
root_cert = root_builder.sign(root_key, hashes.SHA256())

leaf_builder = (
    x509.CertificateBuilder()
    .subject_name(leaf_name)
    .issuer_name(root_name)
    .public_key(leaf_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - timedelta(days=1))
    .not_valid_after(now + timedelta(days=30))
    .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
    .add_extension(x509.SubjectKeyIdentifier.from_public_key(leaf_key.public_key()), critical=False)
)
leaf_cert = leaf_builder.sign(root_key, hashes.SHA256())

(base / 'test_signing_cert.pem').write_bytes(leaf_cert.public_bytes(Encoding.PEM))
(base / 'test_signing_key.pem').write_bytes(leaf_key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()))
(base / 'test_root_cert.pem').write_bytes(root_cert.public_bytes(Encoding.PEM))
print('generated')
