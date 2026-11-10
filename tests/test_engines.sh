#!/bin/bash
# tests/test_engines.sh — engines that run themselves (anna-engine, the stream hook's interpretation/curiosity/correction
# parts, anna-epistemic-hook) and the own journal (anna-log), against a throwaway HOME, config and a stand-in `claude`.
# Run from the repo root: tests/test_engines.sh
set -u
cd "$(dirname "$0")/.."
R=$PWD; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME=$T/home ANNA_CONFIG=$T/anna.toml; mkdir -p "$HOME/.claude/agents" "$T/rec/journal/handoffs" "$T/rec/memory"
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\nrecord = "%s/rec"\n' "$T" "$T" > "$ANNA_CONFIG"
for e in interpretation epistemic; do printf -- '---\nname: anna-%s\n---\n' "$e" > "$HOME/.claude/agents/anna-$e.md"; done
# stand-in claude: answers with the agent's block; FAKE_MODE=slow sleeps past the timeout, =junk prints no block
cat > "$T/claude" <<'EOF'
#!/bin/bash
a=""; while [ $# -gt 0 ]; do [ "$1" = --agent ] && a=$2; shift; done; cat > /dev/null
case ${FAKE_MODE:-ok} in slow) sleep 5 ;; junk) echo "no block here"; exit 0 ;; esac
case $a in
  anna-interpretation) printf '```anna-interpretation\nmode: greeting\ngreet_only: yes\n```\n' ;;
  anna-epistemic) printf '```anna-epistemic\nverdict: check-first\ncheck: run the thing\n```\n' ;;
esac
EOF
chmod +x "$T/claude"; export ANNA_ENGINE_CLAUDE=$T/claude
unset ANNA_ROLE ANNA_HEADLESS; export CLAUDE_CODE_ENTRYPOINT=cli
E=bin/anna-engine; S=bin/anna-stream; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
stream() { cat "$T"/state/stream/*.jsonl 2>/dev/null; }

# anna-engine
out=$(echo "input" | $E interpretation --trigger test)
ok "engine: prints the agent's block" 'echo "$out" | grep -q "^\`\`\`anna-interpretation" && echo "$out" | grep -q "greet_only: yes"'
ok "engine: logs the run to the stream" 'stream | grep -q "interpretation ran (test"'
out=$(echo x | FAKE_MODE=junk $E interpretation --trigger hook); rc=$?
ok "engine: no block → fails open, exit 3" '[ $rc -eq 3 ] && echo "$out" | grep -q "engine unavailable"'
out=$(echo x | FAKE_MODE=slow ANNA_ENGINE_TIMEOUT=1 $E interpretation --trigger hook); rc=$?
ok "engine: timeout → fails open, exit 3, logged" '[ $rc -eq 3 ] && stream | grep -q "interpretation failed (hook): timed out"'
ok "engine: unknown engine → exit 2" '! echo x | $E nosuch 2>/dev/null'
ok "engine: --stats counts runs and failures, not test runs" "$E --stats \$(date -u +%F) | grep -q 'interpretation 0 ran, 0 missed, 2 failed'"

# anna-log
ok "anna-log: writes today's own journal" 'bin/anna-log learned "a small lesson" >/dev/null && grep -q "\[learned\] (brain) a small lesson" "$T"/rec/self/journal/*/*/*.md'
ok "anna-log: refuses an unknown kind" '! bin/anna-log diary "x" 2>/dev/null'

# stream hook: interpretation on the first prompt of a session, a correction logged raw
up() { jq -nc --arg p "$1" --arg s "$2" '{hook_event_name:"UserPromptSubmit",session_id:$s,prompt:$p}' | $S hook; }
out=$(up "good morning" sess-1111aaaa)
ok "hook: first prompt runs interpretation, block on top" 'echo "$out" | grep -q "Interpretation (run by the prompt hook" && echo "$out" | grep -q "greet_only: yes"'
out=$(up "and another thing" sess-1111aaaa)
ok "hook: second prompt, no interpretation" '! echo "$out" | grep -q "Interpretation (run by"'
up "no, I meant the other one" sess-1111aaaa >/dev/null
ok "hook: a correction goes to the own journal" 'grep -q "\[correction\] (hook) Sam: no, I meant the other one" "$T"/rec/self/journal/*/*/*.md'
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\nrecord = "%s/rec"\n[engines]\ninterpretation = false\n' "$T" "$T" > "$ANNA_CONFIG"
out=$(up "hello" sess-2222bbbb)
ok "hook: engines.interpretation = false → no engine" '! echo "$out" | grep -q "Interpretation (run by"'

# curiosity: today's question rides along until asked, then logged
printf 'x\nQuestion for today: Why did you pick walnut shelving for the office? (why: taste)\n' > "$T/rec/journal/handoffs/$(date -u +%F)-morning.md"
out=$(up "what next" sess-2222bbbb)
ok "hook: today's question carried" 'echo "$out" | grep -q "Today.s question (curiosity, not asked yet): Why did you pick walnut"'
jq -nc '{hook_event_name:"Stop",session_id:"sess-2222bbbb",last_assistant_message:"Done. Why did you pick walnut shelving for the office?"}' | $S hook
ok "hook: asking it is logged from curiosity" 'stream | grep -q "\"from\": \"curiosity\""'
out=$(up "ok" sess-2222bbbb)
ok "hook: not carried once asked" '! echo "$out" | grep -q "not asked yet"'

# proposals: after today's question, one nightly proposal rides along until a reply raises it
printf '## Proposed for a reviewed session\n- **memory/walnut.md:** new lesson, walnut over oak for shelving.\n' > "$T/rec/journal/handoffs/2026-01-01-dream.md"
bin/anna-proposals ingest "$T/rec/journal/handoffs/2026-01-01-dream.md" >/dev/null
out=$(up "anything else" sess-2222bbbb)
ok "hook: a proposal is carried once the question is asked" 'echo "$out" | grep -q "A proposal from the nightly runs, not raised yet (p-"'
jq -nc '{hook_event_name:"Stop",session_id:"sess-2222bbbb",last_assistant_message:"Last night I suggested a new lesson: walnut over oak for shelving. Want it in memory?"}' | $S hook
ok "hook: raising it marks it raised" 'bin/anna-proposals list | grep -q "· raised"'
out=$(up "ok" sess-2222bbbb)
ok "hook: not carried once raised (one a day)" '! echo "$out" | grep -q "not raised yet"'

# epistemic hook: Stop logs a due check; the relay check is off by default
H=hooks/anna-epistemic-hook
jq -nc '{hook_event_name:"Stop",last_assistant_message:"The backup is not running because the disk is full."}' | $H
ok "epistemic: a cause/negative not checked → logged as due" 'stream | grep -q "epistemic due, not run"'
rel='{"hook_event_name":"PreToolUse","tool_name":"mcp__plugin_fakechat_fakechat__reply","tool_input":{"text":"It is down because of X.","reply_to":"r1"}}'
ok "epistemic: relay check off by default → passes" '[ -z "$(echo "$rel" | $H)" ]'
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\nrecord = "%s/rec"\n[engines]\nepistemic_relay = true\n' "$T" "$T" > "$ANNA_CONFIG"
ok "epistemic: relay check on → blocks a check-first" 'echo "$rel" | $H | grep -q "permissionDecision\": \"deny"'
ok "epistemic: never blocks the same item twice" '[ -z "$(echo "$rel" | $H)" ]'
ok "epistemic: the bot passes through" '[ -z "$(echo "$rel" | ANNA_ROLE=bot $H)" ]'
# a note without reply_to is keyed to its turn: a reworded note in the same turn isn't blocked again (no loop)
printf '%s\n' '{"type":"user","uuid":"turn-1","message":{"role":"user","content":"close the old items"}}' > "$T/turn.jsonl"
note() { jq -nc --arg t "$1" --arg p "$T/turn.jsonl" '{hook_event_name:"PreToolUse",session_id:"s-1",transcript_path:$p,tool_name:"mcp__plugin_fakechat_fakechat__reply",tool_input:{text:$t}}' | $H; }
ok "epistemic: a note without reply_to is checked once" 'note "It was never restarted because the disk is full." | grep -q "permissionDecision\": \"deny"'
ok "epistemic: rewording it in the same turn passes (no loop)" '[ -z "$(note "It is not running because the disk filled up.")" ]'
printf '%s\n' '{"type":"user","uuid":"turn-2","message":{"role":"user","content":"next thing"}}' >> "$T/turn.jsonl"
ok "epistemic: a note in a new turn is checked again" 'note "Nothing is broken because the disk is fine." | grep -q "permissionDecision\": \"deny"'
exit $fail
