#!/bin/bash
# tests/test_hooks.sh — session-start, session-draft and idle-checkpoint against a synthetic transcript. Throwaway HOME,
# config and state, so nothing touches the real ~/.claude.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
R=$PWD; export HOME=$T/home ANNA_CONFIG=$T/anna.toml PATH="$R/bin:/usr/bin:/bin"
mkdir -p "$HOME/.claude/projects/-home-x" "$T/record/journal/handoffs"
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\n[day]\nopen = "00:00"\n' "$T" "$T" > "$ANNA_CONFIG"
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
now=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
TR=$HOME/.claude/projects/-home-x/11111111-2222-3333-4444-555555555555.jsonl
{
  printf '{"type":"user","timestamp":"%s","cwd":"/home/x","message":{"role":"user","content":"check the disk please"}}\n' "$now"
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"text","text":"Checking."},{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"df -h /","description":"disk"}}]}}\n' "$now"
  printf '{"type":"user","timestamp":"%s","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"/dev/sda1 50G 21G 29G 42%% /"}]}}\n' "$now"
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"bw get password x"}}]}}\n' "$now"
  printf '{"type":"user","timestamp":"%s","message":{"content":[{"type":"tool_result","tool_use_id":"t2","content":"hunter2-secret"}]}}\n' "$now"
  printf '{"type":"assistant","timestamp":"%s","message":{"content":[{"type":"text","text":"42%% used. Token ghp_abcdefghijklmnopqrstuvwxyz0123456789AB"}]}}\n' "$now"
} > "$TR"

# session draft
printf '{"transcript_path":"%s"}' "$TR" | hooks/anna-session-draft 2>/dev/null
D=$T/state/drafts/11111111-2222-3333-4444-555555555555.md
ok "a draft is written" '[ -f "$D" ]'
ok "it names the user" 'grep -q "### .* Sam" "$D"'
ok "it keeps the command and its output" 'grep -q "df -h /" "$D" && grep -q "42% /" "$D"'
ok "vault output is never drafted" '! grep -q hunter2 "$D" && grep -q "vault command: output not drafted" "$D"'
ok "secrets are redacted" '! grep -q ghp_ "$D"'
hooks/anna-session-draft --mark-folded "$D"
ok "--mark-folded moves it and records the line mark" '[ ! -f "$D" ] && grep -q "11111111-2222-3333-4444-555555555555\": 6" "$T/state/folded.json"'
printf '{"transcript_path":"%s"}' "$TR" | hooks/anna-session-draft 2>/dev/null
ok "nothing new after the mark: no new draft" '[ ! -f "$D" ]'

# session start
echo "# headless run 2026-01-01T04:00 exit 0" > "$T/record/journal/handoffs/2026-01-01-morning.md"
printf '## Needs action today\n⛔ the backup failed\n## Watch\nnothing\n' >> "$T/record/journal/handoffs/2026-01-01-morning.md"
out=$(echo '{"session_id":"other"}' | hooks/anna-session-start)
ok "session-start reports the last activity" 'echo "$out" | grep -q "Last interactive session activity"'
ok "and the latest report's Needs action" 'echo "$out" | grep -q "the backup failed" && ! echo "$out" | grep -q "^nothing"'
ok "headless runs get nothing" '[ -z "$(echo "{}" | ANNA_HEADLESS=1 hooks/anna-session-start)" ]'

# idle checkpoint: a quiet transcript with an unjournaled prompt wakes the session (exit 2) with the checkpoint message
rm -f "$T/state/folded.json"
err=$(printf '{"session_id":"sid-1","transcript_path":"%s"}' "$TR" | ANNA_IDLE_WAIT=1 hooks/anna-idle-checkpoint 2>&1 >/dev/null); rc=$?
ok "idle with unjournaled prompts → wake (exit 2)" '[ $rc -eq 2 ] && echo "$err" | grep -q "/anna-checkpoint" && echo "$err" | grep -q "Sam"'
printf '{"sid-1": 6}' > "$T/state/folded.json"
printf '{"session_id":"sid-1","transcript_path":"%s"}' "$TR" | ANNA_IDLE_WAIT=1 hooks/anna-idle-checkpoint 2>/dev/null; rc=$?
ok "everything journaled → stay quiet (exit 0)" '[ $rc -eq 0 ]'
printf '{"session_id":"sid-1","transcript_path":"%s"}' "$TR" | ANNA_ROLE=bot ANNA_IDLE_WAIT=1 hooks/anna-idle-checkpoint; rc=$?
ok "the bot never checkpoints" '[ $rc -eq 0 ]'

# idle checkpoint: a prompt typed while Anna was mid-turn (an attachment, not a user entry) counts as unjournaled
TM=$HOME/.claude/projects/-home-x/mid.jsonl
printf '{"type":"attachment","timestamp":"%s","attachment":{"type":"queued_command","prompt":"also check the backup","origin":{"kind":"human"}}}\n' "$now" > "$TM"
printf '{"session_id":"sid-mid","transcript_path":"%s"}' "$TM" | ANNA_IDLE_WAIT=1 hooks/anna-idle-checkpoint 2>/dev/null; rc=$?
ok "a mid-turn prompt counts → wake (exit 2)" '[ $rc -eq 2 ]'

# idle checkpoint night window: from midnight, or from day.close when that's before midnight, to day.open + 15 min
night() {  # night CLOSE OPEN MINUTE → True/False
  printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\n[day]\nclose = "%s"\nopen = "%s"\n' "$T" "$1" "$2" > "$T/n.toml"
  ANNA_CONFIG=$T/n.toml python3 -c "import importlib.machinery as m, sys; sys.argv=['x']; h=m.SourceFileLoader('h','hooks/anna-idle-checkpoint').load_module(); print(h.in_night($3))"
}
ok "night 00:30→04:15: 00:10 and 04:29 night, 04:30 and 23:30 not" '[ "$(night 00:30 04:15 10)" = True ] && [ "$(night 00:30 04:15 269)" = True ] && [ "$(night 00:30 04:15 270)" = False ] && [ "$(night 00:30 04:15 1410)" = False ]'
ok "night 23:00→04:15: 23:30 night, 22:59 not" '[ "$(night 23:00 04:15 1410)" = True ] && [ "$(night 23:00 04:15 1379)" = False ]'

# session-draft skips the bot's sessions (anna-tg runs in ~/anna-<instance>)
mkdir -p "$HOME/.claude/projects/-bot"; TB=$HOME/.claude/projects/-bot/22222222-2222-3333-4444-555555555555.jsonl
sed "s|\"cwd\":\"/home/x\"|\"cwd\":\"$HOME/anna-ops\"|" "$TR" > "$TB"
printf '{"transcript_path":"%s"}' "$TB" | hooks/anna-session-draft 2>/dev/null
ok "the bot's sessions aren't drafted" '[ ! -f "$T/state/drafts/22222222-2222-3333-4444-555555555555.md" ]'
# …but a brain session in the record is drafted, though the default record path ~/anna-record looks like ~/anna-<instance>
TR2=$HOME/.claude/projects/-bot/33333333-2222-3333-4444-555555555555.jsonl
sed "s|\"cwd\":\"/home/x\"|\"cwd\":\"$HOME/anna-record\"|" "$TR" > "$TR2"
sed "s|^record = .*|record = \"$HOME/anna-record\"|" "$ANNA_CONFIG" > "$T/rec.toml"
printf '{"transcript_path":"%s"}' "$TR2" | ANNA_CONFIG=$T/rec.toml hooks/anna-session-draft 2>/dev/null
ok "a session in ~/anna-record (the record) is drafted" '[ -f "$T/state/drafts/33333333-2222-3333-4444-555555555555.md" ]'
rm -f "$TR2"
rm -f "$TB" "$TM"

# session-start: the gap comes from the last timestamp, not the file's mtime (idle transcripts keep getting metadata)
old=$(date -u -d '-10 hours' +%Y-%m-%dT%H:%M:%S.000Z)
sed "s/$now/$old/g" "$TR" > "$TR.x" && mv "$TR.x" "$TR"; echo '{"type":"summary","leafUuid":"x"}' >> "$TR"   # mtime: now
out=$(echo '{"session_id":"other"}' | hooks/anna-session-start)
ok "session-start: gap from the last timestamp (10 h), not the mtime" 'echo "$out" | grep -qE "activity: (9\.9|10\.[0-9]) h ago"'
exit $fail
