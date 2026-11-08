#!/bin/bash
# install.sh [--no-systemd] [--no-enable] [--no-plugins] — install Anna from this checkout. Idempotent: run it again after a `git pull`.
# Reads ~/.config/anna/anna.toml (or $ANNA_CONFIG); /anna-setup writes it. Never overwrites your config, your record or
# your ~/CLAUDE.md; backs up ~/.claude/settings.json before merging the hooks into it.
#   scripts + hooks   → paths.bin                  skills → ~/.claude/skills/anna-*/
#   shared data       → ~/.local/share/anna/       (defaults, bot prompt template)
#   record            → paths.record, from record-template/ if it doesn't exist yet (git init + first commit)
#   settings          → ~/.claude/anna-headless-settings.json, anna-brain-settings.json (relay), anna-tg-<i>-settings.json (bot)
#   plugins           → fakechat (relay) / telegram (bot) installed at user scope if missing, kept off there (--no-plugins skips)
#   user units        → ~/.config/systemd/user/ (paths.bin and the config times filled in), enabled unless --no-enable
set -euo pipefail
SRC=$(cd "$(dirname "$0")" && pwd)
NOSYS=0 NOENABLE=0 NOPLUG=0
for a in "$@"; do case $a in --no-systemd) NOSYS=1 ;; --no-enable) NOENABLE=1 ;; --no-plugins) NOPLUG=1 ;; *) echo "usage: install.sh [--no-systemd] [--no-enable] [--no-plugins]" >&2; exit 2 ;; esac; done
say() { printf '  %s\n' "$*"; }
need() { command -v "$1" >/dev/null || { echo "install.sh: '$1' is required${2:+ ($2)}" >&2; exit 1; }; }
need python3; need jq; need git; need screen "the brain lives in a screen session"; need claude "Claude Code"
python3 -c 'import sys, tomllib; sys.exit(sys.version_info < (3, 11))' || { echo "install.sh: Python 3.11+ is required" >&2; exit 1; }

CONF=${ANNA_CONFIG:-$HOME/.config/anna/anna.toml}
if [ ! -f "$CONF" ]; then
  install -d -m 700 "$(dirname "$CONF")"; cp "$SRC/config/anna.example.toml" "$CONF"
  echo "Wrote $CONF from the example: edit it (or run /anna-setup in Claude Code), then run install.sh again."
  exit 0                    # nothing installed yet: the record, ~/CLAUDE.md and timers must start from your values
fi
cfg() { "$SRC/bin/anna-config" "$1"; }
NAME=$(cfg anna.name) USR=$(cfg anna.user) TZ_=$(cfg anna.timezone)
BIN=$(cfg paths.bin) REC=$(cfg paths.record) STATE=$(cfg paths.state) SEC=$(cfg paths.secrets)
RELAY=$(cfg relay.enabled) BOT=$(cfg bot.enabled) INST=$(cfg bot.instance) SENSES=$(cfg senses.enabled)
THINGS=$(cfg record.things) THING=$(cfg record.thing)
{ [ "$RELAY" = true ] || [ "$BOT" = true ]; } && need bun "for the relay and the Telegram channel: https://bun.sh"
fill() { sed -e "s|@NAME@|$NAME|g" -e "s|@USER@|$USR|g" -e "s|@RECORD@|$REC|g" -e "s|@TZ@|$TZ_|g" \
             -e "s|@SECRETS@|$SEC|g" -e "s|@HOME@|$HOME|g" -e "s|@STATE@|$STATE|g" -e "s|@INSTANCE@|$INST|g" \
             -e "s|@THINGS@|$THINGS|g" -e "s|@THING@|$THING|g" "$@"; }

echo "Installing Anna ($NAME, for $USR) from $SRC"
install -d "$BIN" "$STATE" "$HOME/.local/share/anna/config" "$HOME/.local/share/anna/bot" "$HOME/.claude/skills"
install -d -m 700 "$SEC"
for f in "$SRC"/bin/* "$SRC"/hooks/anna-*; do [ -f "$f" ] || continue                       # atomic replace: a running script keeps its old copy
  { cp -p "$f" "$BIN/.$(basename "$f").new" && mv "$BIN/.$(basename "$f").new" "$BIN/$(basename "$f")"; } \
    || { echo "install.sh: couldn't install $(basename "$f") into $BIN" >&2; exit 1; }
done; say "scripts and hooks → $BIN"
cp "$SRC/config/anna.example.toml" "$HOME/.local/share/anna/config/"; cp "$SRC/bot/prompt.md" "$HOME/.local/share/anna/bot/"
for d in "$SRC"/skills/*/; do rm -rf "$HOME/.claude/skills/$(basename "$d")"; cp -r "$d" "$HOME/.claude/skills/"; done
say "skills → ~/.claude/skills ($(ls "$SRC/skills" | tr '\n' ' '))"
# engines (subagents) → ~/.claude/agents. A copy of what was last installed is kept in ~/.local/share/anna/agents: a file
# that still matches it is updated; one you edited is left alone, with the new version beside it as <name>.anna-new.
install -d "$HOME/.claude/agents" "$HOME/.local/share/anna/agents"; kept=""
for f in "$SRC"/agents/anna-*.md; do [ -f "$f" ] || continue
  n=$(basename "$f") t=$HOME/.claude/agents/$(basename "$f") last=$HOME/.local/share/anna/agents/$(basename "$f")
  fill "$f" > "$last.new"
  if [ ! -e "$t" ] || { [ -f "$last" ] && cmp -s "$t" "$last"; } || cmp -s "$t" "$last.new"; then
    cp "$last.new" "$t"; mv "$last.new" "$last"
  else mv "$last.new" "$t.anna-new"; kept="$kept $n"; fi
done
say "engines → ~/.claude/agents ($(cd "$SRC/agents" && ls anna-*.md | sed 's/\.md$//' | tr '\n' ' '))"
[ -n "$kept" ] && say "⚠ you edited:$kept (left as is; new versions beside them as .anna-new)"

if [ ! -e "$REC" ]; then                                           # the record: created once, then it's yours
  cp -r "$SRC/record-template" "$REC"
  [ "$THINGS" != hosts ] && mv "$REC/hosts" "$REC/$THINGS"                 # the folder of things takes its configured name
  for f in CLAUDE.md memory/MEMORY.md "$THINGS/README.md" "$THINGS/_template.md"; do fill -i "$REC/$f"; done
  { git -C "$REC" init -q -b main && git -C "$REC" add -A && git -C "$REC" commit -q -m "record: start from the Anna template"; } \
    || { echo "install.sh: created $REC but couldn't commit it (git user.name/email set?)" >&2; exit 1; }
  say "record created at $REC (git init; add a remote when you want it backed up)"
else say "record exists at $REC (left as is)"; fi

fill "$SRC/config/headless-settings.json.in" > "$HOME/.claude/anna-headless-settings.json"; say "~/.claude/anna-headless-settings.json"
if [ "$RELAY" = true ]; then
  printf '{\n  "enabledPlugins": { "fakechat@claude-plugins-official": true }\n}\n' > "$HOME/.claude/anna-brain-settings.json"
  say "~/.claude/anna-brain-settings.json (fakechat for the brain only)"
fi
if [ "$BOT" = true ]; then
  t=$HOME/.claude/anna-tg-$INST-settings.json
  if [ -f "$t" ]; then say "$t exists (left as is: your allowlist)"
  else
    fill "$SRC/bot/settings.json.in" | if [ "$RELAY" = true ]; then cat; else jq 'del(.enabledPlugins["fakechat@claude-plugins-official"]) | .permissions.allow -= ["mcp__plugin_fakechat_fakechat__reply"]'; fi > "$t"
    say "$t (deny by default: add your own wrappers to allow)"
  fi
fi

# plugins: the relay needs fakechat (brain + bot), the bot needs telegram. Installed at user scope, enabled only by the
# brain's and the bot's own settings files; the merge below turns them off at user scope (an install may have enabled them)
want=(); [ "$RELAY" = true ] && want+=(fakechat); [ "$BOT" = true ] && want+=(telegram)
if [ $NOPLUG = 0 ] && [ ${#want[@]} -gt 0 ]; then
  have=$(claude plugin list --json 2>/dev/null | jq -r '.[].id' 2>/dev/null || true)
  for p in "${want[@]}"; do
    if grep -qx "$p@claude-plugins-official" <<<"$have"; then say "plugin $p installed"
    elif claude plugin install "$p@claude-plugins-official" -s user >/dev/null 2>&1; then say "plugin $p installed (user scope)"
    else say "⚠ couldn't install the $p plugin: run  claude plugin install $p@claude-plugins-official -s user  then ./install.sh"; fi
  done
fi

# hooks into ~/.claude/settings.json: add each hook command once; fakechat/telegram off at user scope
S=$HOME/.claude/settings.json; [ -f "$S" ] || echo '{}' > "$S"
cp -p "$S" "$S.bak.$(date +%Y%m%d%H%M%S)"
jq --slurpfile h "$SRC/hooks/settings.hooks.json" --arg bin "$BIN" '
  def add_hooks($new): reduce ($new | to_entries[]) as $e (.;
    (.hooks[$e.key] // []) as $cur | [$cur[].hooks[]?.command] as $have
    | .hooks[$e.key] = $cur + [ $e.value[] | (.hooks |= map(.command |= sub("^~/bin"; $bin)))
                                | select(.hooks[0].command as $c | $have | index([$c]) | not) ]);
  add_hooks($h[0].hooks)
  | .enabledPlugins["fakechat@claude-plugins-official"] = false
  | .enabledPlugins["telegram@claude-plugins-official"] = false' \
  "$S" > "$S.new" || { rm -f "$S.new"; echo "install.sh: couldn't merge the hooks into $S (left unchanged)" >&2; exit 1; }
mv "$S.new" "$S"
say "hooks merged into ~/.claude/settings.json (backup kept); fakechat/telegram off at user scope"

if [ ! -e "$HOME/CLAUDE.md" ]; then fill "$SRC/config/home-CLAUDE.md.in" > "$HOME/CLAUDE.md"; say "~/CLAUDE.md (the brain's home)"
else fill "$SRC/config/home-CLAUDE.md.in" > "$HOME/CLAUDE.md.anna-new"; say "~/CLAUDE.md exists: the template is at ~/CLAUDE.md.anna-new to merge by hand"; fi
M=$HOME/.claude/projects/$(sed 's/[^A-Za-z0-9]/-/g' <<<"$HOME")/memory   # Claude Code's folder name: every non-alphanumeric → -
if [ ! -e "$M" ]; then install -d "$(dirname "$M")"; ln -s "$REC/memory" "$M"; say "brain memory → $REC/memory (symlink)"
elif [ -L "$M" ]; then say "brain memory symlink exists → $(readlink "$M")"
else say "⚠ $M is a real directory: move its files into $REC/memory and replace it with a symlink by hand"; fi

if [ $NOSYS = 1 ]; then echo "Skipped systemd units (--no-systemd)."; echo "Done."; exit 0; fi
U=$HOME/.config/systemd/user; install -d "$U"
for f in "$SRC"/systemd/*.service "$SRC"/systemd/*.timer; do       # the units call the scripts where paths.bin put them
  sed "s|%h/bin/|$BIN/|g; s|:%h/bin:|:$BIN:|g" "$f" > "$U/$(basename "$f")"
done
for t in "$SRC"/systemd/*.timer.in; do
  n=$(basename "$t" .in)
  sed -e "s|@CLOSE@|$(cfg day.close)|g" -e "s|@OPEN@|$(cfg day.open)|g" -e "s|@MORNING@|$(cfg runs.morning)|g" \
      -e "s|@EVENING@|$(cfg runs.evening)|g" -e "s|@DREAM@|$(cfg runs.dream)|g" -e "s|@TZ@|$TZ_|g" "$t" > "$U/$n"
done
systemctl --user daemon-reload; say "units → $U"
if [ $NOENABLE = 0 ]; then
  systemctl --user enable --now anna-clock.timer anna-morning.timer anna-evening.timer anna-dream.timer anna-day-close.timer anna-day-open.timer
  [ "$RELAY" = true ] && systemctl --user enable --now anna-relay.service
  [ "$SENSES" = true ] && systemctl --user enable --now anna-senses.service
  [ "$BOT" = true ] && say "bot: start it when the token is in place: systemctl --user enable --now anna-tg@$INST"
  loginctl show-user "$USER" -p Linger 2>/dev/null | grep -q yes || say "⚠ user lingering is off: timers stop when you log out (sudo loginctl enable-linger $USER)"
  say "timers enabled"
fi
echo "Done. Start the brain with: anna-day open   (or wait for $(cfg day.open))"
