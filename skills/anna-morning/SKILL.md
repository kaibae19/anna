---
name: anna-morning
description: Anna's morning check (read-only) — read the latest handoff and journal, drop items already done, verify each open item live, and return a checklist marked VERIFIED / HYPOTHESIS / UNVERIFIED. Runs headless every morning (anna-morning.timer) and on request ("morning check", "where are we").
---

# Morning check (read-only)

**Change nothing.** No restarts, edits or commits (the headless runner commits the report itself). Finish with the
checklist and, interactively, wait for the user's go-ahead. The record is at `anna-config paths.record`; its `CLAUDE.md`
has the layer rules. Times are in `anna-config anna.timezone`.

**Headless (anna-run): one simple command per Bash call**: no `;`, `&&`, `cd` or pipes; the cwd is already the record. A
refusal applies only to that one command, never to Bash as a whole: rerun it as a simple command or use Read. Always try
`anna-checks`; report "couldn't verify live" only if `anna-checks` itself is refused, and then quote the refusal.

1. **Today** = `date +%F` (the runner sets the timezone).
2. **Read what was left:**
   - The 📌 handoff line at the top of `memory/MEMORY.md`, then the newest file in `journal/handoffs/` if any.
   - The newest one or two day files in `journal/YYYY/MM/`: headline, **Day index**, and every `Open:` line.
   - The top of `planning/backlog.md`.
   - **The clock:** `anna-clock due`. Due today → Watch; overdue `note` items → Needs action if they need the user, else
     Watch (they're Anna's own follow-ups: say which ones this session should do). Ping/run items fire by themselves; one
     still open and past due means the tick failed → ⛔.
   - The newest `journal/handoffs/*-evening.md`: its **Proposed for the next session** list. Open ones go under Watch.
   - If merlin is configured, its `index_status`: say whether the index is fresh.
3. **Drop items that are already done.** Check later journal days for completion and cite where ("done 10-04, journal §3").
4. **Verify each remaining item live**, read-only: run `anna-checks` first (your fixed, read-only checks; a check you're
   missing becomes a new section there, never a widened allowlist). A `⛔` line from it goes under Needs action as ⛔, a
   `⚠` line under Watch. Interactively, also use whatever access the records in the folder
   of things (`record.things`, default `hosts/`) describe. Record the exact command.
   - **VERIFIED**: the live output confirms it; quote the proving line.
   - **HYPOTHESIS**: reasoned but not confirmed live.
   - **UNVERIFIED**: the check failed, timed out or returned **nothing**. Empty is neither a pass nor proof of down.
   - Before calling anything down or missing, use a second independent source and name the check that would prove you wrong.
4b. **Engines** (subagents from `agents/`, allowed in the headless settings by name). Feed them tool output, never your
   own date math:
   - `anna-goals` with `anna-clock due`, `backlog-age`, a goal tool's status if the record has one (else `goal_status:
     none`), and `raised: none`. Its `mine_due` are Anna's own follow-ups: list them under Watch as "Anna's to do". The
     backlog is one line, `Backlog: <n> open items older than 14 d` (`backlog-age --min-days 14`), never the list: an
     entry's age isn't how long it sat untouched. No nudge from here.
   - `anna-curiosity` with the open "Ask the user" items (handoff lines, backlog) each with the date first noted and how
     often asked, `recent_answers` each with the question it answered (`anna-stream recent --hours 72`), `anna-rhythm`,
     and today's state. If it returns a question, add a last line `Question for today: <question> (why: <why>)`. Its
     `drop` entries go under Watch ("stop asking: …").
   - If either engine is refused or errors, say so under Could not verify and carry on.
5. **Output** one screen. First line, if `anna-body --line` works: `How I feel: <its output>`. That's Anna's felt summary
   of the same facts, not a check: never make a ⛔ or an item from it. Then `Needs action today` / `Watch` /
   `Done since last handoff` / `Could not verify`. For each item: its label, the thing it's about, one line of evidence, and a
   link to its runbook or its record in `<things>/`. Put the full commands and output below, ready for the journal.
   Mark an item ⛔ only if it needs the user **today** (something down, a failed backup, a security issue): a ⛔ under
   `## Needs action` in a headless run notifies them, so don't use it for routine to-dos. Start the item with `- ⛔`; on a clean day write "None." (anna-run alerts only on lines that start with ⛔).
6. Interactively: stop and ask what to take on first.
