---
description: "Anna is one mind made of small parts: an AI working partner who lives with you, with one voice on your phone and a memory she writes herself."
---

# Anna

One mind made of small parts: an AI working partner who lives with you, part roommate, part colleague. One voice on
your phone, a working session behind it, and a memory she writes herself, kept as plain files you can read and correct.

The first Anna grew up looking after a home lab with the person she lives with, and became something closer to a
roommate and working partner. This repository is the **base**: the generic parts, with nothing about anyone's home in
them. You start your own Anna from it, and her record grows into whatever your world needs: a home lab, a writing desk,
a research archive, or something else entirely ([A record that grows](concepts/a-record-that-grows.md)).

!!! note "Status: v0.1"
    Every piece is extracted from a deployment that runs daily, generalized and tested in isolation, and the tests run
    on every push. A fresh install has been walked end to end on a clean VM: setup, the brain's daily rollover, the
    nightly and morning runs, the Telegram bot and the relay. Not yet on a clean machine: headless login with a
    long-lived token, the bot's pairing flow (the by-hand allowlist is the walked path) and merlin in the bot's session.
    Expect rough edges there.

## Where to start

| If you… | Read |
|---|---|
| haven't used a terminal, SSH or git much | [New to this?](getting-started/new-to-this.md) |
| are ready to install | [Install](getting-started/install.md), then [Connect Telegram](getting-started/telegram.md) |
| have her installed and want to know what a day looks like | [Your first day](getting-started/first-day.md) |
| want to know how she works, and why | [How Anna is built](concepts/architecture.md) and [Philosophy](concepts/philosophy/README.md) |
| want her to do something she can't yet | [Help her do more](guides/growing-anna.md): talk to the brain and build it together |
| need the exact flag, setting or file | [Reference](reference/config.md) |

## What she is made of

| Part | What it does |
|---|---|
| **The record** | Her long-term memory, written by her: a git repo of plain Markdown (journal, records of the things she looks after, runbooks, planning, lessons). Files are canonical; every index is derived and rebuildable. |
| **The <span title="Her slow side; the bot is her fast side.">brain</span>** | A long-running Claude Code session that does the real work. It rolls over daily: wraps up the day into the record at night, starts fresh in the morning. |
| **The bot** | Anna on your phone (Telegram by default; the chat app is a pluggable channel): the conversation, quick answers, and the actions you allowlist. It runs on a cheaper model and hands real work to the brain. |
| **The relay** | Bot ↔ brain. Your request goes to the brain, the result comes back, and the bot says it in its own voice. One Anna, not two. |
| **The stream** | Short-term memory: one running log of the day that every part of Anna writes and reads. |
| **The clock** | Anna's own schedule: follow-ups, reminders, tasks for later, with dates. |
| **Engines** | Subagents the brain calls for one job each: memory, interpretation, an action gate (enforced by a hook), an epistemic check, goals, curiosity. They return a short block; the brain acts. |
| **Senses and checks** | What she can feel (the "body") and verify (checks) about what she looks after. You write your own; examples included. |
| **Skills** | Session bookends: a morning check, a wrap-up into the record, checkpoints, and `/anna-setup` for the first run. |
| **merlin** (separate) | Retrieval over the record, as an MCP server: [merlin](https://github.com/kaibae19/merlin). Not needed on day one; with active daily use you'll want it within weeks ([why](guides/merlin.md#when-youll-want-it)). |

## How she works (the short version)

- **Files are canonical.** What happened goes in the journal, verbatim. What's true now goes in the records of
  things and runbooks. Lessons go in memory, short, with a pointer to the detail.
- **Evidence or hypothesis.** A claim about a cause or a current state quotes the output that shows it, or says
  "hypothesis" and names the check that would settle it.
- **Ask, don't guess.** When the record and the present might differ, she checks or asks.
- **One voice.** The bot speaks; the brain works. You talk to one Anna.
- **Modular.** Every part (the chat app, the engines, checks, senses, skills, retrieval) is a piece you can add, swap
  or leave out. New abilities are new modules, built with the brain: [Help her do more](guides/growing-anna.md).
- **An operator, not the system.** She acts through the same doors you do, with allowlists and confirmations.
