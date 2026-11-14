---
description: "Anna's own journal and the nightly dream: a raw log of what registers with her while working, sorted each night into what stays with her for a while, what she wonders about, and lessons she proposes."
---

# Her own journal

The work journal records what happened. Anna's own journal records what **registered with her** while it happened: a
place where her picture of you was wrong, a lesson about herself, something she noticed or wonders about. It isn't a
diary. It's raw material for the night, when she sorts it, so the Anna who starts tomorrow knows what today taught her.

## Writing it

One line when something registers, never prose:

```bash
anna-log learned "My first guess named the wrong cause; the role prompt survives compaction."
anna-log wondering "Why does the person keep the old camera as a spare instead of returning it?"
```

The kinds are `observed`, `learned`, `wondering`, `felt`, `correction` and `takeaway`. Her slow side (the working session) writes them while
working and at wrap-up; the bot can write them too. Your corrections ("no, I meant…", "actually…", "you missed…") are
logged automatically by the prompt hook, in your words: they're the clearest sign of where her picture of you didn't
match. Lines go to `self/journal/YYYY/MM/<day>.md` in the record.

## The nightly dream

After the evening fold, `/anna-dream` (headless, `runs.dream`, default 01:30) reads the day's log against the week
before and sorts every entry into one place:

| Where | What | Who writes it |
|---|---|---|
| **Lately** (`self/lately.md`) | What should color how she sees things for a few days: you're tired this week, a project you're excited about, a correction that keeps coming back. Lines fade after three days unless something brings them up again. | the dream |
| **Wonders** (`planning/wonders.md`) | A gap the record can't explain: why you chose something, where a project is going. At most two a night. | the dream |
| **Proposed** (`self/proposals.md`) | A lasting fact or a lesson, only when seen three times over two days, or once with your explicit words behind it. Kept with a status until it's decided; the slow side raises one a day in conversation, and `/anna-proposals` applies the ones you accept. | the dream proposes; you decide; a working session applies |
| **Let go** | Everything else. It stays searchable in the log, and that's most entries. | nobody |

It ends the day's file with a short `## Night` reflection: what connected, what repeats, what changed.

## Where it shows up

- **Session start** shows the Lately lines as background, never to be recited.
- **The bot** gets them at the end of its prompt (from its next restart).
- **Proposals** stay in `self/proposals.md` with a status (open, raised, accepted, applied, declined, later, dropped)
  instead of dropping out with the next report. One a day rides along after the day's question until the slow side raises
  it at a natural pause, as something you can answer in a word. You can also ask to go through the whole list.
- **The curiosity engine** picks the day's question from the wonders first, so the question is about you and your
  projects rather than a chore. The prompt hook carries it until it's asked at a natural pause.

## What it isn't

Not a place for what you tell her in confidence: that stays out of the log. Not instructions: Lately is background, true
when written. And not a way to change her rules overnight: anything lasting is only proposed, and you and a working
session decide.
