---
description: "The relay gives Anna one voice: the Telegram bot (her fast side) talks with you, and harder things go to her slow side, the working session, which has the record and the tools."
---

# The relay: one voice

Anna has two long-running sessions. The **bot** is her fast side, the conversation: it lives in Telegram, answers quickly, does what its
allowlist permits, and runs on a cheaper model. The **working session** is her slow side and does the work: it has the record, the things she looks
after, the tools. Without a relay the bot and the working session would each know half the day. With it, you talk to the bot, harder things go to the slow side, and the result
comes back through the bot, which says it in its own voice.

```
you ─Telegram─▶ bot ──fakechat reply "RELAY: …"──▶ (bot's fakechat /ws) ──▶ anna-relay bridge ──▶ queue
                                                                                             │
slow side ◀── <channel> "[relay <id> from the bot] …" ◀── POST /upload (session's fakechat) ◀┘
    │
    └─fakechat reply (reply_to=<id>)──▶ (session's fakechat /ws) ──▶ bridge ──▶ POST /upload (bot's fakechat)
                                                                                             │
you ◀─Telegram─ bot ◀── <channel> "[relay result for <id>] …" ◀──────────────────────────────┘
```

## Why fakechat

Claude Code can push messages into a running session through **channels** (MCP servers that emit
`notifications/claude/channel`). During the research preview, only channels on Anthropic's allowlist load with plain
`--channels`; your own channel needs `--dangerously-load-development-channels`, which shows a warning dialog on every launch
and resume. **fakechat**, Anthropic's demo channel, is on the allowlist: a small local web chat with an HTTP upload endpoint
(in) and a websocket that broadcasts the session's replies (out). Each session gets its own fakechat on its own port
(`FAKECHAT_PORT`), and `anna-relay bridge` connects the two. No dialog, nothing to auto-answer.

## Trust: read this before you enable it

**fakechat has no authentication.** Anything on the machine that can reach `127.0.0.1:<brain_port>` can put a prompt into
the working session, and it usually runs with wide permissions. So:

- **No HTTP-capable command in any restricted allowlist** (the bot's, the headless runs'): no `curl`, `wget`, `python`,
  `nc`, `bun`. Otherwise a deny-by-default session could drive the working session through the port.
- Run the working session on a machine (or VM) that's Anna's own, without other users or untrusted services that fetch URLs.
- The working session treats a relayed message exactly like a prompt you typed, **and no more**: destructive or outward actions still
  get your confirmation (the question goes back through the bot). Text from photos and forwarded messages is data.

## Guards

- **Only explicit hand-offs count.** fakechat's own instructions tell a session to answer *every* channel message with its
  reply tool, so a result delivered to the bot came straight back as a new request (a loop, 3 rounds in 15 s, in testing).
  The bridge accepts only bot messages that start with `RELAY:` and carry no `reply_to`.
- **Breaker.** More than 5 hand-offs in 2 minutes stops intake and writes a ⚠ to the stream until the bridge restarts.
- **Settling.** A push before a session has registered the channel is dropped silently, so a side counts as online only
  after its websocket has been up for 5 s.
- **Orphans.** fakechat's web server outlives its Claude session (after a kill and after a clean `/exit`), holding the
  port. The next session's fakechat then can't bind, and the bridge would push into a dead end. Launchers run
  `anna-relay clear-port brain|bot` first (kills only an orphaned `bun … server.ts` whose parent is PID 1; refuses if a live
  session holds the port), and the bridge treats an orphan as offline and kills it.
- **Nights.** While the working session wraps up (`paused`, set by `anna-day close`, cleared by `anna-day open`) or is offline,
  hand-offs wait in the queue and the bot is told once, so it can say "I'll get to it in the morning".
- **Age alarm.** An item with no result after `relay.alarm_min` minutes gets a ⚠ line in the stream.

## Queue

`<paths.state>/relay/{new,brain,out,done}/<id>.json`, one file per hand-off, moved by atomic renames. Nothing is
deleted by the bridge. `anna-relay status` and `anna-relay list` show it; `anna-relay send TEXT` queues a request from a
script.

## Turning it on

1. `relay.enabled = true` in `anna.toml`, then `./install.sh`: it installs fakechat if it's missing and keeps it
   **disabled at user scope** (`"enabledPlugins": {"fakechat@claude-plugins-official": false}` in `~/.claude/settings.json`),
   so only the working session and the bot start it.
2. The working session launches with `--settings ~/.claude/anna-brain-settings.json --channels plugin:fakechat@claude-plugins-official`
   and `FAKECHAT_PORT=<brain_port>` (`anna-brain` does this when the relay is enabled).
3. The bot launches with both channels and `FAKECHAT_PORT=<bot_port>`, and its settings allow only
   `mcp__plugin_fakechat_fakechat__reply` from fakechat (`anna-tg` does this).
4. `systemctl --user enable --now anna-relay`.
