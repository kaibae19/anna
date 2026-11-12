#!/bin/bash
# tests/test_tell.sh — the one door (anna-tell, anna-presence, the `tell` check) against a throwaway config and stream.
# anna-tell runs dry (ANNA_TELL_DRY=1: prints what it would do); anna-presence reads a stream written here.
# Run from the repo root: tests/test_tell.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml TZ=UTC
cat > "$ANNA_CONFIG" <<EOF
[anna]
user = "Sam"
timezone = "UTC"
[paths]
state = "$T/state"
bin = "$T/bin"
[relay]
enabled = true
[senses]
enabled = true
EOF
mkdir -p "$T/state/stream" "$T/bin"
P=bin/anna-presence; A=bin/anna-tell; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
day=$(date -u +%F)
line() { printf '{"ts": "%sT%s:00+00:00", "from": "%s", "text": "%s"}\n' "$day" "$1" "$2" "$3" >> "$T/state/stream/$day.jsonl"; }

# presence: from the stream, never guessed
line 06:30 session "Sam: good morning"
line 06:40 session "Sam: [relay r1 from the bot] typed by a script"
line 07:00 bot "Sam: hi from the phone"
j() { $P --json --at "${day}T$1:00+00:00"; }
ok "active in the session" '[ "$(j 06:35 | jq -r .where)" = session ]'
ok "script-typed lines don't count as the person" '[ "$(j 06:45 | jq -r .session.last)" = 06:30 ]'
ok "bot more recent → bot" '[ "$(j 07:05 | jq -r .where)" = bot ]'
ok "nothing for 10 min → away" '[ "$(j 07:20 | jq -r .where)" = away ]'
ok "first message today" '[ "$(j 07:20 | jq -r .first_today)" = 06:30 ]'
ok "never quiet while active" '[ "$(j 06:35 | jq -r .quiet)" = false ]'

# routing (dry): presence is stubbed with ANNA_TELL_PRESENCE so each case is exact
route() { ANNA_TELL_DRY=1 ANNA_TELL_PRESENCE="$1" ANNA_TELL_DIR=$T/tell $A route <<<"$2"; }
ev() { printf '{"v":1,"source":"garage","do":"%s","importance":"%s","message":"%s"}' "$1" "$2" "$3"; }
ok "low → log only" 'route "{\"where\":\"away\"}" "$(ev tell low quiet)" | grep -qx "log (low)"'
ok "check → the brain, whatever the time" 'route "{\"where\":\"away\",\"quiet\":true}" "$(ev check normal look)" | grep -q "anna-relay\", \"send\".*look" '
ok "normal in quiet hours → held" 'route "{\"where\":\"away\",\"quiet\":true,\"why\":\"night\"}" "$(ev tell normal disk-warm)" | tail -1 | grep -qx held'
ok "a dry run writes no held file" '[ "$(ls "$T/tell/held"/*.json 2>/dev/null | wc -l)" -eq 0 ]'
ok "high in quiet hours → not held" '! route "{\"where\":\"away\",\"quiet\":true}" "$(ev tell high fan-stopped)" | grep -qx held'
ok "high, away → the bot" 'route "{\"where\":\"away\",\"quiet\":true}" "$(ev tell high fan-stopped)" | grep -q "anna-relay\", \"tell-bot\".*fan-stopped"'
ok "in the session → the brain, 📣 + [silent]" 'route "{\"where\":\"session\"}" "$(ev tell normal cat)" | grep -q "📣 \*\*Anna:\*\*.*\[silent\]"'
ok "session tell names the user" 'route "{\"where\":\"session\"}" "$(ev tell normal cat)" | grep -q "Sam is here"'
ok "talking to the bot → the bot" 'route "{\"where\":\"bot\"}" "$(ev ask normal door)" | grep -q "tell-bot"'
relay() { sed -i "/^\[relay\]/,/^\[/ s/^enabled = .*/enabled = $1/" "$ANNA_CONFIG"; }
ok "relay off → anna-notify" 'relay false; out=$(route "{\"where\":\"away\"}" "$(ev tell normal x)"); relay true; grep -q "anna-notify" <<<"$out"'
ok "bad JSON → exit 1" '! ANNA_TELL_DIR=$T/tell $A route <<<"nope" 2>/dev/null'

# held → delivered at the first message (flush), for real in a temp dir with stand-ins
mkdir -p "$T/fake"; for c in anna-relay anna-stream anna-notify; do
  printf '#!/bin/bash\necho "%s $*" >> %s/calls\n' "$c" "$T" > "$T/bin/$c"; chmod +x "$T/bin/$c"; done
mkdir -p "$T/tell/held"
printf '{"held_at":"%sT02:00:00+00:00","event":{"source":"disk","message":"ran warm overnight"}}' "$day" > "$T/tell/held/a.json"
ok "flush waits while away" 'ANNA_TELL_PRESENCE="{\"where\":\"away\"}" ANNA_TELL_DIR=$T/tell ANNA_TELL_BIN=$T/bin $A flush | grep -q "not active yet"'
ANNA_TELL_PRESENCE='{"where":"bot"}' ANNA_TELL_DIR=$T/tell ANNA_TELL_BIN=$T/bin $A flush >/dev/null
ok "flush delivers once active, as one message" 'grep -q "anna-relay tell-bot \[sense digest\] 1 thing" "$T/calls" && grep -q "disk: ran warm overnight" "$T/calls"'
ok "delivered items leave held/" '[ -z "$(ls "$T/tell/held")" ] && [ -f "$T/tell/delivered/a.json" ]'

# send: the scripts' door
: > "$T/calls"
ok "send, senses on → a drop (dry)" 'ANNA_TELL_DRY=1 $A send runs "backup failed" --kind failure | grep -q "anna-sense-send\", \"runs\", \"backup failed\", \"--do\", \"tell\", \"--importance\", \"normal\", \"--via\", \"drop\""'
sed -i "/^\[senses\]/,\$ s/^enabled = true/enabled = false/" "$ANNA_CONFIG"
ok "send, senses off → anna-notify (nothing goes silent)" 'ANNA_TELL_BIN=$T/bin $A send runs "backup failed" && grep -q "anna-notify backup failed" "$T/calls"'
ok "send, low → stream only" 'ANNA_TELL_BIN=$T/bin $A send runs "all fine" --importance low && grep -q "anna-stream add --from runs all fine" "$T/calls"'

# the told-in-session reminder (hook-prompt)
mkdir -p "$T/tell/told"; printf '{"id":"r9","at":%s,"state":"told","text":"cat in the garage"}' "$(date +%s)" > "$T/tell/told/r9.json"
ok "reminder on their next prompt" 'echo "{\"prompt\":\"what next?\"}" | ANNA_TELL_DIR=$T/tell $A hook-prompt | jq -r .hookSpecificOutput.additionalContext | grep -q "Reminder"'
ok "only once" '[ -z "$(echo "{\"prompt\":\"and now?\"}" | ANNA_TELL_DIR=$T/tell $A hook-prompt)" ]'
printf '{"id":"r8","at":%s,"state":"told","text":"x"}' "$(date +%s)" > "$T/tell/told/r8.json"
ok "a relay typed into the session isn't their prompt" '[ -z "$(echo "{\"prompt\":\"[relay r7 from the bot] hi\"}" | ANNA_TELL_DIR=$T/tell $A hook-prompt)" ]'
ok "hooks stay quiet in the bot" '[ -z "$(echo "{\"prompt\":\"hi\"}" | ANNA_ROLE=bot ANNA_TELL_DIR=$T/tell $A hook-prompt)" ]'

# the `tell` check: no script messages the user directly
printf '#!/bin/bash\n# anna-notify in a comment\nanna-notify "direct"\n' > "$T/bin/mine"; chmod +x "$T/bin/mine"
ok "check flags a direct anna-notify call (line 3 only)" 'bin/anna-checks tell | grep -q "⚠ tell: mine calls anna-notify directly (line 3)"'
ok "check skips the door itself" '! bin/anna-checks tell | grep -qE "⚠ tell: anna-(notify|tell|checks) "'
rm "$T/bin/mine"; for c in anna-relay anna-stream; do rm "$T/bin/$c"; done
ok "check OK when clean" 'bin/anna-checks tell | grep -q "^OK tell"'
sed -i "/^\[senses\]/,\$ s/^enabled = false/enabled = true/" "$ANNA_CONFIG"; mkdir -p "$T/state/senses/inbox"
touch -d "-10 min" "$T/state/senses/inbox/x.1.json"
ok "check flags a stuck drop" 'bin/anna-checks tell | grep -q "⚠ tell: 1 event file"'
ok "repo scripts don't call anna-notify directly" '! grep -lE "(^|[^-[:alnum:]_])anna-notify([^-[:alnum:]_]|$)" bin/* hooks/anna-* 2>/dev/null | grep -vE "/(anna-notify|anna-tell|anna-checks)$" | xargs -r grep -nE "(^|[^-[:alnum:]_])anna-notify([^-[:alnum:]_]|$)" | grep -vE ":[0-9]+:[[:space:]]*#" | grep -q .'
exit $fail
