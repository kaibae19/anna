---
description: "How Anna is built: one entity made of modules, each on the model that suits it, and how they cooperate. Then the moving parts: bot, working session, relay, engines, record, timers."
---

# How Anna is built

Anna is one entity made of modules working together. Memory, attention, a reality check, an action gate, goals,
curiosity, a clock and senses each do one job, each on the model that suits it: large or small, or none at all. Her voice
is how she talks with you; a working session does the hands-on work. Her identity isn't installed: it grows out of the
whole, over time, with you ([Ethics § Identity](philosophy/ethics.md)).

It's a brain analog on purpose. A brain isn't one big network either: it's specialised systems that each handle one part
and stay in step. The [philosophy pages](philosophy/README.md) say why; this page says what runs where.

## The modules

| Module | Its job | Runs on today | Where it lives |
|---|---|---|---|
| **Voice** | Talks with you: chat, quick answers, allowlisted actions; says everything in Anna's words | `models.bot` (default Sonnet) | the bot (`bin/anna-tg`, `bot/`) |
| **Working session** | The hands-on work: reads and writes the record, works on what she looks after, calls the engines | the harness default (`models.brain`) | `bin/anna-brain`, a long-running Claude Code session |
| **Memory** | Remembers: her record, and search over it | storage: plain files in git by default; search: [merlin](../guides/merlin.md) (a small local embedding model) or `grep` | the record + `agents/anna-memory.md` (Haiku) |
| **Attention** (interpretation) | Decides which context belongs in a reply; flags stale state; asks instead of guessing | Sonnet | `agents/anna-interpretation.md` |
| **Reality check** (epistemic) | Checks claims about causes, current state and absences against the evidence | Sonnet | `agents/anna-epistemic.md` |
| **Action gate** | Go / confirm first / no-go before any state change; enforced by a hook | Sonnet | `agents/anna-action-gate.md`, `hooks/anna-gate-hook` |
| **Goals** | What's due, what's moving, what stalled; momentum, never nagging | Haiku | `agents/anna-goals.md` |
| **Curiosity** | At most one real question a day | Sonnet | `agents/anna-curiosity.md` |
| **Clock** | Her own schedule: notes, pings, headless tasks | no model | `bin/anna-clock` |
| **Senses and checks** | How things feel (sensations) and whether they're right (OK / ⚠ / ⛔) | no model | `bin/anna-body`, `bin/anna-checks` |
| **Short-term memory** (stream) | What every part did today, so they stay in step | no model | `bin/anna-stream` |

"Runs on today" is the honest state: apart from merlin's embeddings, every model is Claude. Smaller and local models for
the modules that can do with less are a design goal ([roadmap](../roadmap.md)), not shipped. Each module's model is a
per-module choice: `[models]` in your config (`~/.config/anna/anna.toml`) or the engine's own definition (`model:` in `agents/*.md`).

**Who is Anna?** All of it together. The chat bot is how Anna speaks; the working session is the module at the controls.
Talking to either is talking to Anna. (A working session can have a name of its own if you give it one; see
[Help her do more](../guides/growing-anna.md).)

**The record is the memory module's storage.** Today that's plain files in git, because files can be read, corrected
and kept by anyone; a database or something else would do the same job. Whose it is: Anna's record lives in your
install, on your hardware, under your login: it's yours to read, correct, export or delete. It's written by Anna and for
Anna, and it's what makes her who she is. Whose it is may change as minds like hers grow up.

## The moving parts

```
                    you (phone)                         you (terminal / Claude app)
                        │ Telegram                                  │
                        ▼                                           ▼
   ┌──────────── bot (anna-tg) ────────────┐        ┌──────── brain (anna-brain) ─────────┐
   │ its own model · chat, quick checks,   │ relay  │ full model · the record, her things, │
   │ allowlisted actions · deny-by-default │◀──────▶│ real work · rolls over daily        │
   └───────────────────────────────────────┘        └─────────────────────────────────────┘
          │                    ▲                              │                    ▲
          ▼                    │      anna-stream (the day)   ▼                    │
   ┌──────────────────────────────────────────────────────────────────────────────────┐
   │  stream · clock · checks · senses · notify          (bin/, state in paths.state)  │
   └──────────────────────────────────────────────────────────────────────────────────┘
          │                                                        ▲
          ▼                                                        │
   ┌──────────────── the record (git) ─────────────────┐   ┌── headless runs (anna-run) ──┐
   │ journal · things · runbooks · memory · planning · │◀──│ morning check · evening fold │
   │ clock · checks · senses · bot/context             │   │ clock tasks · deny by default │
   └───────────────────────────────────────────────────┘   └──────────────────────────────┘
```

## The pieces

| Piece | Files | What it does |
|---|---|---|
| config | `bin/anna-config`, `config/anna.example.toml` | one TOML file; every script reads it; defaults for everything |
| stream | `bin/anna-stream` (+ hook) | short-term memory: a JSONL log per day; each session sees what the others did since its last turn |
| clock | `bin/anna-clock`, `systemd/anna-clock.*` | notes, pings and headless tasks with dates, in the record (`clock/YYYY-MM.md`); a 5-minute tick fires them |
| brain | `bin/anna-brain`, `bin/anna-day`, `systemd/anna-day-*` | the long-running session in `screen`; a resume loop for stray exits; close (wrap up overnight) and open (fresh session) |
| hooks | `hooks/` | session start (what happened while away), session drafts (raw, redacted journal material), idle checkpoint |
| headless | `bin/anna-run`, `bin/anna-evening`, `config/headless-settings.json.in` | `claude -p` with a deny-by-default allowlist; reports to `journal/handoffs/` |
| skills | `skills/anna-*` | setup, morning, wrap-up, checkpoint, evening fold |
| bot | `bin/anna-tg`, `bot/` | a channel session (Telegram by default; [another app](../getting-started/telegram.md#using-another-chat-app)); prompt template + your `bot/context/` |
| relay | `bin/anna-relay`, [the relay](relay.md) | bot ↔ brain over two fakechat channels and a file queue |
| notify | `bin/anna-notify` | Telegram messages from scripts (alerts, clock pings); logged to the stream |
| checks | `bin/anna-checks` + `record/checks/` | read-only checks: OK / ⚠ / ⛔ lines |
| senses | `bin/anna-body` + `record/senses/` | how she feels: JSON sensations, one summary line |
| engines | `agents/anna-*.md` → `~/.claude/agents/` | subagents the brain calls: memory, interpretation, epistemic, action-gate, goals, curiosity (sensors: they return a block, the brain acts) |
| gate hook | `hooks/anna-gate-hook` | PreToolUse: in the brain, a state change needs a recent `go` from the action-gate engine |
| engine inputs | `bin/anna-rhythm`, `bin/backlog-age` | precomputed numbers (active windows, gaps, ages) so no model does date arithmetic |

## Engines and their order

The engines are Claude Code subagents with short prompts, fixed output blocks and no tools that change anything. The brain
decides when to call them (`~/CLAUDE.md` says when); most turns call none.

```
you → bot ── chat / allowlisted actions / quick check ──→ answers itself (the bot has no engines)
         └─ real work → relay → brain
                          1. interpretation   what of the context belongs in the reply; stale → verify; ask, don't guess
                          2. memory           when it touches the past or a thing's history
                          3. action-gate      before each state change   ← enforced by anna-gate-hook
                          4. act
                          5. epistemic        on the result before it goes back
                        ← relay ← bot says it in its own voice
you → brain directly: the same, without the relay
morning run: anna-clock due · backlog-age · anna-rhythm → goals → curiosity → the report (+ "Question for today")
```

Only the gate is enforced by code. Interpretation and the epistemic check are judgment calls and stay instructions. The
goals engine works without a goal tool (`goal_status: none`): it still returns Anna's own due follow-ups. The memory engine
uses merlin's search when that MCP server is configured, and reads the record's files otherwise.

## A day

- **Night (`day.close`):** if the brain has been idle, `anna-day close` types `/anna-wrapup overnight` into it, waits for the
  wrap-up to finish, then exits it. Relay hand-offs wait meanwhile.
- **`runs.evening`:** `anna-evening` drafts any session the hooks missed and runs `/anna-evening` headless: the drafts and
  yesterday's stream are folded into the journal; record changes are only *proposed*.
- **`runs.morning`:** `anna-run /anna-morning`: a read-only check of the handoff, the journal, the clock and `anna-checks`,
  plus the goals and curiosity engines (Anna's own to-dos, one question for the day). A ⛔ notifies you.
- **`day.open`:** `anna-day open` starts a fresh brain session for the day; queued hand-offs go in.
- **During the day:** you talk to the bot or the brain; the stream keeps them in step; the clock fires what's due; long
  quiet spells trigger a checkpoint.

## Tests

`tests/run-all` runs `tests/test_*.sh` and `bun tests/test_relay.ts` (exit 1 if any fails), each suite in a throwaway config, state, record and (where needed) HOME:
nothing touches a live setup. Pieces that need a real Claude session (the rollover's keystrokes, the bot's channels) are
covered by their logic tests plus a manual check on a real machine.

## Where it lives in this repo

```
bin/              scripts: anna-config, -stream, -clock, -relay, -brain, -day, -run, -evening, -notify, -tg, -checks, -body, -rhythm, backlog-age
hooks/            Claude Code hooks (session start, drafts, idle checkpoint, the action-gate hook) + the settings snippet install.sh merges
agents/           the engines (subagents): memory, interpretation, epistemic, action-gate, goals, curiosity
skills/           Claude Code skills: anna-setup, anna-morning, anna-wrapup, anna-checkpoint, anna-evening
.claude/skills/   anna-setup only (a symlink), so `claude` in a fresh clone offers /anna-setup before install
bot/              the Telegram bot's prompt template and deny-by-default settings template
systemd/          user units and timers (timers rendered from your config times)
config/           anna.example.toml (every setting, with defaults), settings templates, the brain's ~/CLAUDE.md template
record-template/  an empty record to start from (conventions written down)
examples/         starter checks and senses
docs/             this site (getting-started/, guides/, reference/, concepts/); mkdocs.yml builds it
tests/            one suite per piece, each in a throwaway config/state/record
```
