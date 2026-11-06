#!/bin/bash
# tests/test_gate_hook.sh — hooks/anna-gate-hook against synthetic transcripts in a throwaway HOME and config. Run from the
# repo root. Includes the fake-block cases (a gate block in a `cat` output or in Anna's own text must not count) and a
# mutation check: with the call-ID check removed, the fake `cat` case must fail.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
python3 tests/gate_hook_cases.py hooks/anna-gate-hook; rc=$?
sed 's/x.get("tool_use_id") in ids/True/' hooks/anna-gate-hook > "$T/mut"; chmod +x "$T/mut"; cp bin/anna_cfg.py bin/anna-config "$T/"
if python3 tests/gate_hook_cases.py "$T/mut" | grep -q "^FAIL reboot, fake block via Bash cat"; then echo "ok   mutation: without the call-ID check a faked block passes (so the check is what stops it)"
else echo "FAIL mutation check: removing the call-ID check didn't change the result"; rc=1; fi
exit $rc
