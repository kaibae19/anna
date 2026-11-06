---
name: anna-wrapup
description: End-of-session wrap-up — write or append the day's journal entry with verbatim output, update host records / runbooks / memory / backlog per the record's layer rules, refresh the handoff line, and commit. Use when the user says to wrap up, document the day, or close out a session; anna-day close types "/anna-wrapup overnight" into an idle brain at night.
---

# Wrap-up

The record is at `anna-config paths.record`. Layer rules are in its `CLAUDE.md` ("Where a new thing goes"); the journal
format is in `journal/README.md`. Read both first.

**Overnight mode** (`/anna-wrapup overnight`, typed in by `anna-day close` when the session has been idle; the user is
asleep): don't ask anything and don't wait for answers. Where a step would ask, take the conservative choice (leave the
record as it is) and put the question in the 📌 handoff line under **Ask**. Push at the end if the record has a remote
(the evening fold and the morning check read it). Keep the reply short; it goes to Anna's stream, not to the user.

1. **Day file** = `journal/YYYY/MM/<day the session STARTED, in anna.timezone>.md`. If it exists, **append** a
   `## YYYY-MM-DD (session N) — …` block. Never rewrite an earlier session's block.
2. **Journal entry:** a headline and a **Day index** (one line per topic, with ⛔/⚠ markers), then one `###` per topic with
   `Did:` / `Hit:` / `Decided:` / `Open:`. **Paste the verbatim commands and output** from this session, trimmed to the lines
   that carry evidence; never summarize output. The user's decisions in their words. Cover everything touched, routine
   work included. Start from the session draft if there is one (`anna-session-draft --scan 24`, then
   `<paths.state>/drafts/<session id>.md`): it has the commands and output.
3. **Other layers**, only where this session produced something:
   - A procedure → `runbooks/<topic>/`. A host fact → `hosts/<host>.md` `## Notes`.
   - A lesson → `memory/`: short, pointer first, and a line in `memory/MEMORY.md`.
   - A task → `planning/backlog.md`; an idea → `planning/ideas.md`; a follow-up with a date → `anna-clock add`.
   - Trim any memory whose topic was touched this session (judge while the context is fresh; never bulk-trim).
   - A section that went stale gets `(superseded YYYY-MM-DD: see § X)` as its first line.
   - If you keep a retrieval log (lookups that took more than one try: the question, where the answer was, the better
     path), add this session's entries now, while you still remember the wrong turns.
3b. **Engines:** `anna-goals` with `anna-clock due`, `backlog-age`, a goal tool's status if the record has one (else
   `goal_status: none`) and what the user raised this session; its `mine_due` go into the handoff as Anna's to-dos. Then
   `anna-curiosity` with the open questions for the user, `anna-rhythm` and recent answers (`anna-stream recent --hours
   72`). Feed them tool output, never your own date math. Interactively, a question it returns may be asked now (log it:
   `anna-stream add --from curiosity "<question>"`); overnight, it goes under **Ask** in the handoff instead.
4. **Handoff:** update the 📌 line at the top of `memory/MEMORY.md`: what's live, what's mid-flight, what's next,
   **Ask** (questions for the user). If nothing is mid-flight, say so on that line.
5. **Mark folded:** `anna-session-draft --mark-folded <draft>` for the drafts you journaled, so the evening fold doesn't
   repeat them.
6. **Commit** one commit for the session's record changes. Before committing, scan the diff for secrets
   (`git diff --cached | grep -nEi 'token|passw|secret|api[_-]?key|BEGIN .*PRIVATE'`) and read the full output. Never commit
   a credential: point to where it lives instead. Confirm with `git log -1 --oneline`. Push if the user says so
   (overnight mode: always, if there's a remote).
7. If your setup unlocked a password manager for the session, lock it now and report its output.
8. **Report:** the files changed and the commit, plus anything skipped and why.
