# Anna's clock

Anna's own schedule: follow-ups with a date ("check the backup after a few clean days", "this certificate expires on the
17th", "ask how the new sensor held up"). Not the user's calendar. A task with no date stays in `planning/backlog.md`.

**Files:** `clock/YYYY-MM.md` by due month, one line per item: `- [ ] 2026-10-21 09:00 ping #a3f2 text (added 2026-10-18 by
session)`. Time `--:--` = date only. States: `[ ]` open · `[x]` done or fired · `[-]` cancelled.

**Kinds:** `note` (shows in the morning check from its day on, until `anna-clock done ID`) · `ping` (a message to the user at
that time via `anna-notify`) · `run` (a headless `anna-run` does the text as a task at that time; deny-by-default
permissions, so a task that needs more reports instead of acting).

**Commands:** `anna-clock add WHEN [--ping|--run] TEXT` (WHEN: `2026-10-21`, `2026-10-21 09:00`, `tomorrow 09:00`, `mon`,
`+3d`, `+2h`, `+90min`) · `list [--all]` · `due [--days N]` · `done ID [note]` · `cancel ID [note]` · `tick` (the timer,
every 5 minutes; catches up after downtime). Every change commits just its month file.
