#!/bin/bash
# tests/test_run.sh — anna-run with a stub `claude` (prints a canned report) and anna-notify's refusals, in a throwaway
# record, state and secret dir. No real session, no token, no network.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/stub" "$T/record" "$T/s" "$T/home/.claude"; R=$PWD
export HOME=$T/home ANNA_CONFIG=$T/anna.toml PATH="$T/stub:$R/bin:/usr/bin:/bin"
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\nbin = "%s/stub"\nsecrets = "%s/s"\n' "$T" "$T" "$T" "$T" > "$ANNA_CONFIG"
git -C "$T/record" init -q; export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git -C "$T/record" commit -q --allow-empty -m init
# stub claude: echoes its args, then a report with a ⛔ under Needs action
cat > "$T/stub/claude" <<'EOF'
#!/bin/bash
echo "args: $*"; printf '## Needs action today\n⛔ the backup is 3 days old\n## Watch\nok\n'
EOF
# stub notifier: records what it was asked to send
printf '#!/bin/bash\necho "$ANNA_NOTIFY_FROM|$*" >> "%s/sent"\n' "$T" > "$T/stub/anna-notify"; chmod +x "$T/stub/"*
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

out=$(bin/anna-run "/anna-morning" morning); rc=$?
F=$(ls "$T"/record/journal/handoffs/*-morning.md 2>/dev/null | head -1)
ok "anna-run exits 0 and writes the report" '[ $rc -eq 0 ] && [ -n "$F" ]'
ok "it runs claude -p with the headless settings" 'grep -q "args: -p /anna-morning .*--settings .*anna-headless-settings.json" "$F"'
ok "the report is committed in the record" 'git -C "$T/record" log --oneline | grep -q "morning .* (headless, exit 0)"'
ok "a ⛔ in a morning run notifies the user" 'grep -q "^anna-run morning|⛔ morning .* needs you:" "$T/sent" && grep -q "backup is 3 days old" "$T/sent"'
bin/anna-run "do a thing" chores >/dev/null
ok "a ⛔ in other runs doesn't notify" '[ "$(grep -c "needs you" "$T/sent")" -eq 1 ]'
# a clean report that mentions ⛔ in prose must not notify
printf '#!/bin/bash\nprintf "## Needs action today\\nNone. Nothing is ⛔.\\n## Watch\\nok\\n"\n' > "$T/stub/claude"
bin/anna-run "/anna-morning" morning >/dev/null
ok "a ⛔ in prose (Nothing is ⛔) doesn't notify" '[ "$(grep -c "needs you" "$T/sent")" -eq 1 ]'
ok "the run is in the stream" 'grep -q "headless morning" "$T"/state/stream/*.jsonl'

# a dream (or evening) run's Proposed items land in self/proposals.md, in their own commit
printf '#!/bin/bash\nprintf "## Dreamt\\nA night.\\n## Proposed for a reviewed session\\n- **memory/x.md:** a new lesson.\\n## Could not\\nnone\\n"\n' > "$T/stub/claude"
bin/anna-run "/anna-dream" dream >/dev/null
ok "a dream run's proposal lands in self/proposals.md" 'grep -q "^## p-[0-9a-f]* · open" "$T/record/self/proposals.md" && grep -q "a new lesson" "$T/record/self/proposals.md"'
ok "proposals.md is committed on its own" 'git -C "$T/record" log --oneline -1 | grep -q "proposals from dream" && [ -z "$(git -C "$T/record" status --porcelain -- self/proposals.md)" ]'
bin/anna-run "/anna-dream" dream >/dev/null
ok "the same proposal again: no new item, no new commit" '[ "$(grep -c "^## p-" "$T/record/self/proposals.md")" = 1 ] && [ "$(git -C "$T/record" log --oneline | grep -c "proposals from")" = 1 ]'
bin/anna-run "do a thing" chores >/dev/null
ok "other runs don't ingest" '[ "$(git -C "$T/record" log --oneline | grep -c "proposals from")" = 1 ]'

# anna-notify (the real one), bot off (the default): the stream only, no token needed, exit 0
ok "anna-notify: bot off → stream only, exit 0" 'bin/anna-notify "disk is full" 2>/dev/null && grep -q "(no bot)" "$T"/state/stream/*.jsonl'
# bot on: refuses without a token, then without a chat id, before any network
printf '[bot]\nenabled = true\n' >> "$ANNA_CONFIG"
ok "anna-notify: no token → refused" '! bin/anna-notify hi 2>/dev/null'
echo "123:fake" > "$T/s/telegram-ops"
err=$(bin/anna-notify hi 2>&1); rc=$?
ok "anna-notify: no chat id → exit 2, says --learn" '[ $rc -eq 2 ] && echo "$err" | grep -q -- "--learn"'

# anna-run commits only its own report: something else staged in the record stays staged (2026-11-03: a bare commit
# pushed files a gate had held)
echo held > "$T/record/held.md"; git -C "$T/record" add held.md
bin/anna-run "/anna-evening" evening >/dev/null
ok "anna-run doesn't commit other staged files" '! git -C "$T/record" log -1 --name-only --format= | grep -q held.md'
ok "and they stay staged" 'git -C "$T/record" diff --cached --name-only | grep -qx held.md'

# anna-tg fills its prompt with bash, so | and & in names stay literal
printf '[anna]\nname = "A|n&a"\nuser = "S&m|x"\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\nbin = "%s/stub"\nsecrets = "%s/s"\n' "$T" "$T" "$T" "$T" > "$ANNA_CONFIG"
p=$(bin/anna-tg ops --print-prompt 2>&1)
ok "anna-tg: | and & in names stay literal" 'grep -qF "You are A|n&a on Telegram. Only S&m|x can reach you" <<<"$p"'
exit $fail
