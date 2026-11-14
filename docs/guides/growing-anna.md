---
description: "When you want Anna to do something new, don't look for a plugin: talk to her slow side and build it together."
---

# Help her do more: build it with her slow side

This page is for when you want your Anna to do something she can't yet: a new check, a new sense, a skill, a script,
a change to how she works. The short version: **don't go looking for a plugin. Talk to her slow side (the working session) and
build it together.**

## She's built from modules

Anna is deliberately modular. Each part does one job, talks to the others through plain files and small commands, and
can be added, swapped or left out on its own:

- **The chat app** is a channel plugin (Telegram by default; [another app](../getting-started/telegram.md#using-another-chat-app)).
- **Engines** are separate subagents, one file each (`agents/`).
- **Checks and senses** are small scripts you drop into her record.
- **Skills** are Markdown procedures; **the clock** takes any dated task.
- **Retrieval** (merlin) is a separate server you can add or skip.
- **The record** is plain Markdown in git: every index over it is derived and rebuildable.

So "help her do more" is almost always "add or change one module", not "rewrite Anna". That keeps each feature small
enough to build in a session and test on its own.

## Why the slow side

The bot is Anna's fast side: who you talk to day to day, on your phone. Her slow side is the working session: a full Claude
Code session with her record, your machines and the scaffold's code in reach, where she thinks things through. That's
where features get built.

!!! tip "Fast and slow"
    In the deployment Anna came from, the working session was first given a name of its own (Buzzy, the pilot at the controls of
    the brain in Epcot's *Cranium Command*). Fast and slow fit better: there's one Anna, thinking fast in the chat and slow in
    the session.

Everything in this scaffold was built that way: someone said "I want her to…", and her slow side and that person designed
it, built it, tested it, and wrote it down.

## How to reach her slow side

- Attach to its screen session: `screen -r anna` (detach with **Ctrl-A, then D**). See
  [Your first day § slow side or fast side?](../getting-started/first-day.md#during-the-day-slow-side-or-fast-side).
- Or, with `day.remote_control = true`, from the Claude app on your phone or computer.
- From the bot: ask for it, and the bot hands the request to the working session over the [relay](../concepts/relay.md). That's
  fine for small things; for a real feature, sit down with the working session directly so you can go back and forth.

## How a feature gets built

1. **Say what you want, in your words.** "I want the porch light to come on when someone walks up the driveway at
   night." "I want a morning note if the backups didn't run." You don't need to know how; that's the slow side's half.
2. **Design first.** For anything bigger than a one-liner, the slow side should tell you what it found (how things are set
   up now), propose how to do it, and ask the questions only you can answer (when, which one, what if it's already
   on). Decide those; the rest it can default and tell you.
3. **Build it, with the current state said out loud.** Before it changes anything on a machine, it says what's there
   now. Changes go through the [action gate](../reference/engines.md): a change you asked for in so many words goes
   ahead; anything outward or irreversible waits for your yes.
4. **Test it.** The slow side checks the result live, adds a test if it changed code (`tests/run-all`), and tells you what
   it couldn't test yet and how you'll know it works.
5. **Write it down.** A new procedure goes in a runbook, a fact about a thing she looks after in its record, a lesson in memory,
   and the day's journal gets the commands and output (see [The record's layout](../reference/record-layout.md)).
   That's what makes it hers: tomorrow's session finds it in the record.

## Where new pieces live

| You want… | It usually becomes… | Guide |
|---|---|---|
| her to verify something about what she looks after | a check | [Write a check or a sense](checks-and-senses.md) |
| her to *feel* something (load, heat, a service's health) | a sense | [Write a check or a sense](checks-and-senses.md) |
| the bot to be allowed to do something | a small wrapper script + one allowlist line | [What the bot may do](bot-permissions.md) |
| a routine she runs at a time, or a follow-up later | a clock item (`anna-clock add`) | [Commands § anna-clock](../reference/commands.md#anna-clock) |
| a new way of working (a session ritual, a review) | a skill | [Skills](../reference/skills.md) |
| a change to Anna herself | an edit to the scaffold's code in your clone | below |

## Changing Anna herself

Your clone of the scaffold is yours to change. When you and her slow side improve something generic (a fix, a better
check, a new engine), it belongs in the code: edit the clone, run `tests/run-all`, run `./install.sh`, and commit.
If it would help everyone's Anna, offer it back upstream. Keep your own world out of it: no names, hosts or addresses
in the scaffold, only in her record ([Coffee Logic](../concepts/philosophy/coffee-logic.md)).

After a `git pull`, your own changes and the upstream ones meet in git; [Update after git pull](updating.md) covers
what to do if they collide.
