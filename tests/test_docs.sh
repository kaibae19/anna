#!/bin/bash
# tests/test_docs.sh — the docs site keeps up with the code: every bin/ command, config key, skill, engine and hook has
# its reference entry; no home names or session links leak into docs/; and `mkdocs build --strict` passes (broken links
# fail) when mkdocs is installed (pip install -r requirements-docs.txt; or set MKDOCS=/path/to/mkdocs).
set -u
cd "$(dirname "$0")/.."
fail=0; ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
R=docs/reference

for f in bin/*; do
  n=$(basename "$f"); case $n in __pycache__|*.pyc) continue;; esac
  ok "commands.md has ## \`$n\`" "grep -qF '## \`$n\`' $R/commands.md"
done
for k in $(python3 -c 'import tomllib,sys
d=tomllib.load(open("config/anna.example.toml","rb"))
for s,v in d.items():
    for k in (v if isinstance(v,dict) else {}): print(k)'); do
  ok "config.md names \`$k\`" "grep -qE '\`([a-z_]+\.)?$k\`' $R/config.md"
done
for d in skills/*/; do n=$(basename "$d"); ok "skills.md names $n" "grep -qF '$n' $R/skills.md"; done
for f in agents/*.md; do n=$(basename "$f" .md); ok "engines.md names $n" "grep -qF '$n' $R/engines.md"; done
for f in hooks/*; do
  n=$(basename "$f"); case $n in __pycache__|*.json) continue;; esac
  ok "hooks.md names $n" "grep -qF '$n' $R/hooks.md"
done

# Coffee Logic: no session links, and no person, home or host of yours. Your own names live outside the repo, one
# extended regex per line (case-insensitive): $ANNA_LEAK_PATTERNS, default ~/.config/anna/leak-patterns.
LP=${ANNA_LEAK_PATTERNS:-$HOME/.config/anna/leak-patterns}
leak=$(grep -rniE 'claude\.ai/(code|artifact)' docs www mkdocs.yml README.md || true)
if [ -s "$LP" ]; then
  leak+=$(grep -v -e '^#' -e '^[[:space:]]*$' "$LP" | grep -rniE -f - docs www mkdocs.yml README.md \
          | grep -v -E 'kaibae19/(merlin|anna)' || true)
else
  echo "note: no $LP, so only session links are checked (add your own names there)"
fi
ok "no home names or session links in docs or the front page" '[ -z "$leak" ]'
[ -n "$leak" ] && echo "$leak" | sed 's/^/       /'

MK=${MKDOCS:-$(command -v mkdocs || true)}
if [ -n "$MK" ] && [ -x "$MK" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  out=$("$MK" build --strict -q -d "$T/site" 2>&1); rc=$?
  ok "mkdocs build --strict" '[ $rc -eq 0 ]'
  [ $rc -ne 0 ] && echo "$out" | sed 's/^/       /' | head -30
else
  echo "skip mkdocs build (no mkdocs: pip install -r requirements-docs.txt, or set MKDOCS)"
fi
exit $fail
