#!/bin/bash
# tests/test_access.sh — anna-access (the record access log) against a throwaway record, state and config.
# Run from the repo root: tests/test_access.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml
mkdir -p "$T/anna-record/hosts" "$T/anna-record/journal/2026/11" "$T/anna-record/memory" "$T/sec"
touch "$T/anna-record/hosts/nas.md" "$T/anna-record/journal/2026/11/2026-11-07.md" "$T/anna-record/hosts/.env"
printf '[anna]\ntimezone = "UTC"\n[paths]\nrecord = "%s/anna-record"\nstate = "%s/state"\nsecrets = "%s/sec"\n' "$T" "$T" "$T" > "$ANNA_CONFIG"
unset ANNA_ROLE ANNA_HEADLESS
python3 - "$T" <<'PY'
import json, os, stat, subprocess, sys, tempfile
T = sys.argv[1]; BIN = os.path.abspath("bin/anna-access"); REC = f"{T}/anna-record"; fail = 0

def run(ev, extra=None, raw=None):
    d = tempfile.mkdtemp(dir=T); env = dict(os.environ, ANNA_ACCESS_DIR=d); env.update(extra or {})
    p = subprocess.run([BIN, "hook"], input=raw if raw is not None else json.dumps(ev), capture_output=True, text=True, env=env, timeout=10)
    rows = [json.loads(l) for n in os.listdir(d) for l in open(os.path.join(d, n))]
    return p, rows, d

def check(name, cond):
    global fail
    print(("ok   " if cond else "FAIL ") + name); fail |= not cond

p, rows, d = run({"tool_name": "Read", "tool_input": {"file_path": f"{REC}/hosts/nas.md"}, "session_id": "abcdef123", "cwd": T})
check("Read of a record file → anna-record/hosts/nas.md", rows and rows[0]["paths"] == ["anna-record/hosts/nas.md"] and rows[0]["kind"] == "read")
check("actor brain, sid 8 chars", rows and rows[0]["actor"] == "brain" and rows[0]["sid"] == "abcdef12")
f = os.path.join(d, os.listdir(d)[0]) if rows else None
check("log file is 0600", f and stat.S_IMODE(os.stat(f).st_mode) == 0o600)
check("hook prints nothing, exit 0", p.returncode == 0 and p.stdout == "" and p.stderr == "")
_, rows, _ = run({"tool_name": "Read", "tool_input": {"file_path": f"{T}/sec/telegram-ops"}, "cwd": T})
check("the secrets store is never logged", rows == [])
_, rows, _ = run({"tool_name": "Bash", "tool_input": {"command": f"cat {T}/sec/x {REC}/hosts/nas.md"}, "cwd": T})
check("a Bash command naming the secrets store logs nothing", rows == [])
_, rows, _ = run({"tool_name": "Read", "tool_input": {"file_path": f"{REC}/hosts/.env"}, "cwd": T})
check(".env in the record is never logged", rows == [])
_, rows, _ = run({"tool_name": "Read", "tool_input": {"file_path": "/etc/hosts"}, "cwd": T})
check("paths outside the record are not logged", rows == [])
_, rows, _ = run({"tool_name": "Bash", "tool_input": {"command": "sed -n 1,20p hosts/nas.md journal/2026/11/2026-11-07.md | grep x"}, "cwd": REC})
check("Bash: relative record paths resolved from cwd", rows and set(rows[0]["paths"]) == {"anna-record/hosts/nas.md", "anna-record/journal/2026/11/2026-11-07.md"})
resp = "index fresh\n\n1. [host] anna-record/hosts/nas.md · 2026-11-01 · score 0.03\n2. [journal] anna-record/journal/2026/11/2026-11-07.md · x\n"
_, rows, _ = run({"tool_name": "mcp__merlin__search", "tool_input": {"query": "nas backup"}, "tool_response": {"result": resp}, "cwd": T})
check("merlin search: query and top hits", rows and rows[0]["q"] == "nas backup" and rows[0]["top"] == ["anna-record/hosts/nas.md", "anna-record/journal/2026/11/2026-11-07.md"])
_, rows, _ = run({"tool_name": "Read", "tool_input": {"file_path": f"{REC}/hosts/nas.md"}, "cwd": T}, {"ANNA_ROLE": "bot"})
check("actor bot", rows and rows[0]["actor"] == "bot")
_, rows, _ = run({"tool_name": "Read", "tool_input": {"file_path": f"{REC}/hosts/nas.md"}, "agent_type": "anna-memory", "cwd": T})
check("actor subagent:anna-memory", rows and rows[0]["actor"] == "subagent:anna-memory")
p, rows, _ = run(None, raw="not json{{")
check("garbage input fails open", p.returncode == 0 and p.stdout == "" and rows == [])
d = tempfile.mkdtemp(dir=T); env = dict(os.environ, ANNA_ACCESS_DIR=d)
for ev in ({"tool_name": "Read", "tool_input": {"file_path": f"{REC}/hosts/nas.md"}, "cwd": T},
           {"tool_name": "mcp__merlin__search", "tool_input": {"query": "x"}, "tool_response": "1. [host] anna-record/hosts/other.md · y", "cwd": T}):
    subprocess.run([BIN, "hook"], input=json.dumps(ev), text=True, env=env)
s = subprocess.run([BIN, "stats", "--week"], capture_output=True, text=True, env=env).stdout
check("stats --week: one line, uses, hot file, unopened search", s.count("\n") == 1 and "2 uses" in s and "hosts/nas.md 1" in s and "1 with no top hit opened" in s)
sys.exit(fail)
PY
rc=$?
out=$(bin/anna-checks access 2>&1)
if echo "$out" | grep -q "⚠ access: no entries"; then echo "ok   anna-checks access: an empty log is ⚠"; else echo "FAIL anna-checks access: an empty log is ⚠"; rc=1; fi
exit $rc
