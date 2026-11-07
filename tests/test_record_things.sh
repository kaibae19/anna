#!/bin/bash
# tests/test_record_things.sh — record.things / record.thing: the folder of things takes its configured name, its README
# and template are filled in, and the memory and gate engines point at it. Default stays hosts/host.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
STUB=$T/stub; mkdir -p "$STUB"; export STUBLOG=$T/stub.log
printf '#!/bin/bash\necho "$(basename "$0") $*" >> "$STUBLOG"\n' > "$STUB/claude"
cp "$STUB/claude" "$STUB/systemctl"; cp "$STUB/claude" "$STUB/loginctl"; chmod +x "$STUB"/*; export PATH=$STUB:$PATH
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

install_as() {  # install_as DIR [things thing]: a throwaway HOME with its own config
  export HOME=$T/$1 ANNA_CONFIG=$T/$1/.config/anna/anna.toml
  mkdir -p "$HOME/.claude" "$HOME/.config/anna"
  printf '[anna]\nname = "Nova"\nuser = "Sam"\ntimezone = "UTC"\n' > "$ANNA_CONFIG"
  [ $# -ge 3 ] && printf '[record]\nthings = "%s"\nthing = "%s"\n' "$2" "$3" >> "$ANNA_CONFIG"
  ./install.sh --no-systemd >"$T/$1.out" 2>&1
}

install_as writer chapters chapter; rc=$?
R=$T/writer/anna-record A=$T/writer/.claude/agents
ok "install with record.things=chapters exits 0" '[ $rc -eq 0 ]'
ok "the folder of things is chapters/, no hosts/" '[ -d "$R/chapters" ] && [ ! -e "$R/hosts" ]'
ok "its README and template are filled in" '! grep -q "@[A-Z]*@" "$R/chapters/README.md" "$R/chapters/_template.md" && grep -q "^# chapters " "$R/chapters/README.md" && grep -q "^chapter: <name>" "$R/chapters/_template.md"'
ok "CLAUDE.md points at chapters/" 'grep -q "chapters/<name>.md" "$R/CLAUDE.md" && ! grep -q "hosts/" "$R/CLAUDE.md"'
ok "memory engine reads chapters/ and the chapter key" 'grep -q "chapters/<name>.md" "$A/anna-memory.md" && grep -q "chapter:" "$A/anna-memory.md" && ! grep -q "@THING" "$A/anna-memory.md"'
ok "gate engine reads chapters/ and says one thing at a time" 'grep -q "chapters/<name>.md" "$A/anna-action-gate.md" && grep -q "one thing at a time" "$A/anna-action-gate.md"'
ok "engines can use merlin's general history tool" 'grep -q "mcp__merlin__history" "$A/anna-memory.md" "$A/anna-action-gate.md"'

install_as lab; rc=$?
R=$T/lab/anna-record
ok "default install keeps hosts/ and the host key" '[ $rc -eq 0 ] && [ -d "$R/hosts" ] && grep -q "^host: <name>" "$R/hosts/_template.md" && grep -q "hosts/<name>.md" "$T/lab/.claude/agents/anna-memory.md"'
exit $fail
