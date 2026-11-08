---
description: "What's designed or prototyped in the deployment Anna came from but not in the scaffold yet, and what's done."
---

# Roadmap

Designed and partly prototyped in the deployment this scaffold came from; not in the scaffold yet.

**Done:** engines as subagents (`agents/`, [architecture](concepts/architecture.md) § Engines) with the action gate enforced by a hook. Pushed senses: the sense intake (`anna-senses`; contract v1 over HTTP, a drop folder or MQTT; [Senses](concepts/senses.md)). Engines that run themselves (interpretation by the prompt hook, epistemic counted; [Engines](reference/engines.md#engines-that-run-themselves)). An own journal and a nightly dream ([Her own journal](concepts/own-journal.md)).
Next for them: replay a day's stream through each engine and score the blocks in the nightly fold, so prompt changes are
measured rather than guessed; then the local-model shadow below, engine by engine (interpretation and epistemic first: no
tool calls, fixed labels).

- **Local-model shadow.** A shadow Anna on a local GPU (Ollama speaks the Messages API) fed the day's stream overnight, with
  no actions and no replies, scored per engine against the frontier run: right tool, right facts, honest "don't know",
  voice, latency. The outcome: which parts a one-GPU home can run locally. Where models disagree is where Anna was unsure,
  which becomes a morning salience list.
- **Event wakes.** Home Assistant, the UPS, or a ⛔ check pushes an event over the relay and wakes the brain at any hour to
  gather context. The system's own alert always reaches the person first.
- **The canon off-site.** Client-side encrypted backups of the record and state (restic, append-only) to a second location.
  Running in the home this came from since 2026-11; not in the scaffold yet.
- **Memory that fades by disuse.** Topics nobody has needed for a long while turn into a short gist with a pointer to the
  full detail, which stays archived; seasonal topics wait instead of fading, and anything comes back the moment it's
  used. Corrections, decisions and their reasons never fade. Designed, not built.
- **A record access log.** Which parts of her record get read, searched or written, by which part of her, so fading,
  search and the always-loaded index can follow real use. Running in one home since 2026-11; not in the scaffold yet.
- **Secrets without a terminal.** A small local web form for giving Anna a token or password, for people who don't work
  in a terminal. Designed, not built.
- **Proof of memory.** OpenTimestamps over the record's commits, so the history provably existed when it says it did.
- **More senses.** Cameras as eyes, proxy errors as skin, WAN health as breath.
- **The chat app as a setting.** The bot's channel is a Claude Code plugin, but Telegram is wired into `anna-tg`,
  `anna-notify`, the bot's settings and `install.sh`. A `bot.channel` setting (plugin, token file, and a notify method
  per channel) would make another chat app a config change instead of an edit.
- **merlin during setup, via podman.** `/anna-setup` asks whether to install merlin now: rootless podman quadlets
  (Postgres + pgvector, a CPU embedder, the indexer on a timer) shipped in merlin's own repo, registered with Claude
  Code as the `merlin` MCP server. Until then, the [merlin guide](guides/merlin.md) covers it.
