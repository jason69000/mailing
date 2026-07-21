"""Generate the SHA-256 manifest for frontend assets."""

import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
MANIFEST_PATH = BASE / "validator" / "asset_manifest.json"
ASSETS = (
    Path("web/index.html"),
    Path("templates/invoice_template.html"),
)


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as asset_file:
        for chunk in iter(lambda: asset_file.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    assets = {}
    missing = []
    for relative_path in ASSETS:
        full_path = BASE / relative_path
        if not full_path.is_file():
            missing.append(str(relative_path))
            continue
        assets[relative_path.as_posix()] = file_hash(full_path)

    if missing:
        raise FileNotFoundError(f"Missing manifest assets: {', '.join(missing)}")

    MANIFEST_PATH.write_text(
        json.dumps({"algorithm": "sha256", "assets": assets}, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Manifest updated: {MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
