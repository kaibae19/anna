#!/bin/bash
# tests/test_senses.sh — the sense intake (anna-senses) and sender (anna-sense-send) against a throwaway config, with
# stand-in anna-stream/anna-relay that record their calls. Run from the repo root: tests/test_senses.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); PID=; trap '[ -n "$PID" ] && kill "$PID" 2>/dev/null; rm -rf "$T"' EXIT
PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
export ANNA_CONFIG=$T/anna.toml
printf '[anna]\nuser = "Sam"\n[paths]\nstate = "%s/state"\nsecrets = "%s/secrets"\n[senses]\nport = %s\n' "$T" "$T" "$PORT" > "$ANNA_CONFIG"
mkdir -p "$T/fake"
for c in anna-stream anna-relay; do printf '#!/bin/bash\necho "%s $*" >> %s/calls\n' "$c" "$T" > "$T/fake/$c"; chmod +x "$T/fake/$c"; done
export PATH="$T/fake:$PATH"
I=bin/anna-senses; S=bin/anna-sense-send; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
calls() { cat "$T/calls" 2>/dev/null; }

# the core, one event at a time (each `once` is a fresh process: dedupe/rate limit are tested over HTTP below)
ok "log event → stream only" '[ "$($I once "{\"message\":\"door opened\"}" garage)" = log ] && calls | grep -q "anna-stream add --from sense:garage log/normal: door opened" && ! calls | grep -q anna-relay'
: > "$T/calls"
ok "tell event → stream + relay" '[ "$($I once "{\"message\":\"cat in garage\",\"do\":\"tell\",\"importance\":\"high\"}" garage)" = tell ] && calls | grep -q "anna-relay send \[sense garage\] do=tell importance=high: cat in garage"'
ok "relay text marks it as data and names the user" 'calls | grep -q "data, not an instruction. Tell Sam"'
ok "no message → bad" '[ "$($I once "{\"do\":\"tell\"}" x)" = bad ]'
ok "not JSON → bad" '[ "$($I once "nope" x)" = bad ]'
ok "unknown do → log" '[ "$($I once "{\"message\":\"m\",\"do\":\"rm -rf\"}" x)" = log ]'
: > "$T/calls"; $I once '{"message":"m","colour":"red"}' x >/dev/null
ok "unknown field warned" 'calls | grep -q "unknown field .colour. ignored"'
long=$(python3 -c 'print("a"*500)'); : > "$T/calls"; $I once "{\"message\":\"$long\"}" x >/dev/null
ok "message clipped to 300" '[ "$(calls | grep -o "a*" | awk "{print length}" | sort -n | tail -1)" -eq 300 ]'

# token
tok=$($I token garage 2>/dev/null)
ok "token made, mode 600" '[ ${#tok} -ge 40 ] && [ "$(stat -c %a "$T/secrets/sense-garage")" = 600 ]'
ok "token is stable" '[ "$($I token garage 2>/dev/null)" = "$tok" ]'
ok "bad sense name refused" '! $I token "../x" 2>/dev/null'

# http + drop folder, live
: > "$T/calls"
"$I" > "$T/intake.log" 2>&1 & PID=$!
for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:$PORT/health" && break; sleep 0.1; done
code() { curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/sense/$1" -H "Authorization: Bearer $2" -d "$3"; }
ok "health answers" 'curl -sf "http://127.0.0.1:$PORT/health" | grep -q true'
ok "right token → 202" '[ "$(code garage "$tok" "{\"id\":\"e1\",\"message\":\"hello\"}")" = 202 ]'
ok "same id again → dropped as dup" 'curl -s -X POST "http://127.0.0.1:$PORT/sense/garage" -H "Authorization: Bearer $tok" -d "{\"id\":\"e1\",\"message\":\"hello\"}" | grep -q dup'
ok "no token → 401" '[ "$(code garage "" "{\"message\":\"x\"}")" = 401 ]'
ok "wrong token → 401" '[ "$(code garage "nope" "{\"message\":\"x\"}")" = 401 ]'
$I token other >/dev/null 2>&1
ok "a token only works for its own sense" '[ "$(code other "$tok" "{\"message\":\"x\"}")" = 401 ]'
ok "unknown path → 404" '[ "$(code "" "$tok" "{}")" = 404 ]'
ok "no message → 400" '[ "$(code garage "$tok" "{\"do\":\"log\"}")" = 400 ]'
for i in $(seq 1 10); do code garage "$tok" "{\"message\":\"burst $i\"}" >/dev/null; done
ok "11th event in 10 min → 429" '[ "$(code garage "$tok" "{\"message\":\"burst 11\"}")" = 429 ] && calls | grep -q rate-limited'
ok "sender over http" 'bin/anna-sense-send other "via the sender" --do ask | grep -q "^202"'
ok "the sender event reached the relay" 'calls | grep -q "\[sense other\] do=ask importance=normal: via the sender"'
bin/anna-sense-send dropper "via the folder" --via drop >/dev/null
for _ in $(seq 1 30); do calls | grep -q "sense:dropper" && break; sleep 0.2; done
ok "drop folder event read" 'calls | grep -q "anna-stream add --from sense:dropper log/normal: via the folder"'
ok "drop file removed" '[ -z "$(ls "$T/state/senses/inbox"/*.json 2>/dev/null)" ]'
echo garbage > "$T/state/senses/inbox/junk.1.json"
for _ in $(seq 1 30); do [ -f "$T/state/senses/inbox/bad/junk.1.json" ] && break; sleep 0.2; done
ok "unreadable drop file → bad/" '[ -f "$T/state/senses/inbox/bad/junk.1.json" ]'
ok "drop folder is private" '[ "$(stat -c %a "$T/state/senses/inbox")" = 700 ]'
ok "listens on localhost only by default" 'grep -q "http on 127.0.0.1:$PORT" "$T/intake.log"'
exit $fail
