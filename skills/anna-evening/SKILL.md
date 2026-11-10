---
name: anna-evening
description: Headless evening fold — fold the day's interactive-session drafts and Anna's stream into the journal, propose (not make) record updates, refresh the handoff line, commit and push. Use only when invoked as /anna-evening (by the anna-evening script).
---

# Evening fold (headless): Anna's sleep

The record is the cwd. Journal format: `journal/README.md` and the `/anna-wrapup` skill (read both first). Drafts are raw,
redacted transcript extracts written by `anna-session-draft`, one per session, in `<paths.state>/drafts/`. Each starts with
front matter: `session`, `day`, `started`/`ended`, `transcript_lines`, `wrapped_up_in_session`. A draft covers only the lines
after the last fold, so a session can show up again on a later evening.

**Shell (headless):** one simple allowlisted command per Bash call. Compound commands (`cd …;`, loops, `;` chains) are
refused **per command**, not Bash as a whole: split them and carry on. Use `grep` via Bash if there's no Grep tool.

1. The drafts are the paths given after `/anna-evening`. A `STREAM: <path>` argument names a day of **Anna's stream**
   (`<paths.state>/stream/YYYY-MM-DD.jsonl`). No drafts and no stream: write "no drafts", the final line `FOLDED:` (empty),
   and stop.
1b. **Stream:** read the stream file (`cat`). It's the day across all of Anna: bot exchanges (`[bot] <user>: …` /
   `Anna: …`), the main session's lines (`[session]`, already covered by the drafts: skip those), notifications
   (`… → Telegram`), clock items, relay hand-offs, headless runs. Append to that day's journal file a
   `## The bot and the day (Anna's stream)` section: what the user said, asked, decided or reported through the bot (their
   words verbatim where they matter), actions the bot took, clock items fired, alerts sent, relay hand-offs and their
   results, any `for the brain` line with whether it was picked up. Skip small talk with nothing to keep. If a stream line
   contradicts the record, list it under Proposed. The bot's sessions are never drafted (`anna-session-draft` skips
   `~/anna-<instance>`), so this section is the bot's only record of the day: don't leave out a bot exchange that matters
   because "a draft will cover it".
2. For each draft, oldest `started` first:
   - **Day file** = `journal/YYYY/MM/<draft day>.md`. Read it (it may not exist yet).
   - `wrapped_up_in_session: true` means it was already journaled. Add only what the day file clearly lacks (e.g. work after
     the wrap-up). Usually that's nothing.
   - Otherwise append `## YYYY-MM-DD (session N, folded by the evening run from <session[:8]>, not reviewed)`, following
     `/anna-wrapup` step 2. **Copy commands and output verbatim from the draft; never reconstruct or paraphrase output.**
     If the day file doesn't exist, create it: its first line is that `## …` block heading (no `#` title line).
   - Never copy anything `[REDACTED]`, credentials, vault output, account names or email addresses. If a draft looks like
     it holds a secret the redactor missed, leave that part out and flag it under ⚠.
3. **Don't edit the records of things (the folder of things, `record.things`, default `hosts/`), runbooks, memory
   lessons or the backlog** unattended. List proposed updates under
   **Proposed for the next session** (file, change, evidence line), so a reviewed session can apply them.
   **Read `self/proposals.md` first** (the standing list, `anna-proposals`): don't propose again what's already there,
   whatever its status. New evidence for an open one → one line `- **still open:** <p-id> — <the new evidence>` (the
   tool notes it on that item). A `declined` one stays declined unless the person's own words reopen it.
3b. **Memory consolidation:** for each memory whose topic shows up in what you folded, compare the memory file and its
   MEMORY.md line with what the drafts and the journal say. Flag claims that are contradicted, transient ("currently",
   "for now", "pending") but resolved, or duplicated. Propose fixes under **Proposed → memory**.
4. **Handoff:** if a folded session left something mid-flight, update the 📌 line at the top of `memory/MEMORY.md`. Keep
   items that aren't shown done, add new ones, and append `(evening run <date>)`. Otherwise leave it alone.
5. **Commit:** `git add` only the files you changed. Scan `git diff --cached | grep -nEi 'token|passw|secret|api[_-]?key|BEGIN
   .*PRIVATE'` and read the output. Commit `evening fold <date> (<n> sessions)`; `git push` if there's a remote.
6. **Output:** what you folded where (file § heading), Proposed for the next session, ⚠ anything odd. Then a last line,
   exactly `FOLDED: <path> <path> …` listing the drafts you fully handled (wrapped-up drafts with nothing to add included)
   and the `STREAM:` path if you folded it. A draft you couldn't handle stays off that line and is retried tomorrow.
