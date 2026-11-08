---
description: "Anna's record folder by folder: what goes where, how files are named, and the conventions its CLAUDE.md sets."
---

# The record's layout

This page goes through the record folder by folder: what goes where, how files are named, and the conventions the
record's own `CLAUDE.md` sets. It's for anyone who opens the record and wants to find their way around, and for developers
writing a skill that reads or writes it. For how to read and correct it day to day, see
[Read and correct the record](../guides/the-record.md).

!!! tip "New to this?"
    **The record** is a folder of plain Markdown files kept in git. It's Anna's long-term memory. You can open any file
    in a text editor. git keeps every earlier version, so nothing written there is ever really lost.

## Where it is and how it starts

The record lives at `paths.record` (default `~/anna-record`). The first `./install.sh` copies the scaffold's
`record-template/` there, renames the folder of things to `record.things` (the default, `hosts/`, keeps its name), fills `@NAME@`,
`@USER@`, `@TZ@`, `@RECORD@`, `@THINGS@` and `@THING@` in `CLAUDE.md`, `memory/MEMORY.md` and that folder's `README.md`
and `_template.md`, runs `git init -b main` and makes the first commit, `record: start from the Anna template`. After that, `install.sh` never
touches it again (`record exists at … (left as is)`).

`install.sh` also links Claude Code's memory folder for the brain's home directory
(`~/.claude/projects/<your home path, every character that isn't a letter or digit replaced by ->/memory`, for example
`~/.claude/projects/-home-you/memory`) to `<record>/memory`, so what the brain remembers is
versioned in the record.

## Folders

```
<record>/
├── CLAUDE.md            how Anna and you work; where a new thing goes; things at a glance
├── bot/context/         what the bot knows by heart (appended to its prompt)
├── checks/              your anna-checks sections (executables)
├── clock/               Anna's own schedule, one file per month
├── hosts/               the folder of things: one file per thing she keeps a record of
├── journal/
│   ├── YYYY/MM/         one file per day
│   └── handoffs/        reports from the headless runs
├── memory/              lessons, one per file, plus the MEMORY.md index
├── planning/            backlog.md and ideas.md
├── runbooks/            how to do things, one folder per topic
└── senses/              your anna-body senses (executables)
```

Each folder in the template has a `README.md` with its own rules. They're summarized here.

### CLAUDE.md

Read first in every session. It has four parts:

- **How we work:** design first for non-trivial changes; never conclude a negative from one check; evidence or
  "hypothesis"; say the current state, read live, before a state change; two failed fixes, then stop; one thing at a time;
  back up a config as `*.bak.<date>` before editing it; `set -o pipefail`; secrets never on a command line, in the record
  or in a chat; commit when asked or as the skills say.
- **Where a new thing goes** (the layer rules, below).
- **Session bookends:** `/anna-morning`, `/anna-wrapup`, `/anna-checkpoint` ([Skills](skills.md)).
- **Things at a glance:** a table of the things she keeps a record of (name, optional address, what it is). `/anna-setup`
  starts it.

### Where a new thing goes

| What | Where |
|---|---|
| What was done, with the raw output | `journal/YYYY/MM/YYYY-MM-DD.md` |
| A fact about one thing she looks after | `<things>/<name>.md`, under `## Notes` (the folder named by `record.things`, default `hosts/`) |
| A procedure, a config file, a script | `runbooks/<topic>/` |
| A lesson, a gotcha, a "why we chose this" | `memory/<slug>.md`, pointer first, plus a line in `memory/MEMORY.md` |
| A task | `planning/backlog.md` (newest at the top, dated) |
| An idea | `planning/ideas.md` |
| A follow-up with a date | `anna-clock add` (lands in `clock/`) |
| A check Anna should run | `checks/<name>` |
| Something Anna should feel | `senses/<name>` |
| What the bot should know without looking it up | `bot/context/` |
| A changelog or deploy history | nowhere: git has it |

### journal/

**Day files:** `journal/YYYY/MM/YYYY-MM-DD.md`, named for the day the session **started**, in `anna.timezone`. A session
that runs past midnight stays in the day it started.

Every session writes its own `## ` block, the first one included; there's no `#` title line. Later sessions and
checkpoints append another block. An earlier block is never rewritten.

```markdown
## 2026-10-02 (session 1) — <headline: the 3–5 biggest things, separated by " · ">

**Day index:**
 1. <one line per topic, things by name, ⛔/⚠ if something broke>

### <topic>
Did: …
Hit: … (verbatim command + output, trimmed to the lines that carry evidence)
Decided: … (and what we rejected)
Open: … (and where it's tracked)
```

Block headings you'll also see:

| Heading | Written by |
|---|---|
| `## YYYY-MM-DD (session N) — … · checkpoint in-session (<id>; session stays open, later work appends)` | the first `/anna-checkpoint` of a session |
| `## YYYY-MM-DD (session N, continued after checkpoint K) — …` | later checkpoints |
| `## YYYY-MM-DD (session N, folded by the evening run from <id>, not reviewed)` | `/anna-evening`, for a session nobody wrapped up |
| `## The bot and the day (Anna's stream)` | `/anna-evening`, from the day's stream |

Conventions: one `###` per topic (a search index embeds sections); name things by their record name; paste real output,
never a summary of it. Conclusions belong in memory, runbooks or the records of things.

**`journal/handoffs/`:** reports from headless runs, written by `anna-run` as `<date>-<label>.md`:
`<date>-morning.md`, `<date>-evening.md`, `<date>-clock-<id>.md`. The first line of each records the host, time, prompt
and exit code. The template keeps the folder with a `.gitkeep`.

### hosts/

`<things>/<name>.md` (default `hosts/<name>.md`): one file per *thing* Anna keeps a record of. In a home lab that's a machine or device; elsewhere it
might be a chapter, a source, a client or a plant ([A record that grows](../concepts/a-record-that-grows.md)). Each file
says what the thing is, how to reach it if that applies (no secrets), what matters about it, and `## Notes` with dated
facts, newest first. The folder's name comes from `record.things` (default `hosts`) and the key from `record.thing`
(default `host`); the engines read whatever you chose. Use the same name everywhere (journal, checks, senses) so a search ties them together. A thing's file
holds current practice; the history of how it got that way stays in the journal.

New files start from `<things>/_template.md`, whose front matter names the thing and its other names. With the default
layout (`hosts/`, key `host:`), a machine:

```markdown
---
host: nas
aliases: [storage, nas.home.arpa]
ips: [192.0.2.20]
---
```

A writer's record with `things = "chapters"` and `thing = "chapter"`, `chapters/three.md`:

```markdown
---
chapter: three
aliases: [the lighthouse chapter, ch3]
---
```

merlin reads this to tie mentions in the journal back to the thing. Without it, `history` finds nothing for it. Point
merlin's layout at your folder: its `[entities]` `name`, `types` and `key` take `record.thing`, and the layer glob
takes `record.things` (the merlin guide shows the Anna layout).

### runbooks/

`runbooks/<topic>/README.md` plus any scripts or config files it needs. A runbook says how to do it now. When a section
goes stale, its first line becomes `(superseded YYYY-MM-DD: see § X)` rather than the section being deleted.

### memory/

One lesson per file, kebab-case filename, short, **pointer first** to the runbook, thing's record or repo that holds the
detail. Each file has front matter:

```markdown
---
name: <kebab-case-slug>
description: <one line, used to decide relevance>
metadata:
  type: user | feedback | project | reference
---

<the lesson; for feedback and project lessons, follow with **Why:** and **How to apply:** lines.
Link related lessons with [[their-name]].>
```

| Type | For |
|---|---|
| `user` | who you are: role, expertise, preferences |
| `feedback` | how to work with you: corrections and confirmed approaches, with the why |
| `project` | ongoing work and constraints the code and history don't show, with absolute dates |
| `reference` | pointers to outside resources |

**`memory/MEMORY.md`** is the index: one line per lesson file. Claude Code loads it into every brain session, so keep it
under about 24 KB. Its first line is the **📌 Handoff** line: what's live, what's mid-flight, what's next, and **Ask**
(questions for you). The wrap-up, checkpoints and (when something is mid-flight) the evening fold update it.

Before adding a lesson, update an existing file that already covers it. Delete a lesson that turned out wrong. Don't store
what the record holds elsewhere.

### planning/

- `backlog.md`: newest at the top, `- **(YYYY-MM-DD) title:** what, why, where it stands.` Done items get ✅ and a pointer.
- `ideas.md`: things worth doing someday, dated, with who suggested them and why.

### clock/

Anna's own schedule (not your calendar), managed with `anna-clock`. One file per due month, `clock/YYYY-MM.md`, one line
per item:

```
- [ ] 2026-10-21 09:00 ping #a3f2 text (added 2026-10-18 by session)
```

Time `--:--` means date only. States: `[ ]` open, `[x]` done or fired, `[-]` cancelled. Kinds: `note` (shows in the
morning check until done), `ping` (a message to you at that time), `run` (a headless run does the text as a task). Every
change commits just its month file. A task with no date stays in the backlog. Full command list:
[Commands](commands.md).

### checks/ and senses/

Executables you write. Each file in `checks/` is an `anna-checks` section named after the file; each file in `senses/` is
an `anna-body` sense. Contracts and examples: [Write a check or a sense](../guides/checks-and-senses.md).

### bot/context/

Every file here except `README*` is appended to the bot's prompt at launch, each as its own section with the file name as
the heading: rooms and devices, names you use for things, sensors worth reading, wrappers the bot may call. Keep it short
and factual: names and ids, not states (states are read live). Restart the bot after a change:

```bash
systemctl --user restart anna-tg@<instance>
```

To see the prompt the bot gets: `anna-tg <instance> --print-prompt`.

## What isn't in the record

Some of Anna's files live outside the record on purpose:

| Path | What |
|---|---|
| `<paths.state>/stream/` | the stream, one `YYYY-MM-DD.jsonl` per day (folded into the journal at night) |
| `<paths.state>/drafts/` | raw session drafts, never committed or indexed |
| `<paths.state>/folded.json`, `folded/` | which transcript lines are already journaled; drafts after folding |
| `<paths.state>/gate-off` | the gate override file, if you created it |
| `<paths.secrets>/` | tokens, mode 700 |
| `~/.config/anna/anna.toml` | your config |

The defaults are `paths.state = ~/.local/state/anna` and `paths.secrets = ~/.config/anna/secrets`
([Configuration](config.md)).
