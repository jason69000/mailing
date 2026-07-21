import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import validator.asset_integrity_validate as asset_validator


def test_manifest_matches_assets():
    result = asset_validator.validate_assets()

    assert result["ok"] is True
    assert result["mismatches"] == []


def test_manifest_detects_changed_asset(tmp_path, monkeypatch):
    asset_path = tmp_path / "asset.js"
    asset_path.write_text("console.log('original');", encoding="utf-8")
    manifest_path = tmp_path / "asset_manifest.json"
    manifest_path.write_text(
        json.dumps(
            {
                "algorithm": "sha256",
                "assets": {
                    "asset.js": hashlib.sha256(b"console.log('expected');").hexdigest()
                },
            }
        ),
        encoding="utf-8",
    )
    monkeypatch.setattr(asset_validator, "BASE", tmp_path)
    monkeypatch.setattr(asset_validator, "MANIFEST_PATH", manifest_path)

    result = asset_validator.validate_assets()

    assert result["ok"] is False
    assert result["mismatches"] == ["asset.js: hash mismatch"]