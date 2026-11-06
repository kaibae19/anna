# Journal — what we actually did and saw

One file per day: `YYYY/MM/YYYY-MM-DD.md`, named for the day the session **started** (in `anna.timezone`). Every session
writes its own `## YYYY-MM-DD (session N) — …` block, the first one included (no `#` title line); a later session or
checkpoint appends another. Never rewrite an earlier block.

```
## 2026-10-02 (session 1) — <headline: the 3–5 biggest things, separated by " · ">

**Day index:**
 1. <one line per topic, hosts by name, ⛔/⚠ if something broke>

### <topic>
Did: …
Hit: … (verbatim command + output, trimmed to the lines that carry evidence)
Decided: … (and what we rejected)
Open: … (and where it's tracked)
```

- **One `###` per topic.** Sections are the unit a search index embeds.
- Name hosts by their record name (`nas`, not "the storage box"), so a search can tag them.
- **Paste real output, never a summary of output.** Conclusions go in memory, runbooks or host records; the journal holds
  the raw material.
- `journal/handoffs/` holds the headless runs' reports (`<date>-morning.md`, `<date>-evening.md`, `<date>-clock-<id>.md`).
