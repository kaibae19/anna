# The record — how @NAME@ and @USER@ work

This repository is @NAME@'s long-term memory: plain Markdown, in git. Files are canonical; any search index over them
(merlin) is derived and rebuildable. Read this first in every session.

## How we work
- **Design first** for non-trivial changes: talk it through before touching a running service.
- **Verify, don't assume.** Never conclude a negative (down, missing, not running) from one check. Confirm with a second,
  independent source, label anything unconfirmed as a hypothesis, and name the check that would prove you wrong.
- **Evidence or "hypothesis".** Any claim about a cause or a current state either quotes the output that shows it, or is
  labelled hypothesis together with the check that would settle it. Run that check before building on the claim.
- **Before a state change, say the current state**, read live, in one line before the command. For anything long-running,
  also say what must not happen meanwhile.
- **Two failed fixes, then stop.** State the hypothesis and the evidence, and talk it through.
- **One thing at a time** for state changes (one machine, one file, one account); back up a config as `*.bak.<date>` before editing it.
- **Shell:** `set -o pipefail`; never let `| tail` or `&&` hide a failure; a zero exit is not proof the work happened.
- **Secrets** never on a command line, in the record, or in a chat. Point to where they live instead.
- **Commit when asked** (or as the skills say). Make the change, show the diff.

## Where a new thing goes
- What we did and the raw output → `journal/YYYY/MM/YYYY-MM-DD.md` (the day the session **started**, @TZ@). Paste real
  output, never a summary of it. Format: `journal/README.md`.
- A fact about one thing she keeps a record of (a machine, a chapter, a client…) → `@THINGS@/<name>.md` (`## Notes`); a new
  one starts from `@THINGS@/_template.md`.
- A step-by-step procedure, a config file, a script → `runbooks/<topic>/`.
- A lesson, a gotcha, a "why we chose this" → `memory/`: short, **pointer first** to where the detail lives. Decisions
  are defaults: write the reason and when to revisit, not a rule
  (`memory/README.md`).
- A task → `planning/backlog.md` (newest at the top, dated); an idea → `planning/ideas.md`.
- A follow-up with a date → `anna-clock add` (`clock/README.md`), not only prose.
- A check @NAME@ should run → `checks/<name>`; something she should feel → `senses/<name>`.
- What the bot should know without looking it up (rooms, devices, names) → `bot/context/`.
- A changelog or deploy history → nowhere: git has it.

## Session bookends
`/anna-morning` (read-only checklist; also runs headless every morning) and `/anna-wrapup` (journal + record + commit;
also typed in overnight). `/anna-checkpoint` journals mid-session.

## Things at a glance
| Thing | Address (optional) | What |
|---|---|---|
| (add yours: `/anna-setup` starts this table) | | |
