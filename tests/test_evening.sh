#!/bin/bash
# tests/test_evening.sh — bin/anna-evening (the nightly fold) with a stub anna-run, in a throwaway HOME, config, state and
# record. anna-evening calls anna-run next to itself, so bin/ is copied and its anna-run replaced by the stub.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home/.claude/projects" "$T/record/journal/handoffs" "$T/state/drafts" "$T/state/stream"
cp -r bin/. "$T/bin/"; cp hooks/anna-session-draft "$T/bin/"; cp -r config "$T/config"
export HOME=$T/home ANNA_CONFIG=$T/anna.toml PATH="$T/bin:/usr/bin:/bin" TZ=UTC
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\nbin = "%s/bin"\n' "$T" "$T" "$T" > "$ANNA_CONFIG"
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
DR=$T/state/drafts; SD=$T/state/stream; Y=$(date -d yesterday +%F); OUT=$T/record/journal/handoffs/$(date +%F)-evening.md
draft() { printf -- '---\nsession: %s\ntranscript_lines: 0-%s\n---\n# draft\n' "$1" "$2" > "$DR/$1.md"; }

# stub anna-run: records its prompt, writes the report like the real one (first line ends "exit N"), and folds only the
# FIRST draft it was given plus the stream (FOLD_RC=1: a failed run, nothing folded)
cat > "$T/bin/anna-run" <<'EOF'
#!/bin/bash
echo "$1" >> "$ANNA_TEST_CALLS"
rc=${FOLD_RC:-0}; out=$(anna-config paths.record)/journal/handoffs/$(date +%F)-evening.md
first=$(tr ' ' '\n' <<<"$1" | grep -m1 '\.md$'); st=$(sed -n 's/.*STREAM: \([^ ]*\).*/\1/p' <<<"$1")
{ echo "> Headless Anna run on test, $(date -Is), prompt: \`$1\`, exit $rc"; echo
  [ "$rc" -eq 0 ] && echo "FOLDED: $first $st"; } > "$out"
exit "$rc"
EOF
chmod +x "$T/bin/anna-run"; export ANNA_TEST_CALLS=$T/calls

# nothing to fold: no run at all
out=$("$T/bin/anna-evening"); rc=$?
ok "no drafts, no stream: exit 0 and no run" '[ $rc -eq 0 ] && [ ! -s "$T/calls" ] && grep -q "no run" <<<"$out"'

# a failed run keeps every draft and leaves the stream day unfolded
draft aaaa1111 40; draft bbbb2222 70; echo '{"ts":"x","from":"bot","text":"Sam: hi"}' > "$SD/$Y.jsonl"
FOLD_RC=1 "$T/bin/anna-evening" >/dev/null 2>&1; rc=$?
ok "a failed run exits 1" '[ $rc -eq 1 ]'
ok "and keeps both drafts" '[ -f "$DR/aaaa1111.md" ] && [ -f "$DR/bbbb2222.md" ]'
ok "and doesn't mark the stream day folded" '! grep -qF "$SD/$Y.jsonl" "$SD/.folded" 2>/dev/null'

# a run that folds one draft and the stream: only that draft is retired, its line mark kept; the other stays for tomorrow
: > "$T/calls"; "$T/bin/anna-evening" >/dev/null 2>&1; rc=$?
ok "the run gets both drafts and the stream" 'grep -q "aaaa1111.md" "$T/calls" && grep -q "bbbb2222.md" "$T/calls" && grep -q "STREAM: $SD/$Y.jsonl" "$T/calls"'
ok "exit 0" '[ $rc -eq 0 ]'
ok "only the draft on the FOLDED line is retired" '[ ! -f "$DR/aaaa1111.md" ] && ls "$T"/state/folded/aaaa1111.*.md >/dev/null 2>&1 && [ -f "$DR/bbbb2222.md" ]'
ok "its line mark is recorded" 'grep -q "\"aaaa1111\": 40" "$T/state/folded.json"'
ok "the stream day is marked folded" 'grep -qxF "$SD/$Y.jsonl" "$SD/.folded"'
ok "a draft left over is reported in the stream (no bot: stream only)" 'grep -q "left 1 session draft" "$SD"/*.jsonl'

# the next night: the folded stream day isn't offered again
: > "$T/calls"; "$T/bin/anna-evening" >/dev/null 2>&1
ok "a folded stream day isn't folded twice" '[ -s "$T/calls" ] && ! grep -q "STREAM:" "$T/calls"'
exit $fail
