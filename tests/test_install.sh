#!/bin/bash
# tests/test_install.sh — install.sh into a throwaway HOME (no systemd), twice, to check it's idempotent and keeps
# existing settings, hooks and files.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME=$T/home ANNA_CONFIG=$T/home/.config/anna/anna.toml
mkdir -p "$HOME/.claude" "$HOME/.config/anna"
# a pre-existing user settings file with one unrelated hook and a setting that must survive
echo '{"theme":"dark","hooks":{"Stop":[{"hooks":[{"type":"command","command":"/usr/local/bin/other-hook"}]}]}}' > "$HOME/.claude/settings.json"
printf '[anna]\nname = "Nova"\nuser = "Sam"\ntimezone = "UTC"\n[relay]\nenabled = true\n[bot]\nenabled = true\n' > "$ANNA_CONFIG"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
# stubs: claude (plugin list/install, logged; never the network) and systemctl/loginctl (logged; never real units)
STUB=$T/stub; mkdir -p "$STUB"; export STUBLOG=$T/stub.log
printf '#!/bin/bash\necho "bun $*" >> "$STUBLOG"\n' > "$STUB/bun"; chmod +x "$STUB/bun"   # install.sh requires bun for the relay; the tests never run it
cat > "$STUB/claude" <<'S'
#!/bin/bash
echo "claude $*" >> "$STUBLOG"
case "$1 $2" in "plugin list") cat "$STUBLOG.plugins" 2>/dev/null || echo '[]' ;; "plugin install") echo "[{\"id\":\"$3\"}]" > "$STUBLOG.plugins" ;; esac
S
printf '#!/bin/bash\necho "$(basename "$0") $*" >> "$STUBLOG"\n' > "$STUB/systemctl"; cp "$STUB/systemctl" "$STUB/loginctl"
chmod +x "$STUB"/*; export PATH=$STUB:$PATH
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

# before any install: `claude` in the clone must already offer /anna-setup (Claude Code reads .claude/skills/)
ok "/anna-setup is a project skill of the clone" '[ -f .claude/skills/anna-setup/SKILL.md ] && grep -q "^name: anna-setup" .claude/skills/anna-setup/SKILL.md'

# no config yet: write it from the example and stop, so nothing starts from the example's values
mv "$ANNA_CONFIG" "$T/conf.keep"
out=$(./install.sh --no-systemd 2>&1); rc=$?
ok "first run with no config writes it and stops" '[ $rc -eq 0 ] && [ -f "$ANNA_CONFIG" ] && grep -q "Wrote" <<<"$out" && [ ! -e "$HOME/anna-record" ] && [ ! -e "$HOME/bin" ] && [ ! -e "$HOME/CLAUDE.md" ]'
mv "$T/conf.keep" "$ANNA_CONFIG"

out=$(./install.sh --no-systemd 2>&1); rc=$?
echo "$out" | sed "s/^/   install: /" | head -12
ok "install exits 0" '[ $rc -eq 0 ]'
ok "scripts and hooks are in ~/bin" '[ -x "$HOME/bin/anna-stream" ] && [ -x "$HOME/bin/anna-session-draft" ] && [ -f "$HOME/bin/anna_cfg.py" ]'
ok "skills are installed" '[ -f "$HOME/.claude/skills/anna-wrapup/SKILL.md" ]'
ok "the record was created and committed" 'git -C "$HOME/anna-record" log --oneline | grep -q "start from the Anna template"'
ok "the record is filled in (no placeholders)" '! grep -rq "@[A-Z]*@" "$HOME/anna-record/CLAUDE.md" "$HOME/anna-record/memory/MEMORY.md" && grep -q "Nova and Sam" "$HOME/anna-record/CLAUDE.md"'
ok "headless settings rendered with absolute paths" 'jq -e ".permissions.allow | index(\"Edit(/$HOME/anna-record/**)\")" "$HOME/.claude/anna-headless-settings.json" >/dev/null'
ok "no HTTP-capable command in the headless allowlist" '[ -s "$HOME/.claude/anna-headless-settings.json" ] && ! jq -r ".permissions.allow[]" "$HOME/.claude/anna-headless-settings.json" | grep -qE "curl|wget|python|bun|nc "'
ok "bot settings rendered with fakechat (relay on)" 'jq -e ".permissions.allow | index(\"mcp__plugin_fakechat_fakechat__reply\")" "$HOME/.claude/anna-tg-ops-settings.json" >/dev/null'
ok "bot can read its photo inbox (allow + additionalDirectories, placeholders filled)" 'jq -e "(.permissions.allow | map(select(test(\"^Read\\\\(//.*/telegram-ops/inbox/\\\\*\\\\*\\\\)$\"))) | length == 1) and (.permissions.additionalDirectories | map(select(test(\"telegram-ops/inbox$\"))) | length == 1)" "$HOME/.claude/anna-tg-ops-settings.json" >/dev/null && ! grep -q "@STATE@\|@INSTANCE@" "$HOME/.claude/anna-tg-ops-settings.json"'
ok "bot unit restarts after a crash (screen in the foreground, Type=simple)" 'grep -q "^Type=simple" systemd/anna-tg@.service && grep -q "screen -DmS" systemd/anna-tg@.service'
ok "brain settings enable fakechat" 'jq -e ".enabledPlugins[\"fakechat@claude-plugins-official\"] == true" "$HOME/.claude/anna-brain-settings.json" >/dev/null'
S=$HOME/.claude/settings.json
ok "user settings keep their own keys and hooks" 'jq -e ".theme == \"dark\"" "$S" >/dev/null && grep -q other-hook "$S"'
ok "Anna's hooks are merged with absolute paths" 'jq -r ".hooks.UserPromptSubmit[].hooks[].command" "$S" | grep -qx "$HOME/bin/anna-stream hook"'
ok "fakechat and telegram stay off at user scope" 'jq -e ".enabledPlugins[\"fakechat@claude-plugins-official\"] == false and .enabledPlugins[\"telegram@claude-plugins-official\"] == false" "$S" >/dev/null'
ok "~/CLAUDE.md written" 'grep -q "^# Nova.s home" "$HOME/CLAUDE.md"'
ok "the six engines are installed, filled in" '[ "$(ls "$HOME/.claude/agents"/anna-*.md | wc -l)" -eq 6 ] && ! grep -q "@[A-Z]*@" "$HOME/.claude/agents"/anna-*.md && grep -q "You are Nova.s memory engine" "$HOME/.claude/agents/anna-memory.md"'
ok "the engines are allowed in headless runs" '[ "$(jq "[.permissions.allow[] | select(startswith(\"Agent(anna-\"))] | length" "$HOME/.claude/anna-headless-settings.json")" -eq 6 ]'
ok "the gate hook is merged as PreToolUse" 'jq -r ".hooks.PreToolUse[].hooks[].command" "$S" | grep -qx "$HOME/bin/anna-gate-hook"'
# Claude Code names the folder with every non-alphanumeric as "-" (this HOME, /tmp/tmp.XXXX/home, has a dot in it)
ok "brain memory is a symlink into the record, under Claude Code's folder name" '[ "$(readlink "$HOME/.claude/projects/$(sed "s/[^A-Za-z0-9]/-/g" <<<"$HOME")/memory")" = "$HOME/anna-record/memory" ]'

echo "my notes" >> "$HOME/anna-record/CLAUDE.md"; echo "# mine" > "$HOME/CLAUDE.md"
echo "my tweak" >> "$HOME/.claude/agents/anna-goals.md"; cp "$HOME/.claude/agents/anna-memory.md" "$T/mem.before"
jq '.permissions.allow += ["Bash(my-wrapper*)"]' "$HOME/.claude/anna-tg-ops-settings.json" > "$T/x" && mv "$T/x" "$HOME/.claude/anna-tg-ops-settings.json"
rm -rf "$HOME/anna-record/self" "$HOME/anna-record/planning/wonders.md" "$HOME/anna-record/.git"   # an older record: its
( cd "$HOME/anna-record" && git init -q -b main && git add -A && git commit -qm "an older record" )   # history never had them
git -C "$HOME/anna-record" rm -q runbooks/README.md && git -C "$HOME/anna-record" commit -qm "remove a template file on purpose"
jq '(.hooks.UserPromptSubmit[].hooks[] | select(.command | endswith("anna-stream hook")) | .timeout) = 5' "$S" > "$T/s" && mv "$T/s" "$S"   # an older install's timeout
out2=$(./install.sh --no-systemd 2>&1); rc=$?
ok "update: an Anna hook already there gets the template's timeout" '[ "$(jq "[.hooks.UserPromptSubmit[].hooks[] | select(.command | endswith(\"anna-stream hook\")) | .timeout][0]" "$S")" = 45 ]'
ok "a second install exits 0" '[ $rc -eq 0 ]'
ok "update: a template file you removed (in git history) is not added back" '[ ! -e "$HOME/anna-record/runbooks/README.md" ]'
ok "update: new template files are added to an existing record" '[ -f "$HOME/anna-record/self/README.md" ] && [ -f "$HOME/anna-record/planning/wonders.md" ] && echo "$out2" | grep -q "added what.s new in the template"'
ok "hooks are not duplicated" '[ "$(jq "[.hooks.UserPromptSubmit[].hooks[]] | length" "$S")" -eq 1 ] && [ "$(jq "[.hooks.Stop[].hooks[]] | length" "$S")" -eq 4 ]'
ok "the record is left alone" 'grep -q "my notes" "$HOME/anna-record/CLAUDE.md"'
ok "~/CLAUDE.md is left alone (template beside it)" 'grep -qx "# mine" "$HOME/CLAUDE.md" && [ -f "$HOME/CLAUDE.md.anna-new" ]'
ok "an engine you edited is left alone (new one beside it)" 'grep -q "my tweak" "$HOME/.claude/agents/anna-goals.md" && [ -f "$HOME/.claude/agents/anna-goals.md.anna-new" ]'
ok "an unedited engine is updated in place, no .anna-new" 'cmp -s "$T/mem.before" "$HOME/.claude/agents/anna-memory.md" && [ ! -e "$HOME/.claude/agents/anna-memory.md.anna-new" ]'
ok "the gate hook is not duplicated" '[ "$(jq "[.hooks.PreToolUse[].hooks[]] | length" "$S")" -eq 2 ]'
ok "your bot allowlist is left alone" 'grep -q my-wrapper "$HOME/.claude/anna-tg-ops-settings.json"'
ok "relay + bot: fakechat and telegram plugins installed at user scope" 'grep -qx "claude plugin install fakechat@claude-plugins-official -s user" "$STUBLOG" && grep -qx "claude plugin install telegram@claude-plugins-official -s user" "$STUBLOG"'
ok "a plugin already installed is not installed again" '[ "$(grep -c "plugin install telegram" "$STUBLOG")" -eq 1 ]'
jq '.enabledPlugins["telegram@claude-plugins-official"] = true' "$S" > "$T/x" && mv "$T/x" "$S"
./install.sh --no-systemd --no-plugins >/dev/null 2>&1
ok "a plugin left on at user scope is turned off again" 'jq -e ".enabledPlugins[\"telegram@claude-plugins-official\"] == false" "$S" >/dev/null'

# units: paths.bin filled in (a non-default bin), timers rendered; systemctl is the stub
sed -i 's|^\[anna\]|[paths]\nbin = "'"$HOME"'/opt/anna-bin"\n[anna]|' "$ANNA_CONFIG"
./install.sh --no-enable --no-plugins >/dev/null 2>&1; rc=$?
U=$HOME/.config/systemd/user
ok "install with units exits 0" '[ $rc -eq 0 ]'
ok "units call the scripts in paths.bin, not ~/bin" 'grep -q "^ExecStart=$HOME/opt/anna-bin/anna-day open" "$U/anna-day-open.service" && ! grep -rq "%h/bin" "$U"/anna-*.service'
ok "the relay unit's PATH has paths.bin" 'grep -q ":$HOME/opt/anna-bin:" "$U/anna-relay.service"'
ok "the scripts are in paths.bin" '[ -x "$HOME/opt/anna-bin/anna-day" ]'
exit $fail
