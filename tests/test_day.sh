#!/bin/bash
# tests/test_day.sh — what anna-day does without a live brain session (the full rollover needs claude + screen: see
# docs/ for the manual check). Throwaway config and state; a screen name nobody uses.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml PATH="$PWD/bin:/usr/bin:/bin"
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\nbin = "%s/bin"\n[day]\nscreen = "anna-test-%s"\n' "$T" "$T" "$$" > "$ANNA_CONFIG"
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

out=$(bin/anna-day close); rc=$?
ok "close with no brain session exits 0" '[ $rc -eq 0 ]'
ok "and says so in the stream" 'grep -q "close: no brain session open in screen anna-test-" "$T"/state/stream/*.jsonl'
ok "no relay pause left behind" '[ ! -e "$T/state/relay/paused" ]'
ok "usage on a bad verb" '! bin/anna-day sideways >/dev/null'

# a brain session started in a folder with . and _ : Claude Code names its transcript folder with every non-alphanumeric
# as -, so close must find the transcript there (it used to see "never used" and /exit without the wrap-up)
export HOME=$T/home; mkdir -p "$HOME/.claude/sessions"
cwd=/home/first.last/my_record; dir=$HOME/.claude/projects/-home-first-last-my-record; mkdir -p "$dir"
sid=11111111-2222-3333-4444-555555555555
echo '{"type":"user","timestamp":"2026-01-01T00:00:00Z"}' > "$dir/$sid.jsonl"
env STY="1.anna-test-$$" WINDOW=0 sleep 60 & fake=$!
printf '{"kind":"interactive","pid":%s,"sessionId":"%s","cwd":"%s"}\n' "$fake" "$sid" "$cwd" > "$HOME/.claude/sessions/x.json"
printf 'idle_min = 99999999\n' >> "$ANNA_CONFIG"     # found and "active": left open, no keystrokes needed
bin/anna-day close >/dev/null; kill $fake 2>/dev/null
ok "close finds a transcript under a . and _ folder name" 'grep -q "close: session 11111111 active .* left open" "$T"/state/stream/*.jsonl'
ok "and doesn't take it for a never-used session" '! grep -q "11111111 was never used" "$T"/state/stream/*.jsonl'
exit $fail
