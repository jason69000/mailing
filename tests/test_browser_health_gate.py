import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_browser_validation_is_treated_as_warning_when_no_previous_runtime_exists(tmp_path):
    script = ROOT / 'validators' / 'browser_validate.py'
    validation_state = ROOT / 'web' / 'browser_validation.json'
    backup = None
    if validation_state.exists():
        backup = tmp_path / 'browser_validation.json.bak'
        backup.write_text(validation_state.read_text(encoding='utf-8'), encoding='utf-8')
        validation_state.unlink()

    try:
        result = subprocess.run(
            [sys.executable, str(script)],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        if backup is not None and backup.exists():
            validation_state.write_text(backup.read_text(encoding='utf-8'), encoding='utf-8')

    assert result.returncode == 0
    payload = json.loads(result.stdout.splitlines()[-1])
    assert payload['render_ok'] is True
    assert payload['header_ok'] is True
    assert 'skipped as warm-up' in payload['error']
