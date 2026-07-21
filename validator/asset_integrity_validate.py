"""Validate frontend assets against the checked-in SHA-256 manifest."""

import hashlib
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
MANIFEST_PATH = BASE / "validator" / "asset_manifest.json"


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as asset_file:
        for chunk in iter(lambda: asset_file.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_assets() -> dict:
    result = {"ok": True, "algorithm": "sha256", "mismatches": []}
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        if manifest.get("algorithm") != "sha256":
            result["ok"] = False
            result["mismatches"].append("manifest: unsupported hash algorithm")

        assets = manifest.get("assets")
        if not isinstance(assets, dict) or not assets:
            result["ok"] = False
            result["mismatches"].append("manifest: assets must be a non-empty object")
            return result

        for relative_path, expected_hash in assets.items():
            asset_path = BASE / Path(relative_path)
            if not asset_path.is_file():
                result["ok"] = False
                result["mismatches"].append(f"{relative_path}: missing")
                continue
            actual_hash = file_hash(asset_path)
            if actual_hash != expected_hash:
                result["ok"] = False
                result["mismatches"].append(f"{relative_path}: hash mismatch")
    except FileNotFoundError:
        result["ok"] = False
        result["mismatches"].append("manifest: missing")
    except (OSError, json.JSONDecodeError, TypeError, AttributeError) as exc:
        result["ok"] = False
        result["mismatches"].append(f"manifest: {exc}")

    return result


def main() -> int:
    result = validate_assets()
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
