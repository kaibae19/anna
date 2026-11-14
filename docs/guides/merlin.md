---
description: "What merlin, Anna's memory search, adds; what the scaffold expects from it; and when to add it as the record grows."
---

# Add merlin

This guide explains what merlin adds to Anna, what the scaffold expects from it, and where its setup lives.

Anna starts fine without it: on day one the record is a handful of files and `grep` finds everything. **Plan on adding
it soon, though.** With daily conversations and a few projects going, the record grows faster than you'd think, and
recall is the first thing to suffer.

## When you'll want it

The record only grows: every day adds a journal entry with real command output, and every project adds runbooks,
notes on things and lessons. In the deployment Anna came from, with daily use and several projects at once, the journal
passed a megabyte in about five weeks, next to 80-odd lessons. At that size, searching by literal words stops working
well. These are the signs:

- she answers "I mentioned before…" or "when did we…" by guessing, or needs several tries to find it;
- a search for a word pulls up pages of unrelated days;
- she misses something because you described it in different words than the record does;
- the always-loaded lessons index (`memory/MEMORY.md`) is getting long because it's doing the job of a search.

When you notice the first of these, add merlin. It's easier while the record is still small enough to check that the
index finds what you expect.

!!! tip "New to this?"
    **merlin** is a search engine for her record. It reads the Markdown files, builds an index, and answers questions
    like "when did we last change the backup schedule?" with the sections that match. It plugs into Claude Code as an
    **MCP server**: a small program that gives Claude Code extra tools, here tools named `search`, `history` and so on.
    The files stay the truth: the index is built from them and can always be rebuilt.

## What it adds

| Without merlin | With merlin |
|---|---|
| The memory engine reads `memory/MEMORY.md`, greps the record for literal words and reads matching journal days. | It searches an index of the whole record, by meaning as well as words, with dates and document types. |
| The action gate reads the thing's record (`<record.things>/<name>.md`) before a reboot or restart. | It can also ask for that thing's history across the journal (`history`). |
| The morning check has no index to report on. | It reports whether the index is fresh (`index_status`). |
| Drafts and the stream are redacted with the built-in patterns. | They can use merlin's redaction patterns. |

## It's a separate project

merlin has its own repository, its own install and its own documentation: <https://github.com/kaibae19/merlin>. The
scaffold doesn't install it, start it or index her record. This page covers only what the Anna scaffold does with it.

To set it up, follow merlin's [quick start](https://github.com/kaibae19/merlin#quick-start): Docker Compose runs the
database, the embedder and merlin on one machine, and you keep the index fresh with a timer. In its `.env`:

```bash
RECORD_DIR=/home/you/anna-record          # the output of: anna-config paths.record
MERLIN_TOML=../examples/anna/merlin.toml  # the layout made for an Anna record
```

The [Anna layout](https://github.com/kaibae19/merlin/tree/main/examples/anna) knows the record's folders. Its one
requirement: every `<things>/<name>.md` (the folder named by `record.things`, default `hosts/`) starts with front
matter naming the thing (new ones get it from `<things>/_template.md`; see [The record's layout](../reference/record-layout.md#hosts)). A first index of a new record
takes a few minutes; merlin only indexes committed files, which the wrap-up takes care of.

## What the scaffold expects

### An MCP server named `merlin`

Anna refers to merlin's tools by name, `mcp__merlin__<tool>`, so the server must be registered in Claude Code under the
name **`merlin`**. The tools the scaffold uses:

| Tool | Used by |
|---|---|
| `search` | `anna-memory`, `anna-action-gate` (standing permissions in memory lessons) |
| `history` | `anna-memory` (`mode: history`), `anna-action-gate` (what depends on a thing before a reboot or restart) |
| `host_history` | the same, in older merlin versions (the engines accept either) |
| `get_document` | `anna-memory` (reads the hit it quotes) |
| `list_documents` | `anna-memory` |
| `index_status` | `anna-memory` (once per question), `/anna-morning` |

### Visible to every part of Anna

The permission files already allow merlin, so nothing needs editing once the server is registered:

| Part | Settings file | Entry |
|---|---|---|
| headless runs (morning, evening, clock) | `~/.claude/anna-headless-settings.json` | `mcp__merlin__*` |
| the bot | `~/.claude/anna-tg-<instance>-settings.json` | `mcp__merlin__*` |
| the working session | runs with permissions off | (no entry needed) |
| the engines | their `tools:` line in `agents/anna-memory.md` and `agents/anna-action-gate.md` | listed by name |

So the server has to be available to the working session, to `claude -p` runs started by `anna-run`, and to the bot's
session in `~/anna-<instance>`. Registering it at Claude Code's **user** scope does that, since all three run as the same
user from different directories.

Register it at user scope (merlin's README, [Connecting Claude Code](https://github.com/kaibae19/merlin#connecting-claude-code)):

```bash
claude mcp add --scope user merlin -- \
  docker compose -f ~/merlin/deploy/compose.yaml run --rm -T app python -m merlin.mcp_server
```

!!! note
    The bot's settings set `"disableClaudeAiConnectors": true`, which turns off claude.ai connectors in the bot's
    session. A merlin server you register yourself in Claude Code isn't a claude.ai connector.
    <!-- TODO: verify on a clean machine that a user-scope merlin server loads in the bot session with that setting. -->

### Pointed at her record

merlin indexes the folder at `paths.record`. Print it with:

```bash
anna-config paths.record
```

The record's conventions are written with an index in mind: one `###` per topic in the journal (a section is what gets
embedded), things named the same everywhere, stale runbook sections marked `(superseded YYYY-MM-DD: see § X)` as their
first line rather than deleted ([The record's layout](../reference/record-layout.md)).

### Optional: merlin's redaction

`bin/anna_cfg.py` tries `from merlin.redact import redact`. If that works, the stream and the session drafts are redacted
with merlin's patterns; if not, with the built-in ones. It works when merlin is installed as a Python package Anna's
scripts can import, or when the environment variable `MERLIN_PATH` points at a merlin checkout. The scaffold doesn't set
`MERLIN_PATH` anywhere: the hooks run in Claude Code's environment and the timers in systemd's, so set it where both see
it if you use it.

<!-- TODO: verify the recommended way to make merlin.redact importable for both the hooks and the systemd user units. -->

## Check that it works

In the working session, ask a question about something you know is in the record:

```
When did we set up the backup check?
```

The session should hand it to `anna-memory`, and the returned block should say `index: fresh` (merlin answered) rather than
`index: files (no index)` (merlin wasn't available, so it read the files).

The next morning report should also say whether the index is fresh.

## Without merlin

Nothing breaks. `anna-memory` reads the files, `anna-action-gate` reads the records of things, the morning check skips the index
line, and redaction uses the built-in patterns. `/anna-setup` suggests adding merlin later, once the record has grown.
