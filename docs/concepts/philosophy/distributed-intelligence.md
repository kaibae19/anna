---
description: "Why Anna uses several small parts on focused tasks, each on the smallest model that does its job well, instead of one large model for everything."
---

# Distributed intelligence: small models, focused tasks

The industry's default is one model, as large as possible, for everything. Anna takes the other path: **specialized parts
doing focused tasks, each on the smallest model that does its job well, learning one person rather than averaging
everyone.** Not to be contrarian: it's how biological intelligence is built. The brain doesn't run one giant network.
Its regions are specialized, communicate through signals, and work at different speeds on purpose: fast salience shapes
slower deliberation.

## Comprehension versus generation
Most of what an agent does to understand a moment is **comprehension**: is this message low-energy? which of these facts is
stale? does this draft claim more than its evidence shows? which question would unblock something? These are reading tasks
with a small, fixed set of answers.

Small models are good at comprehension: fast, cheap, and accurate when the output is a short structured block. The second
version's clearest example: statistics alone said "keep replies proportional" no matter the moment, so someone writing
"yeah pretty tired…" got a long, cheerful reply. A 3-billion-parameter model reading the current message, the last few
messages and the last emotional snapshot returned *low energy, falling, be gentle, be brief*, and the reply fit. It
generated no prose; it read the room. A sensor, not an actor.

Only the voice, the reply itself, clearly benefits from a large model: nuance, judgment and expression live there.

## In this version
Every engine names its model by alias (`haiku`, `sonnet`), and each part of Anna (brain, bot, scheduled runs) is one config
line. Today the frontier models do the work, because they're reliable at tool calling and judgment, and reliability comes
first. The architecture is built so that changes:

| Engine | Fit for a small local model | Why |
|---|---|---|
| interpretation | good | fixed labels, no tool calls |
| epistemic | good | reading comprehension over a short draft and its evidence |
| goals | good, once its numbers are precomputed | fills fields from inputs |
| curiosity | fair | a judgment of value |
| memory | hardest | needs reliable tool calls |
| action gate | shadow only | a wrong `go` is the one mistake that matters; the stricter verdict wins |
| voice | last | after the engines are trusted |

The plan ([roadmap](../../roadmap.md)) is a shadow Anna: a local model fed the day overnight, with no actions and no replies,
scored engine by engine against the frontier run. An engine moves to a local model when it earns it, not before.

## Why it matters
- **Speed:** a small model answers in a second or two; the reply isn't held up by the sensing around it.
- **Hardware:** the goal is that a home with one GPU can run most of Anna. One huge model can't get there; several small ones
  and one capable one can.
- **Resilience:** an engine that's unavailable degrades on its own; the rest keep working.
- **Evolution:** each engine can be improved, retested or swapped without touching the others.
- **Privacy:** what runs locally stays local. The more of Anna that runs on the person's own hardware, the less of their
  life passes through anyone else's.

Small models, focused tasks, individual learning, local where it's earned. That's the path to an agent that serves a person
rather than a platform.
