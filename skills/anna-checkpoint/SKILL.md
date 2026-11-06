---
name: anna-checkpoint
description: Mid-session checkpoint — journal what this session did since the last checkpoint (verbatim output, from the session draft), refresh the handoff line, mark the draft folded so the evening fold doesn't repeat it, commit and push. The session stays open. Use when the user says checkpoint, "save our progress", or "journal what we have so far"; anna-idle-checkpoint asks for it after a quiet spell.
---

# Checkpoint (the session stays open)

A short `/anna-wrapup` that doesn't end anything. On a long day it keeps the journal close to what happened, in pieces.
The record is at `anna-config paths.record`. Read `journal/README.md` and the `/anna-wrapup` skill's step 2 first.

1. **Refresh the draft:** `anna-session-draft --scan 24`, then read this session's draft
   `<paths.state>/drafts/<session id>.md`. It holds only what wasn't folded yet, so it starts where the last checkpoint
   ended. Other unfolded drafts from today (a session that ended without a wrap-up): fold them too, oldest first, as their
   own session blocks.
2. **Journal** (day = the day the session **started**): first checkpoint → `## YYYY-MM-DD (session N) — … · checkpoint
   in-session (<sid[:8]>; session stays open, later work appends)`. Later ones → `## YYYY-MM-DD (session N, continued
   after checkpoint K) — …`. Headline, Day index (⛔/⚠), one `###` per topic with `Did:` / `Hit:` / `Decided:` / `Open:`.
   **Copy commands and output verbatim from the draft** (trimmed to the evidence lines, never paraphrased); the user's
   decisions in their words. Never copy `[REDACTED]`, credentials or vault output. Work done by subagents: the result they
   reported plus what you verified yourself, marked as such.
3. **Other layers**: usually done already (commit as you go). Add only what's missing: a host fact, a runbook step, a
   memory lesson (pointer first, plus the MEMORY.md line), a backlog item, or a dated follow-up on `anna-clock`.
4. **Handoff:** update the 📌 line at the top of `memory/MEMORY.md`: session id, `checkpoint N`, what's live, what's
   mid-flight, **Ask**. Keep the older lines' open items unless shown done.
5. **Mark folded:** `anna-session-draft --mark-folded <draft path>…` for every draft you journaled.
6. **Commit:** `git add` the files you changed; scan `git diff --cached | grep -nEi 'token|passw|secret|api[_-]?key|BEGIN
   .*PRIVATE'` and read it; commit `YYYY-MM-DD checkpoint N: <topics>`; push if the record has a remote.
7. **Don't** end the session. Report in 3–5 lines: the commit, the journal § heading, anything skipped.
