#!/bin/bash
# tests/test_body_checks.sh — anna-checks and anna-body with throwaway checks/senses in a throwaway record.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml PATH="$PWD/bin:/usr/bin:/bin"
mkdir -p "$T/record/checks" "$T/record/senses"
printf '[anna]\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\n' "$T" "$T" > "$ANNA_CONFIG"
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
mk() { printf '#!/bin/bash\n%s\n' "$2" > "$1"; chmod +x "$1"; }

mk "$T/record/checks/backup" 'echo "OK backup: 3h old"'
mk "$T/record/checks/mail" 'echo "⛔ mail: queue stuck"'
mk "$T/record/checks/broken" 'echo "oops" >&2; exit 3'
mk "$T/record/checks/disk" 'echo "OK disk: mine"'
out=$(bin/anna-checks)
ok "runs the built-ins" 'echo "$out" | grep -q "^OK relay: not enabled" && echo "$out" | grep -qE "^(OK|⚠|⛔) disk"'
ok "runs your checks" 'echo "$out" | grep -q "^OK backup: 3h old" && echo "$out" | grep -q "^⛔ mail: queue stuck"'
ok "a check that fails to run is ⚠, never OK" 'echo "$out" | grep -q "^⚠ broken: check failed to run (exit 3)"'
ok "a check named like a built-in is flagged, not silently shadowed" 'echo "$out" | grep -q "^⚠ checks: .*/disk has a built-in.s name"'
ok "sections can be picked" '[ "$(bin/anna-checks backup | grep -c "^\$ ")" -eq 1 ]'
ok "an unknown section says so" 'bin/anna-checks nope | grep -q "^⚠ nope: no such section"'

mk "$T/record/senses/ups" 'echo "{\"severity\":2,\"sensation\":\"hungry\",\"why\":\"on battery, 60%\"}"'
mk "$T/record/senses/solar" 'echo "{\"severity\":0,\"sensation\":\"sunlit\",\"why\":\"solar 300 W\"}"'
mk "$T/record/senses/junk" 'echo "not json"'
mk "$T/record/senses/slow" 'sleep 30'
s=$(bin/anna-body)
ok "body: valid JSON with every sense" 'jq -e ".senses | has(\"self\") and has(\"ups\") and has(\"solar\") and has(\"junk\") and has(\"slow\")" <<<"$s" >/dev/null'
ok "body: junk output is numb, not fine" 'jq -e ".senses.junk[0].sensation == \"numb\"" <<<"$s" >/dev/null'
ok "body: a hanging sense is numb, and the run stays fast" 'jq -e ".senses.slow[0].sensation == \"numb\" and .took_s < 14" <<<"$s" >/dev/null'
line=$(bin/anna-body --line)
ok "body --line leads with the worst feeling" 'echo "$line" | grep -q "^hungry: on battery, 60%"'
ok "and mentions the good ones" 'echo "$line" | grep -q "sunlit"'

# the relay check's night window (close → open + 5 min), also when the day closes before midnight
n() { bin/anna-checks --in-night "$@"; }
ok "night: 00:30→04:15, 01:00 is night" '[ "$(n 0100 0030 0415)" = 1 ]'
ok "night: 00:30→04:15, 04:19 still night, 04:20 not" '[ "$(n 0419 0030 0415)" = 1 ] && [ "$(n 0420 0030 0415)" = 0 ]'
ok "night: 00:30→04:15, 12:00 not" '[ "$(n 1200 0030 0415)" = 0 ]'
ok "night: 23:00→04:15, 23:30 and 01:00 are night" '[ "$(n 2330 2300 0415)" = 1 ] && [ "$(n 0100 2300 0415)" = 1 ]'
ok "night: 23:00→04:15, 22:59 and 12:00 not" '[ "$(n 2259 2300 0415)" = 0 ] && [ "$(n 1200 2300 0415)" = 0 ]'
ok "night: open 04:58 + 5 min = 05:03 (minutes, not HHMM + 5)" '[ "$(n 0502 0030 0458)" = 1 ] && [ "$(n 0503 0030 0458)" = 0 ]'
exit $fail
