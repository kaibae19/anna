#!/bin/bash
# tests/test_proposals.sh — anna-proposals: ingest a handoff's "Proposed" items once, raise one a day, keep a status.
# A throwaway record and config. Run from the repo root: tests/test_proposals.sh
set -u
cd "$(dirname "$0")/.."
P=$PWD/bin/anna-proposals
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml ANNA_PROPOSALS=$T/self/proposals.md
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nstate = "%s/state"\nrecord = "%s"\n' "$T" "$T" > "$ANNA_CONFIG"
fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
mkdir -p "$T/journal/handoffs"
cat > "$T/journal/handoffs/2026-01-01-dream.md" <<'EOF'
> Headless run, exit 0

## Dreamt
A night.

## Proposed for a reviewed session
1. **New memory lesson `record-first`:** search the record before calling something unknown.
   - 11-08 12:07: .60 "unidentified", but the runbook had it.
2. **`planning/backlog.md`:** add "the timer drifts".

## Could not
- **not a proposal:** this is in another section.
EOF
cat > "$T/journal/handoffs/2026-01-02-evening.md" <<'EOF'
Folded.

**Proposed for the next session**
- **memory:**
  - `a.md` front matter doesn't parse.
- **retrieval:** nothing to add.
- **still open:** p-PLACEHOLDER (record-first), seen again tonight.

**⚠ Odd**
- **not a proposal either**
EOF
out=$("$P" ingest "$T/journal/handoffs/2026-01-01-dream.md")
ok "ingest: two items from a ## section" 'grep -q "2 new" <<<"$out"'
ok "ingest: the next section is not read" '! grep -q "not a proposal" "$ANNA_PROPOSALS"'
ok "ingest: again adds nothing" '"$P" ingest "$T/journal/handoffs/2026-01-01-dream.md" | grep -q "0 new"'
id=$("$P" list | grep record-first | cut -d" " -f1)
sed -i "s/p-PLACEHOLDER/$id/" "$T/journal/handoffs/2026-01-02-evening.md"
out=$("$P" ingest "$T/journal/handoffs/2026-01-02-evening.md")
ok "ingest: bold-line section, one real item ('nothing to add' skipped, the id reference not a new item)" 'grep -q "1 new" <<<"$out"'
ok "ingest: the referenced proposal notes 'seen again'" '"$P" show "$id" | grep -q "seen again (evening 2026-01-02)"'
ok "ingest: a short heading line takes its first child as the summary" '"$P" list | grep -q "memory: \`a.md\` front matter"'
ok "list: three live" '[ "$("$P" list | grep -c "^p-")" = 3 ]'
nx=$("$P" next)
ok "next: oldest open first, as id<TAB>summary" '[ "${nx%%	*}" = "$id" ]'
ok "raised-in: a reply without a question doesn't count" '[ -z "$(echo "New memory lesson record-first: search the record." | "$P" raised-in -)" ]'
ok "raised-in: a reply that asks it marks it raised" 'echo "Last night I proposed a memory lesson: search the record first before calling something unknown. Want it?" | "$P" raised-in - | grep -q raised'
ok "next: nothing more today (one a day)" '[ -z "$("$P" next)" ]'
ok "set: accepted with her words" '"$P" set "$id" accepted --said "yes; do it" | grep -q accepted && "$P" show "$id" | grep -q "said \"yes, do it\""'
ok "set: unknown status refused" '! "$P" set "$id" maybe 2>/dev/null'
ok "set: unknown id refused" '! "$P" set p-000000 applied 2>/dev/null'
"$P" set "$id" applied --commit abc1234 >/dev/null
ok "list: applied drops out of the default list" '! "$P" list | grep -q "$id" && "$P" list --all | grep -q "$id"'
# later comes back after 7 days, raised twice stops: fake the history dates
id2=$("$P" list | grep timer | cut -d" " -f1)
"$P" set "$id2" later >/dev/null
sed -i "s/^- history: \(.*\)$(date -u +%F) later/- history: \12000-01-01 later/" "$ANNA_PROPOSALS"
sed -i "s/$(date -u +%F) raised/2000-01-01 raised/" "$ANNA_PROPOSALS"
ok "next: 'later' comes back after 7 days" '"$P" next | grep -q "$id2"'
"$P" set "$id2" raised >/dev/null; sed -i "s/$(date -u +%F) raised/2000-01-02 raised/" "$ANNA_PROPOSALS"
"$P" set "$id2" raised >/dev/null; sed -i "s/$(date -u +%F) raised/2000-01-03 raised/" "$ANNA_PROPOSALS"
ok "next: raised twice without an answer isn't raised again" '! "$P" next | grep -q "$id2"'
ok "list: but stays in the list" '"$P" list | grep -q "$id2"'
exit $fail
