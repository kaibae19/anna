"""anna_cfg — shared config + helpers for Anna's Python scripts (imported from the script's own directory).

    from anna_cfg import CFG, get, path, TZ, USER, redact
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from zoneinfo import ZoneInfo

_HERE = Path(__file__).resolve().parent


def _load() -> dict:
    exe = _HERE / "anna-config"
    try:
        r = subprocess.run([str(exe) if exe.exists() else "anna-config", "--dump"], capture_output=True, text=True, timeout=10)
        return json.loads(r.stdout) if r.returncode == 0 else {}
    except Exception:  # noqa: BLE001  a missing config must never break a hook
        return {}


CFG = _load()


def get(dotted: str, default=None):
    v = CFG
    for part in dotted.split("."):
        if not isinstance(v, dict) or part not in v:
            return default
        v = v[part]
    return v


def path(dotted: str, default: str) -> Path:
    return Path(os.path.expanduser(str(get(dotted, default))))


TZ = ZoneInfo(get("anna.timezone", "UTC"))
USER = get("anna.user", "user")
NAME = get("anna.name", "Anna")
STATE = path("paths.state", "~/.local/state/anna")
RECORD = path("paths.record", "~/anna-record")

try:  # merlin's redaction if importable (MERLIN_PATH points at a merlin checkout), else blunt built-in patterns
    if os.environ.get("MERLIN_PATH"):
        sys.path.insert(0, os.environ["MERLIN_PATH"])
    from merlin.redact import redact  # type: ignore  # noqa: F401
except Exception:  # noqa: BLE001
    _SECRET = re.compile(
        r"(?:sk-[A-Za-z0-9_\-]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|xox[abpr]-[A-Za-z0-9\-]{20,}|AKIA[0-9A-Z]{16}"
        r"|eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}"
        r"|-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----"
        r"|\b[A-Fa-f0-9]{40}\b|\b[A-Za-z0-9_\-]{40,}\b)", re.S)

    def redact(s: str) -> tuple[str, int]:
        return _SECRET.subn("[REDACTED]", s)
