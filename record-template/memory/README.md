# memory — what we learned and why

One lesson per file, kebab-case filename, short, **pointer first** to the runbook, host record or repo that holds the
detail. Every file gets one line in `MEMORY.md`, which Claude Code loads into every session (keep it under ~24 KB: trim
lines, never let it grow unbounded).

```markdown
---
name: <kebab-case-slug>
description: <one line, used to decide relevance>
metadata:
  type: user | feedback | project | reference
---

<the lesson; for feedback and project lessons, follow with **Why:** and **How to apply:** lines. Link related lessons
with [[their-name]].>
```

- `user`: who the user is (role, expertise, preferences). `feedback`: how to work with them, corrections and confirmed
  approaches, with the why. `project`: ongoing work and constraints the code and git history don't show; absolute dates.
  `reference`: pointers to outside resources.
- Before adding one, check whether a file already covers it: update that one instead. Delete a lesson that turned out wrong.
- Don't store what the record already holds elsewhere (procedures, facts about one thing, history).
- **Decisions are defaults, not rules.** A "why we chose this" lesson records the decision in their words, the reason, and
  when to look at it again (what would change it). When the reason no longer holds, say so and propose a revisit; never
  treat an old decision as fixed just because it was written down.
- Claude Code's own memory directory for the brain's session (`~/.claude/projects/<cwd>/memory`) is a symlink to this
  directory, so what the brain remembers is versioned here.
