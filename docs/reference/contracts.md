---
description: "The versioned contract (v1) for each engine's input and output block and for the record's layout, and the anna-contract tool that checks them."
---

# Contracts (v1)

This page is the versioned contract for the parts of Anna that a later build has to keep: each engine's input fields
and the block it returns, and the record's layout. It lives in one file, `contracts/v1.json`, and the
[`anna-contract`](commands.md#anna-contract) tool checks things against it. It's for developers: anyone changing an
engine, porting Anna to another harness or model, or writing a tool that reads her blocks or her record.

!!! tip "New to this?"
    A **contract** is a written promise about shape: "this engine always answers with these lines, and `verdict` is
    always one of these three words." Code that reads the answer can rely on it, and a new version of an engine (or the
    same engine on another model) can be tested against it.

## Why a contract

The engines' prompts have only ever run on one model family, and the record has only been read by Claude Code. Writing
the shapes down, with a version number, turns "it should port" into something that can be checked: a block either has
the keys and values the contract names or it doesn't. The [senses](../concepts/senses.md) use the same idea (contract v1
for a sense event).

## What v1 covers

- **Engines:** for each of the six engines in [Engines](engines.md), the input fields (required and optional), the fence
  name of its block (`anna-gate` for the action gate, `anna-<engine>` for the rest), every output key, and the fixed
  values where a key has them (`verdict`, `found`, `mode`, `greet_only`, `missing`, `index`, `source`, `when`).
- **The record:** the folders and files every record has, the optional ones, how files are named (journal days,
  handoffs, clock months, lessons, things) and the shape of `self/lately.md`. The full layout is on
  [The record's layout](record-layout.md).

## Rules

- A producer of v1 writes **every** output key. A value that has nothing to say is `none`.
- A reader ignores keys it doesn't know (with a warning) and checks fixed values by the **first word**, so
  `index: stale (2 commits behind)` reads as `stale`.
- Adding an optional input field or a new allowed value is still v1. Renaming or removing a key, or changing what a value
  means, makes v2: a new `contracts/v2.json`, with v1 kept beside it until nothing reads v1.

## Checked by

[`anna-contract`](commands.md#anna-contract) and `tests/test_contract.sh`, which run in CI:

| Check | Fails when |
|---|---|
| `anna-contract agents` | an `agents/anna-*.md` file's output block or `## Input` section differs from the contract |
| `anna-contract docs` | a block on [Engines](engines.md) differs from the contract (docs and code must agree) |
| `anna-contract record` | a record lacks a required folder or file, a journal day sits in the wrong month, a lesson lacks front matter, or `self/lately.md` breaks its shape |
| `anna-contract check <engine>` | one returned block misses a key or uses a value outside the fixed list |

`check` is the one to use on real output: feed it what an engine returned (from a transcript, a log, or a run on another
model) and it says whether the block conforms.

```bash
anna-engine interpretation < input.txt | anna-contract check interpretation
anna-contract record ~/anna-record
```

## Related

- [Engines](engines.md): what each engine does and when it runs.
- [The record's layout](record-layout.md): every folder and its rules.
- [Senses](../concepts/senses.md): the sense event contract.
