#!/bin/bash
# tests/test_pushed_senses.sh — examples/pushed-senses: prometheus-alerts sends edges (fire, no repeat, resolve) and the
# dead-man after 3 failed runs; container-updates turns Watchtower output into the right digest lines.
# Run from the repo root: tests/test_pushed_senses.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_STATE=$T/state; E=examples/pushed-senses; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
# a stand-in anna-sense-send that records what it was asked to send
mkdir -p "$T/bin"; printf '#!/bin/sh\necho "$@" >> %s/sent\n' "$T" > "$T/bin/anna-sense-send"; chmod +x "$T/bin/anna-sense-send"
export PATH="$T/bin:$PATH"

cat > "$T/firing.json" <<'J'
{"data":{"alerts":[{"state":"firing","activeAt":"2026-01-01T10:00:00Z","value":"97",
 "labels":{"alertname":"DiskFull","instance":"nas:9100","device":"/dev/sda1","severity":"critical"},
 "annotations":{"summary":"nas disk 97% full"}}]}}
J
echo '{"data":{"alerts":[]}}' > "$T/none.json"
$E/prometheus-alerts --from-file "$T/firing.json" >/dev/null
ok "a new firing alert is sent, high, tell" 'grep -q "prometheus nas disk 97% full .*--state firing --do tell --importance high" "$T/sent"'
$E/prometheus-alerts --from-file "$T/firing.json" >/dev/null
ok "the same alert is not sent twice" '[ "$(wc -l < "$T/sent")" -eq 1 ]'
$E/prometheus-alerts --from-file "$T/none.json" >/dev/null
ok "a cleared alert sends resolved, log" 'grep -q "resolved: nas disk 97% full .*--state resolved --do log" "$T/sent"'
: > "$T/sent"
for i in 1 2 3 4; do $E/prometheus-alerts --from-file "$T/missing.json" >/dev/null 2>&1; done
ok "dead-man: one high tell after 3 failed runs" '[ "$(grep -c "PrometheusUnreachable .*--state firing --do tell --importance high" "$T/sent")" -eq 1 ]'
$E/prometheus-alerts --from-file "$T/none.json" >/dev/null
ok "dead-man clears with a normal tell" 'grep -q "Prometheus answers again.*--state resolved --do tell --importance normal" "$T/sent"'
ok "--dry-run sends nothing" ': > "$T/sent"; rm -f "$ANNA_STATE/prometheus-alerts.json"; $E/prometheus-alerts --dry-run --from-file "$T/firing.json" | grep -q ^DRY && [ ! -s "$T/sent" ]'

cat > "$T/wt.txt" <<'W'
time="2026-01-01T03:30:05Z" level=info msg="Found new image" container=db image=postgres:16-alpine new_id=abc
time="2026-01-01T03:30:09Z" level=info msg="Started new container" container=web image=nginx:latest
time="2026-01-01T03:30:12Z" level=info msg="session completed" failed=0 scanned=5 updated=1
--- monitor-only
db postgres:16-alpine
W
out=$($E/container-updates --print --from-file "$T/wt.txt")
ok "digest: auto-update line" 'grep -q "✅ test auto-updated: web" <<<"$out"'
ok "digest: pinned update waiting" 'grep -q "📌 test update waiting (pinned): db (postgres:16-alpine)" <<<"$out"'
printf -- '--- monitor-only\n' > "$T/quiet.txt"
ok "digest: nothing to report sends nothing" '$E/container-updates --print --from-file "$T/quiet.txt" | grep -q "nothing to report"'
: > "$T/sent"; $E/container-updates --from-file "$T/wt.txt"
ok "digest: pinned waiting → normal tell, dated id" 'grep -q "^updates Container updates" "$T/sent" && grep -q -- "--do tell --importance normal .*--id digest-" "$T/sent"'
exit $fail
