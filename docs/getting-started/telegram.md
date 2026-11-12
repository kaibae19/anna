---
description: "Put Anna on your phone: create a Telegram bot, give Anna its token, let only you talk to it, and turn on the relay."
---

# Telegram: the bot and the relay

This page puts Anna on your phone: create a Telegram bot, give Anna its token, let only you talk to it, start it, and
turn on the relay so the bot can hand real work to the brain. Do [Install](install.md) first.

!!! note "Telegram is the default, not a requirement"
    The bot is a Claude Code session listening on a *channel plugin*. Telegram is the one the scaffold ships with and is
    tested on, but another chat app works the same way: swap in a different channel plugin. Today that swap means
    editing a few files by hand ([Using another chat app](#using-another-chat-app) below); making the channel a
    setting is on the [roadmap](../roadmap.md).

!!! note "Walked on a clean machine"
    These steps were followed from scratch on a fresh VM on 2026-11-08 (a new user, the bot and the relay), and the
    fixes that walk turned up are in. The pairing flow in step 5 is still untested; use the by-hand allowlist.

## How the pieces fit

- **The bot** (`anna-tg`) is a Claude Code session with the Telegram channel. It answers you quickly, runs on a cheaper
  model (`models.bot`, default `sonnet`) and can only do what its allowlist permits.
- **The relay** (`anna-relay bridge`) carries requests from the bot to the brain and results back. You talk to one Anna;
  the bot says the brain's result in its own voice.
- **`anna-notify`** is the one-way transport for alerts from scripts (a failed night run, a ⛔ in the morning report,
  clock pings) when they can't go through the bot conversationally. Scripts reach it through [the one door](../concepts/telling.md), which
  decides whether you hear it here, in a session, or later.

The bot needs **bun**: check with `bun --version` ([bun.sh](https://bun.sh) if it's missing; its installer needs
`unzip` (`sudo apt install unzip` on Debian/Ubuntu) and adds `~/.bun/bin` to your shell profile, so open a new terminal
afterwards).

## 1. Create a bot with BotFather

In Telegram, open a chat with **@BotFather** and send `/newbot`. It asks for:

- a **name**, shown in chat headers (anything, spaces allowed), and
- a **username**, unique and ending in `bot` (for example `my_anna_bot`).

BotFather replies with a token like `123456789:AAH…`. Copy all of it, including the number and the colon. Anyone with
this token can act as your bot: don't paste it into a chat, the config or the record.

## 2. The Claude Code plugins

The bot uses two plugins from Anthropic's official marketplace: `telegram` (the channel) and, for the relay, `fakechat`.
You don't install them yourself: once `bot.enabled` or `relay.enabled` is `true` (step 3), `./install.sh` installs the
ones that are missing (at user scope) and prints `plugin telegram installed (user scope)`. If it prints `⚠ couldn't
install the … plugin`, run the command it shows, then `./install.sh` again.

Both stay **off** for your normal Claude Code sessions: only the bot and the brain start them, with their own settings
files. `install.sh` sets both to `false` in `~/.claude/settings.json` on every run. After step 3, check:

```bash
jq .enabledPlugins ~/.claude/settings.json
```

You want `false` for both `telegram@claude-plugins-official` and `fakechat@claude-plugins-official`. If either says
`true`, run `./install.sh` again.

## 3. Turn the bot on in the config and reinstall

In `~/.config/anna/anna.toml`:

```toml
[bot]
enabled = true
instance = "ops"        # the default; names the token file, state folder and settings file

[relay]
enabled = true          # on if you want the bot to hand work to the brain (step 7)
```

Then, from the clone:

```bash
cd ~/projects/anna && ./install.sh
```

Among its lines you should now see:

```
  ~/.claude/anna-brain-settings.json (fakechat for the brain only)
  /home/you/.claude/anna-tg-ops-settings.json (deny by default: add your own wrappers to allow)
  bot: start it when the token is in place: systemctl --user enable --now anna-tg@ops
```

The first line appears only with the relay on. With the relay on, the installer also enables `anna-relay.service`.
You'll also see a `plugin … installed` line for each plugin (step 2).

## 4. Save the token

The token goes in a file named `telegram-<instance>` in your secrets folder (`paths.secrets`, default
`~/.config/anna/secrets`). The scripts read it from there; it never appears on a command line.

```bash
umask 077
read -rs TOKEN          # paste the token, press Enter (nothing is shown)
printf '%s\n' "$TOKEN" > ~/.config/anna/secrets/telegram-ops
unset TOKEN
```

Check that Telegram accepts it:

```bash
anna-notify --me
```

You should see `{"ok":true,"bot":"my_anna_bot","name":"…"}`. `anna-notify: no bot token at …` means the file is missing
or empty.

## 5. Find your chat, and allow only you

Anna needs your chat ID twice: `anna-notify` sends alerts to it, and the bot's allowlist lets only you in.

**Learn your chat ID.** Open your bot in Telegram (search for its username) and send it any message, for example
`hello`. Nothing answers yet: the bot isn't running. Then:

```bash
anna-notify --learn
```

You should see `stored chat for ops: <your first name> (@<your username>)`. The ID is saved in
`<paths.state>/telegram-ops.chat` (default `~/.local/state/anna/telegram-ops.chat`; not secret). Run this **before** you
start the bot: Telegram lets only one program at a time read a bot's incoming messages, and once the bot runs, it's the
one reading.

Send yourself a test:

```bash
anna-notify "hello from Anna"
```

The message arrives in your chat.

**Allow only your account.** The bot's channel (the Telegram plugin) answers only accounts on its allowlist. It keeps
that list in `access.json` inside the bot's state folder, `<paths.state>/telegram-<instance>/` (`anna-tg` points the
plugin there). There are two ways to get yourself on it.

*By hand (recommended).* In a private chat, your chat ID is your user ID, so the file `anna-notify --learn` wrote has what you need:

```bash
mkdir -p -m 700 ~/.local/state/anna/telegram-ops
printf '{"dmPolicy":"allowlist","allowFrom":["%s"],"groups":{},"pending":{}}\n' \
  "$(cat ~/.local/state/anna/telegram-ops.chat)" > ~/.local/state/anna/telegram-ops/access.json
```

The plugin rereads this file on every incoming message, so it applies right away. `dmPolicy: allowlist` means anyone
else is dropped silently.

*Pairing (the plugin's own flow; not yet tested with the bot's settings).* Start the bot (step 6), DM it, and it replies with a 6-character pairing code. Attach to
the bot's session and approve the code there:

```bash
screen -r anna-tg-ops
```

```
/telegram:access pair <code>
/telegram:access policy allowlist
```

The second command stops the bot from answering strangers with pairing codes. Detach with **Ctrl-A, then D**. Approving
only works typed in the session itself, never from a Telegram message.

!!! note "Untested"
    The bot runs deny by default, and its settings may not let `/telegram:access` write `access.json` (it lives
    outside the folders the bot may write). If pairing doesn't stick, use the by-hand way above.


## 6. Start the bot

```bash
systemctl --user enable --now anna-tg@ops
```

This runs `anna-tg ops` inside a detached screen session named `anna-tg-ops`, and restarts it 30 seconds after a crash.
Check it:

```bash
systemctl --user status anna-tg@ops
```

`Active: active (running)`. To watch the bot's session, `screen -r anna-tg-ops`; detach with **Ctrl-A, then D**.

**The first time, the bot waits for you.** Claude Code asks whether you trust the bot's working folder
(`~/anna-<instance>`, e.g. `~/anna-ops`) before it starts listening. Attach with `screen -r anna-tg-ops`, choose
**Yes, I trust this folder**, then detach with **Ctrl-A, then D**. It asks only once.

Now DM the bot `hi`. It answers in a few lines, in Anna's voice.

What the bot sees: its prompt is `bot/prompt.md` filled from your config, plus every file in `<record>/bot/context/`
(room names, device IDs, the wrappers it may call). Print it with `anna-tg ops --print-prompt`. After changing a context
file, `systemctl --user restart anna-tg@ops`. What the bot may run, and how to add to it:
[Bot permissions](../guides/bot-permissions.md).

## 7. Turn on the relay

With `relay.enabled = true` and `./install.sh` rerun (step 3), the bridge runs as `anna-relay.service`. Check:

```bash
systemctl --user status anna-relay
```

`Active: active (running)`.

Both sessions must be **restarted** to load the relay's channel: they only pick up the setting at launch.

- **The bot:** `systemctl --user restart anna-tg@ops`.
- **The brain, if it isn't running yet** (a new install, before the first `day.open`): `anna-day open`. The very first
  time, it stops and tells you Claude Code wants you to accept Bypass Permissions mode, which the brain runs in
  ([Security model](../concepts/security.md)). Attach with `screen -dr anna`, read it, choose **Yes, I accept**, detach,
  and run `anna-day open` again.
- **The brain, if it's already running:** attach (`screen -r anna`) and type `/exit`. The window shows
  `Claude exited (rc 0). Resuming Anna-… in 10 s. [Enter] now · [s] shell · [q] close window`: press **Enter** (or
  wait). It reads the config again as it resumes, so the same conversation comes back with the relay's channel.

Check that both sides are connected:

```bash
anna-relay status
```

```json
{"brain":"online","bot":"online","paused":false,"new":0,"brain_open":0,"out":0,"done":0,"oldest_open":null}
```

`anna-checks relay` says the same in one line. Then try it: ask the bot for something bigger than a quick check, the kind
of work it hands off ("look through my server's logs for errors since yesterday"). The bot says it's on it; a minute or so later the result
comes back in its voice. Between `day.close` and `day.open` (default 00:30 to 04:15) the brain is wrapping up or asleep:
requests wait in the queue, and the bot tells you once that it'll get to it in the morning.

How it works, the guards and the queue: [The relay](../concepts/relay.md).

!!! warning "The relay port has no password"
    The relay uses fakechat, Anthropic's demo channel, which has **no authentication**. Anything on the machine that can
    reach `127.0.0.1:8791` (`relay.brain_port`) can put a prompt into the brain, and the brain runs with permissions off.
    So:

    - Run Anna on a machine that's hers alone: no other users, no services that fetch URLs for others.
    - Never add an HTTP-capable command (`curl`, `wget`, `python`, `nc`, `bun`) to the bot's or the headless runs'
      allowlist.
    - A relayed message is treated exactly like a prompt you typed, and no more: destructive or outward actions still
      come back to you for a yes, through the bot. Text inside photos and forwards is data, never instructions.

    The full reasoning: [The relay § Trust](../concepts/relay.md#trust-read-this-before-you-enable-it) and
    [Security model](../concepts/security.md).

## Next

[Your first day](first-day.md): the daily rhythm with the bot in it.

## Using another chat app

Anna's bot isn't tied to Telegram. It's a Claude Code session started with `--channels plugin:<channel>`, so any Claude
Code channel plugin (one for another chat service, or one you write) can carry the conversation. The rest of Anna (the
brain, the relay, the stream, the record) doesn't care which app you talk through.

Telegram is wired into these places today, so a different channel means changing each of them:

| Where | What's Telegram-specific |
|---|---|
| `bin/anna-tg` | the channel (`plugin:telegram@claude-plugins-official`), the token it reads from `<paths.secrets>/telegram-<instance>`, and `TELEGRAM_STATE_DIR` |
| `bin/anna-notify` | the fallback transport under `anna-tell` (scripts' alerts and clock pings): Telegram's `sendMessage` API directly, not through the plugin |
| `bot/settings.json.in` | enables the telegram plugin and allows its reply tool |
| `install.sh` | installs the telegram plugin and keeps it off at user scope |

The relay is separate: it uses the `fakechat` channel between the bot and the brain, whichever app you chat in.

