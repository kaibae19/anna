# Roadmap

Designed and partly prototyped in the deployment this scaffold came from; not in the scaffold yet.

**Done:** engines as subagents (`agents/`, [architecture](concepts/architecture.md) § Engines) with the action gate enforced by a hook.
Next for them: replay a day's stream through each engine and score the blocks in the nightly fold, so prompt changes are
measured rather than guessed; then the local-model shadow below, engine by engine (interpretation and epistemic first: no
tool calls, fixed labels).

- **Local-model shadow.** A shadow Anna on a local GPU (Ollama speaks the Messages API) fed the day's stream overnight, with
  no actions and no replies, scored per engine against the frontier run: right tool, right facts, honest "don't know",
  voice, latency. The outcome: which parts a one-GPU home can run locally. Where models disagree is where Anna was unsure,
  which becomes a morning salience list ("dreaming").
- **Event wakes.** Home Assistant, the UPS, or a ⛔ check pushes an event over the relay and wakes the brain at any hour to
  gather context. The system's own alert always reaches the person first.
- **The canon off-site.** Client-side encrypted backups of the record and state (restic, append-only) to a second location.
- **Proof of memory.** OpenTimestamps over the record's commits, so the history provably existed when it says it did.
- **More senses.** Cameras as eyes, proxy errors as skin, WAN health as breath.
- **The chat app as a setting.** The bot's channel is a Claude Code plugin, but Telegram is wired into `anna-tg`,
  `anna-notify`, the bot's settings and `install.sh`. A `bot.channel` setting (plugin, token file, and a notify method
  per channel) would make another chat app a config change instead of an edit.
- **merlin during setup, via podman.** `/anna-setup` asks whether to install merlin now: rootless podman quadlets
  (Postgres + pgvector, a CPU embedder, the indexer on a timer) shipped in merlin's own repo, registered with Claude
  Code as the `merlin` MCP server. Until then, the [merlin guide](guides/merlin.md) covers it.
