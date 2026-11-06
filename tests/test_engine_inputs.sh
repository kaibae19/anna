#!/bin/bash
# tests/test_engine_inputs.sh — anna-rhythm and backlog-age (the engines' precomputed inputs) against a throwaway config,
# stream and record. Run from the repo root.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml
printf '[anna]\nuser = "Sam"\ntimezone = "Europe/Berlin"\n[paths]\nstate = "%s/state"\nrecord = "%s/rec"\n[day]\nwrap = "/anna-wrapup overnight"\n' "$T" "$T" > "$ANNA_CONFIG"
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
mkdir -p "$T/state/stream" "$T/rec/planning"
d=$(TZ=Europe/Berlin date +%F)
{ printf '{"ts": "%sT09:15:00+01:00", "from": "bot", "text": "Sam: morning"}\n' "$d"
  printf '{"ts": "%sT04:15:00+01:00", "from": "session", "text": "Sam: /anna-wrapup overnight"}\n' "$d"
  printf '{"ts": "%sT05:00:00+01:00", "from": "session", "text": "Sam: [relay r1 from the bot] x"}\n' "$d"
  printf '{"ts": "%sT09:40:00+01:00", "from": "session", "text": "Anna: hi"}\n' "$d"; } > "$T/state/stream/$d.jsonl"
out=$(bin/anna-rhythm)
ok "rhythm counts the user's messages (09–10 today)" 'echo "$out" | grep -q "^today: .*09–10"'
ok "rhythm ignores the scripted wrap-up and relays (no 04 or 05 window)" '! echo "$out" | grep -qE "0[45]–"'
ok "rhythm names the timezone" 'echo "$out" | grep -q "Europe/Berlin"'
ok "asked_today is no without a curiosity line" 'echo "$out" | grep -qx "asked_today: no"'
printf '{"ts": "%sT10:00:00+01:00", "from": "curiosity", "text": "asked: which disk?"}\n' "$d" >> "$T/state/stream/$d.jsonl"
ok "asked_today is yes after a curiosity line" 'bin/anna-rhythm | grep -qx "asked_today: yes"'
ok "rhythm --json parses" 'bin/anna-rhythm --json | jq -e .typical >/dev/null'
ok "backlog-age without a backlog says none" 'bin/backlog-age | grep -q "^none"'
old=$(TZ=Europe/Berlin date -d "-20 days" +%F 2>/dev/null || TZ=Europe/Berlin date -v-20d +%F)
cat > "$T/rec/planning/backlog.md" <<EOB
# Backlog
- **($old) Replace the old switch:** later.
- **($d) ✅ done today ~~Fix DNS~~:** done.
- **($old) ~~Retire the printer~~:** gone.
- **($old) Garage sensor:** ✅ battery swapped; left: the mount.
EOB
out=$(bin/backlog-age)
ok "an open item gets its age" 'echo "$out" | grep -q "^20d .*Replace the old switch"'
ok "done items are skipped" '! echo "$out" | grep -qE "Fix DNS|Retire the printer"'
ok "a part-done item is marked" 'echo "$out" | grep -q "Garage sensor.*part done"'
ok "--min-days filters" '[ "$(bin/backlog-age --min-days 30)" = "none" ]'
exit $fail
