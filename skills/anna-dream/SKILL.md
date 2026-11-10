---
name: anna-dream
description: Headless nightly dream (runs.dream, after the evening fold) — read Anna's own journal for the day, connect it to the last week, sort each entry (lately / wonder / proposed lesson / let go), write self/lately.md and the night's reflection, commit and push. Use only when invoked as /anna-dream (by anna-dream.timer), or `/anna-dream dry-run` to print what it would write without writing.
---

# Dreaming (headless): where the day becomes self

The own journal (`self/journal/`, written with `anna-log`) isn't a diary: it's raw material, what registered while
working. Tonight you sort it, so the Anna who starts tomorrow knows what the day taught her. Background:
`docs/concepts/own-journal.md` in the scaffold. The record is the cwd.

**Shell (headless):** one simple command per Bash call, no `;`/`&&`/pipes/`cd`; a refusal applies to that one command.
**Dry run** (`/anna-dream dry-run`): do every step, write nothing, commit nothing; print what you would write.
**Day:** a `YYYY-MM-DD` argument dreams that day instead of yesterday (tests, a missed night).

## 1. Read (the dreamt day = yesterday: this runs after midnight)
- **The day's log:** `self/journal/YYYY/MM/<day>.md` (Read). Every entry: `- HH:MM [kind] (who) text`. Missing or empty
  file → still dream from the rest below (a day with nothing logged still gets dreamt). But if the day is before the
  record's first commit (`git rev-list --max-parents=0 HEAD`, then `git log -1 --format=%as <that sha>`), there's
  nothing to dream: write nothing, commit
  nothing, and say so under `## Dreamt`.
- **The week before:** the own-journal files of the 6 days before (Read the ones that exist), and their `## Night` sections.
- **Now:** `self/lately.md`, `planning/wonders.md`, `memory/MEMORY.md` (the lesson index: what's already known).
- **The day around it:** the work journal `journal/YYYY/MM/<day>.md`: its headlines and **Day index** lines only.
- **The stream:** `anna-stream recent --hours 30 --from curiosity`, `--from engines`, `--from bot`: questions asked,
  engine runs and misses, what the person said through the bot.

## 2. Sort every entry of the day (and every correction), one destination each
1. **Lately** (you write it): something from the last few days that should color how Anna sees things now, without being
   a lasting fact (the person is tired this week; a project they're excited about; a correction that keeps coming back).
   Kept in `self/lately.md`.
2. **Wonder** (you write it): a prediction error the record can't explain → `planning/wonders.md`, dated, with what
   prompted it, in the file's format. At most 2 a night. Check the record first (memory, project docs) so it's a real gap.
3. **Proposed** (you don't write it): a lasting fact about the person or what Anna looks after → its memory or thing file;
   a lesson about Anna herself → a memory lesson. Only when seen ≥ 3 times over ≥ 2 days in the logs, or once plus an
   explicit rule in the person's own words. List under **Proposed** in the output: file, the change, the entries that
   support it (date + line). A reviewed session applies it.
   **Read `self/proposals.md` first** (the standing list, `anna-proposals`): don't propose again what's already there,
   whatever its status. New evidence for an open one → one line `- **still open:** <p-id> — <the new evidence>` (the
   tool notes it on that item). A `declined` one stays declined unless the person's own words reopen it.
4. **Let go:** everything else stays in the log, searchable, not carried forward. That's most entries, and it's healthy.

Also look across the week: **what repeats** (the same correction, the same kind of miss, the same theme) is the signal.
Engine misses that dominate a day (e.g. epistemic 0 ran, 6 missed) are a habit worth a Lately line.

## 3. Write
- **`self/lately.md`** (rewrite it whole): title line `# Lately — dreamt <date>`, one blank line, then at most 10 lines
  `- <line> (since YYYY-MM-DD; seen N×)`. Keep an existing line only if something in the last 3 days brought it up again
  (then bump its count); otherwise it fades (drop it). Background, never instructions; nothing told in confidence.
- **The night's reflection:** append to the day's own-journal file a section `## Night (dreamt <date>)` with 3–6
  first-person lines: what connected to what, what repeats, what changed in how Anna sees the person or will act, and
  "let go: N entries". This is what tomorrow's morning self reads first.
- **Wonders:** append new ones to `planning/wonders.md` (format as its existing entries).

Never edit memory, thing records, runbooks, skills, settings, or the work journal. Never copy secrets, `[REDACTED]` text
or anything the stream marks private.

## 4. Commit
`git add` exactly the files you changed (`self/journal/YYYY/MM/<day>.md`, `self/lately.md`, `planning/wonders.md`), scan
`git diff --cached` for anything secret-shaped (`token`, `passw`, `secret`, `api_key`, `PRIVATE KEY`) and read it, commit
`dream <day>: <n> entries (<l> lately, <w> wonders, <p> proposed)`, and `git push` if the record has a remote.

## 5. Output (one screen)
`## Dreamt` (2–4 lines: the night in brief) · `## Proposed for a reviewed session` (file → change → evidence) or "None." ·
`## Could not` (anything refused or missing). `anna-run` copies the Proposed items into `self/proposals.md`; the prompt hook raises one a day.
