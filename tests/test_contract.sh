#!/bin/bash
# tests/test_contract.sh — contracts/v1.json: the engine files, the engines reference and the record template agree with
# it, and anna-contract tells a good block, a bad block and a broken record apart.
# Run from the repo root: tests/test_contract.sh
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
K=bin/anna-contract; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

ok "contract is valid JSON, version 1" 'jq -e ".version == 1" contracts/v1.json >/dev/null'
ok "every engine file matches the contract" '$K agents >/dev/null'
ok "the engines reference matches the contract" '$K docs >/dev/null'
cp -r record-template "$T/rec"
ok "the record template meets the record contract" '$K record "$T/rec" >/dev/null'

# blocks
good='```anna-gate
verdict: go
reason: typed ask names this action
missing: none
confirm: none
hold: none
rollback: git revert
audit: 2026-01-01T10:00 gate go web "systemctl restart x" origin=typed asked="restart x"
```'
ok "check: a full gate block passes" 'echo "$good" | $K check action-gate >/dev/null'
ok "check: the gate's short name works" 'echo "$good" | $K check gate >/dev/null'
ok "check: text around the block is ignored" '{ echo "Here is my verdict:"; echo "$good"; echo "done"; } | $K check anna-gate >/dev/null'
ok "check: a missing key fails" '! echo "$good" | grep -v "^rollback:" | $K check gate >/dev/null'
ok "check: a value outside the enum fails" '! echo "$good" | sed "s/^verdict: go/verdict: maybe/" | $K check gate >/dev/null'
ok "check: a list field checks every value" '! echo "$good" | sed "s/^missing: none/missing: asked, vibes/" | $K check gate >/dev/null'
ok "check: list values from the enum pass" 'echo "$good" | sed "s/^missing: none/missing: asked, hold/" | $K check gate >/dev/null'
ok "check: an unknown key only warns" 'out=$(echo "$good" | sed "s/^hold: none/hold: none\nextra: 1/" | $K check gate); [ $? = 0 ] && grep -q "unknown key" <<<"$out"'
ok "check: enum read by first word (stale (…))" 'printf "found: yes\nanswer: a\nas_of: 2026-01-01\nsources: x\nconflicts: none\nindex: stale (2 behind)\nretrieval: first-try\n" | $K check memory >/dev/null'
ok "check: unknown engine is a usage error" '! $K check mood </dev/null 2>/dev/null'

# engine files and docs: drift is caught
cp -r agents docs contracts "$T/"; mkdir -p "$T/bin"
sed -i 's/^when: next-pause | next-session/when: soon | next-session/' "$T/agents/anna-curiosity.md"
ok "agents: a changed enum in an engine file fails" '! $K agents "$T" >/dev/null'
sed -i 's/^source: wonder.*//' "$T/docs/reference/engines.md"
ok "docs: a dropped output key in the reference fails" '! $K docs "$T" >/dev/null'

# record
rm "$T/rec/planning/wonders.md"
ok "record: a missing required file fails" '! $K record "$T/rec" >/dev/null'
cp record-template/planning/wonders.md "$T/rec/planning/"
mkdir -p "$T/rec/journal/2026/02" && touch "$T/rec/journal/2026/02/2026-03-01.md"
ok "record: a day in the wrong month folder fails" '! $K record "$T/rec" >/dev/null'
rm "$T/rec/journal/2026/02/2026-03-01.md"
printf '# Lately\n\n- something without a count\n' > "$T/rec/self/lately.md"
ok "record: a lately line without (since …; seen N×) fails" '! $K record "$T/rec" >/dev/null'
printf '# Lately\n\n- a thing (since 2026-01-01; seen 2×)\n' > "$T/rec/self/lately.md"
ok "record: a good lately passes" '$K record "$T/rec" >/dev/null'
mv "$T/rec/hosts" "$T/rec/chapters"
ok "record: --things names the folder of things" '$K record "$T/rec" --things chapters >/dev/null && ! $K record "$T/rec" >/dev/null'

exit $fail
