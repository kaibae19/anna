#!/bin/bash
# tests/test_stream.sh — anna-stream against a throwaway config + state dir. Run from the repo root: tests/test_stream.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml
unset ANNA_ROLE ANNA_HEADLESS; export CLAUDE_CODE_ENTRYPOINT=cli   # as in an interactive session, even when the suite runs under claude -p
printf '[anna]\nuser = "Sam"\ntimezone = "Europe/Berlin"\n[paths]\nstate = "%s/state"\n' "$T" > "$ANNA_CONFIG"
S=bin/anna-stream; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

$S add --from clock "reminder fired" ; $S add --for brain "please look at the backup"
f=$(ls "$T"/state/stream/*.jsonl 2>/dev/null | head -1)
ok "add writes a jsonl line per call" '[ "$(wc -l < "$f")" -eq 2 ]'
ok "--for brain is recorded" 'grep -q "\"for\": \"brain\"" "$f"'
ok "recent shows both" '[ "$($S recent | wc -l)" -eq 2 ]'
ok "recent --from filters by source" '[ "$($S recent --from clock | wc -l)" -eq 1 ] && $S recent --from clock | grep -q "reminder fired"'
ok "recent tags the hand-off" '$S recent | grep -q "for the brain"'
$S add "token ghp_abcdefghijklmnopqrstuvwxyz0123456789AB end"
ok "secrets are redacted" '! grep -q ghp_ "$f" && grep -q "\[REDACTED\]" "$f"'
ok "--for only takes brain" '! $S add --for bot x 2>/dev/null'

# hook, interactive session: logs the prompt as the user's words, returns the others' lines as context
out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"sess-aaaa1111","prompt":"hello there"}' | $S hook)
ok "session prompt logged as 'Sam: '" 'grep -q "\"Sam: hello there\"" "$f"'
ok "hook context lists the other lines" 'echo "$out" | grep -q "reminder fired"'
ok "context names the timezone" 'echo "$out" | grep -q "Europe/Berlin"'
out2=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"sess-aaaa1111","prompt":"again"}' | $S hook)
ok "second turn: only lines since the last turn" '! echo "$out2" | grep -q "reminder fired"'

# hook, bot: only Telegram channel blocks are the user's words; relay (fakechat) blocks are not
p='<channel source="plugin:telegram:telegram" chat_id="1">turn on the lamp</channel> <channel source="plugin:fakechat:fakechat" message_id="r1">[relay result for r1] done</channel>'
jq -n --arg p "$p" '{hook_event_name:"UserPromptSubmit",session_id:"bot-bbbb2222",prompt:$p}' | ANNA_ROLE=bot $S hook >/dev/null
ok "bot logs the Telegram text" 'grep -q "Sam: turn on the lamp" "$f"'
ok "bot does not log relay text as the user" '! grep -q "Sam: \[relay" "$f"'

# a `claude -p` (entrypoint sdk-cli) is headless even without ANNA_HEADLESS: its prompt is not the user's words
printf '{"hook_event_name":"UserPromptSubmit","session_id":"sdk-cccc3333","prompt":"say ok"}' | CLAUDE_CODE_ENTRYPOINT=sdk-cli $S hook >/dev/null
ok "claude -p prompts are not logged as the user" '! grep -q "Sam: say ok" "$T"/state/stream/*.jsonl'

# hook never fails
ok "bad hook input exits 0" 'echo "not json" | $S hook >/dev/null; [ $? -eq 0 ]'
exit $fail
