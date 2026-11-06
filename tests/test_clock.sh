#!/bin/bash
# tests/test_clock.sh — anna-clock against a throwaway record (a git repo without a remote) and state dir.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export ANNA_CONFIG=$T/anna.toml
mkdir -p "$T/bin" "$T/record"; git -C "$T/record" init -q; git -C "$T/record" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
printf '[anna]\nuser = "Sam"\ntimezone = "UTC"\n[paths]\nrecord = "%s/record"\nstate = "%s/state"\nbin = "%s/bin"\n' "$T" "$T" "$T" > "$ANNA_CONFIG"
# a fake notifier that records what it was asked to send
printf '#!/bin/bash\necho "$ANNA_NOTIFY_FROM|$*" >> "%s/sent"\n' "$T" > "$T/bin/anna-notify"; chmod +x "$T/bin/anna-notify"
export PATH="$T/bin:$PWD/bin:/usr/bin:/bin"   # never the real ~/bin: its anna-stream would write into the live stream
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
K=bin/anna-clock; fail=0
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

out=$($K add "+3d" "check the backup")
ok "add a date-only note" 'echo "$out" | grep -q "^added #[0-9a-f]\{4\} .* --:-- note: check the backup"'
id=$(echo "$out" | grep -o '#[0-9a-f]\{4\}' | head -1)
ok "it's in the month file" 'grep -q "^- \[ \] .* note $id check the backup (added .* by session)" "$T"/record/clock/*.md'
ok "the change is committed" '[ "$(git -C "$T/record" log --oneline | wc -l)" -eq 2 ]'
ok "list shows it" '$K list | grep -q "check the backup"'
ok "due today does not (3 days out)" '! $K due | grep -q "check the backup"'
ok "due --days 3 does" '$K due --days 3 | grep -q "check the backup"'
ok "a ping without a time is refused" '! $K add "+1d" --ping x 2>/dev/null'
ok "a time in the past is refused" '! $K add "2000-01-01 09:00" --ping x 2>/dev/null'
$K done "$id" "fine" >/dev/null
ok "done closes it with a suffix" 'grep -q "^- \[x\] .* $id .* — done .*: fine" "$T"/record/clock/*.md'
ok "done twice fails" '! $K done "$id" 2>/dev/null'

# tick: a due ping fires once through anna-notify; written straight into the file as already due
m=$(date -u +%Y-%m); d=$(date -u -d "-2 hours" '+%F %H:%M')
echo "- [ ] $d ping #beef stretch your legs (added x by test)" >> "$T/record/clock/$m.md"
$K tick >/dev/null
ok "tick sent the ping" 'grep -q "^clock #beef|⏰ stretch your legs (late: was due" "$T/sent"'
ok "and closed it" 'grep -q "^- \[x\] .* #beef .* — pinged" "$T/record/clock/$m.md"'
$K tick >/dev/null
ok "a second tick doesn't resend" '[ "$(wc -l < "$T/sent")" -eq 1 ]'

# tick: a due run item starts one headless anna-run through systemd-run (stubbed: records its arguments), once
printf '#!/bin/bash\necho "$*" >> "%s/runs"\n' "$T" > "$T/bin/systemd-run"; chmod +x "$T/bin/systemd-run"
m=$(date -d '-1 hour' +%Y-%m); echo "- [ ] $(date -d '-1 hour' '+%F %H:%M') run #cafe check the disk on web (added $(date +%F) by session)" >> "$T/record/clock/$m.md"
$K tick >/dev/null
ok "tick starts the run item once, as anna-run with its id" '[ "$(grep -c "anna-clock-run-cafe" "$T/runs")" -eq 1 ] && grep -q "anna-clock-run-cafe .*anna-run .*check the disk on web" "$T/runs" && grep -q " clock-cafe$" "$T/runs"'
ok "the task tells the run what to do if it needs the user" 'grep -q "Needs action" "$T/runs"'
ok "and marks it fired" 'grep -q "^- \[x\] .* run #cafe .* — run started" "$T/record/clock/$m.md"'
$K tick >/dev/null
ok "a second tick doesn't start it again" '[ "$(grep -c "anna-clock-run-cafe" "$T/runs")" -eq 1 ]'

# an item whose text names another item's id: done on that id closes only the item that owns it (2026-11-03: #05fc)
b=$($K add "+2d" "renew the cert" | grep -o '#[0-9a-f]\{4\}' | head -1)
a=$($K add "+2d" "after $b is done, tell Sam" | grep -o '#[0-9a-f]\{4\}' | head -1)
$K done "$b" >/dev/null
ok "done #id closes the item with that id" 'grep -q "^- \[x\] .* $b renew the cert" "$T"/record/clock/*.md'
ok "and not an item that only mentions it" 'grep -q "^- \[ \] .* $a after $b is done" "$T"/record/clock/*.md'
ok "done on an id only mentioned in text fails" '! $K done "${b}" 2>/dev/null'
exit $fail
