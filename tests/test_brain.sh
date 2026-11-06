#!/bin/bash
# tests/test_brain.sh — anna-brain's launch flags with a stub claude: a config change (relay on) takes effect at the next
# resume, without closing the window; anna-day's stop marker ends the loop. No tty (setsid), so the 10 s prompt is skipped.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME=$T/home ANNA_CONFIG=$T/anna.toml LOG=$T/claude.log
mkdir -p "$HOME" "$T/stub"
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\n[relay]\nenabled = false\nbrain_port = %s\n' \
  "$T" "$((40000 + $$ % 20000))" > "$ANNA_CONFIG"
# stub claude: logs its args; 1st launch turns the relay on and exits (like a /exit), 2nd touches the stop marker
cat > "$T/stub/claude" <<'S'
#!/bin/bash
echo "$*" >> "$LOG"
n=$(wc -l < "$LOG")
if [ "$n" -eq 1 ]; then sed -i 's/^enabled = false/enabled = true/' "$ANNA_CONFIG"; else touch "$STOPF"; fi
S
chmod +x "$T/stub/claude"; export PATH=$T/stub:$PATH STOPF=$T/state/brain-stop
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

cd "$T" && timeout 60 setsid -w "$OLDPWD/bin/anna-brain" anna-test >/dev/null 2>&1; rc=$?; cd "$OLDPWD"
ok "the stop marker ends the loop (exit 0)" '[ $rc -eq 0 ]'
ok "claude was launched twice" '[ "$(wc -l < "$LOG")" -eq 2 ]'
ok "first launch: relay off, no fakechat channel" '! sed -n 1p "$LOG" | grep -q -- --channels'
ok "after the change, the resume loads the fakechat channel" 'sed -n 2p "$LOG" | grep -q -- "--channels plugin:fakechat@claude-plugins-official"'
ok "and still resumes the same session" 'sid=$(sed -n 1p "$LOG" | grep -o -- "--session-id [0-9a-f-]*" | cut -d" " -f2); [ -n "$sid" ] && sed -n 2p "$LOG" | grep -q -- "--session-id $sid\|--resume $sid"'
exit $fail
