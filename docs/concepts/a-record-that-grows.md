---
description: "How Anna's record starts small and grows from the work you do together: things, checks, runbooks, history, and names that last."
---

# A record that grows

Anna doesn't arrive knowing what your life or work looks like, and the scaffold doesn't pretend to. It gives her a small
core and a few ideas that work in any domain. The rest of her record grows out of the work you do together. This page
explains those ideas, how the growing happens, and how to tell the template apart from what one Anna grew into.

## The core every Anna starts with

The [record template](../reference/record-layout.md) is deliberately small:

- **journal/**: what happened, one file per day, written as it happens.
- **memory/**: short lessons, one per file, with an index she reads at the start of every session.
- **planning/**: a backlog and an ideas list.
- **clock/**: her own schedule of dated follow-ups.
- **checks/** and **senses/**: small scripts that look at something on a schedule.
- **bot/context/**: what the phone voice knows without looking it up.
- **hosts/** and **runbooks/**: the first two folders for *things* and *how-tos* (below). They start empty.

## Ideas that travel

These words came from looking after a home lab, but each one is a general idea. Define it for your world and it works
there too.

| Idea | What it means | In a home lab | Somewhere else |
|---|---|---|---|
| **A thing** | Something Anna keeps a record of: what it is now, how to reach it, dated notes. One file per thing. | a server, a router, a camera | a chapter, a source, a client, a plant, a recipe |
| **The things she looks after** | The set of like things she keeps an eye on. In a home lab we call it the *fleet*. | every machine on the network | every chapter of the book, every client this month |
| **A check** | A small, repeatable look at those things, on a schedule. | "are the backups fresh, are the disks healthy?" | "which chapters haven't moved in a week?", "which plants are due for water?" |
| **A runbook** | A repeatable how-to, written down once you've done it twice. | "update the router", "restore a backup" | "send the monthly invoice", "submit a chapter to the editor" |
| **History of a thing** | Everything the journal says about one thing, in date order. | "what have we already tried on the printer?" | "what did the editor say about chapter 3?" |

The folder for things is named in Anna's config: `record.things` (default `hosts`) names the folder, and `record.thing`
(default `host`) is the front-matter key in each file. `/anna-setup` asks what she'll help with and suggests a name; the
memory and action engines read whatever you chose.

## How the record grows

Structure appears when the work asks for it, not before. And so does content: Anna learns the way a roommate does,
from what comes up, over time. She never asks for a complete inventory; the record fills in as you go. If you *want* her
to be your librarian (a whole record collection to catalog, a bibliography, a client list), hand it over and she takes it
as given. The rule: never require an intake, accept one when it's offered.

When a new kind of thing keeps coming up, this is how it gets its place:

1. **Notice a pattern.** When the journal keeps coming back to the same kind of thing (the same machines, the same
   chapters, the same clients), that kind deserves its own records.
2. **Propose, then agree.** Anna suggests a folder for it and what each file should hold. You decide.
3. **Write the rules down.** The new folder gets a one-page `README.md`: what goes in it, how files are named, which
   front matter fields matter.
4. **Tell the search.** If you use [merlin](../guides/merlin.md), add the folder to its layout so search and history
   know about it.
5. **Note why.** A line in the journal (and a lesson in `memory/` if it was a real decision) says what was added and why,
   so the next person, or the next Anna, can follow the reasoning.

**Names that last.** Name a folder or file after the stable thing (a room, a project, a client), not a nickname or a
mood: rooms and projects change rarely, gear and nicknames more often. Keep nicknames as aliases in the file's first
lines ("also called: …"), so search finds either name. Keep it shallow: one file per thing, and split part of it into
its own page only when that part earns it (it has a history of its own). Each folder's README says what goes where and
keeps a short, dated moves log, so a rename stays traceable.

Nothing here is final, and moving things later is cheap: the files are the record and the search index is rebuilt from
them. A folder that stops earning its keep can be merged or retired the same way.

## The template and one Anna's record

There are always two different things:

- **The scaffold** is what a *new* Anna starts with. It changes slowly and stays generic.
- **Your Anna's record** is hers. It grows its own folders, checks and how-tos, and it doesn't change when the scaffold
  does. Improvements flow from a living record back into the scaffold, generalized, never the other way round by
  accident.

The examples in these docs mostly come from one Anna who grew up looking after a home lab with the person she lives with:
host records, fleet checks, runbooks for updates and restores. That's what *she* grew into. Yours might grow into a
writing desk, a research archive, or something nobody has thought of yet.
