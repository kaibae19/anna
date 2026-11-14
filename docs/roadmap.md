---
description: "What's designed or prototyped in the deployment Anna came from but not in the scaffold yet, and what's done."
---

# Roadmap

Designed and partly prototyped in the deployment this scaffold came from; not in the scaffold yet.

**Done:** engines as subagents (`agents/`, [architecture](concepts/architecture.md) § Engines) with the action gate enforced by a hook. Pushed senses: the sense intake (`anna-senses`; contract v1 over HTTP, a drop folder or MQTT; [Senses](concepts/senses.md)). Engines that run themselves (interpretation by the prompt hook, epistemic counted; [Engines](reference/engines.md#engines-that-run-themselves)). An own journal and a nightly dream ([Her own journal](concepts/own-journal.md)). A record access log (`anna-access`): which parts of the record are used, the measurement for memory that fades by disuse. Versioned contracts (v1) for each engine's blocks and the record's layout, checked by `anna-contract` and the tests ([Contracts](reference/contracts.md)). The learning loop closed: the nightly runs' proposals kept with a status in `self/proposals.md`, raised one a day in conversation, applied by `/anna-proposals` once you accept ([Skills](reference/skills.md#anna-proposals)). One door for everything Anna tells you: sense alerts, clock pings and failed runs routed by where you are, held in your quiet hours, as loud as they need to be ([How Anna tells you things](concepts/telling.md)). Two example pushed senses to start from: Prometheus alerts with a dead-man, and a daily container-update digest ([Senses](concepts/senses.md#examples-to-start-from)).
Next for them: replay a day's stream through each engine and score the blocks in the nightly fold, so prompt changes are
measured rather than guessed; then the local-model shadow below, engine by engine (interpretation and epistemic first: no
tool calls, fixed labels).

- **A stricter action gate.** Today the gate blocks a known list of commands ([security](concepts/security.md) § What it
  doesn't catch yet). Planned: only known reads pass and everything else needs a `go`; a `go` counts only for the action
  it was given for; the `asked` words in the gate's audit are checked against what the person actually said.
- **Local-model shadow.** A shadow Anna on a local GPU (Ollama speaks the Messages API) fed the day's stream overnight, with
  no actions and no replies, scored per engine against the frontier run: right tool, right facts, honest "don't know",
  voice, latency. The outcome: which parts a one-GPU home can run locally. Where models disagree is where Anna was unsure,
  which becomes a morning salience list.
- **Night wakes.** Pushed senses already reach the working session by day (`check` and `ask` go over the relay,
  [Senses](concepts/senses.md)). Still missing: an urgent one waking it at night, while the relay is paused for the
  rollover, to gather context. The system's own alert always reaches the person first.
- **The canon off-site.** Client-side encrypted backups of the record and state (restic, append-only) to a second location.
  Running in the home this came from since 2026-11; not in the scaffold yet.
- **Memory that fades by disuse.** Topics nobody has needed for a long while turn into a short gist with a pointer to the
  full detail, which stays archived; seasonal topics wait instead of fading, and anything comes back the moment it's
  used. Corrections, decisions and their reasons never fade. Designed, not built.
- **Secrets without a terminal.** A small local web form for giving Anna a token or password, for people who don't work
  in a terminal. Designed, not built.
- **Proof of memory.** OpenTimestamps over the record's commits, so the history provably existed when it says it did.
- **Critical alerts that can wake you.** A `critical` importance above `high` for the rare thing that can't wait until
  morning (a storage pool with no redundancy left, the UPS on battery and running low, a leak or smoke sensor). Anna
  escalates step by step, each only if the last got no reply within a few minutes: a message where you are plus a phone
  notification that breaks through Focus; overnight, a physical cue in **your** room only (a lamp to a dim warm level,
  an LED strip pulsing), which you name and give a standing OK for in advance; then one repeat, and she stops. Waits for
  a sense that actually needs it ([How Anna tells you things](concepts/telling.md)).
- **More senses.** Cameras as eyes, proxy errors as skin, WAN health as breath.
- **The chat app as a setting.** The bot's channel is a Claude Code plugin, but Telegram is wired into `anna-tg`,
  `anna-notify`, the bot's settings and `install.sh`. A `bot.channel` setting (plugin, token file, and a notify method
  per channel) would make another chat app a config change instead of an edit.
- **merlin during setup, via podman.** `/anna-setup` asks whether to install merlin now: rootless podman quadlets
  (Postgres + pgvector, a CPU embedder, the indexer on a timer) shipped in merlin's own repo, registered with Claude
  Code as the `merlin` MCP server. Until then, the [merlin guide](guides/merlin.md) covers it.
