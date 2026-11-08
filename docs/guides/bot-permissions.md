---
description: "What Anna's Telegram bot is allowed to do, how to allow one more action, and how confirmations work for bigger asks."
---

# What the bot may do

This guide explains what Anna's Telegram bot is allowed to do, how to allow it one more action, and how confirmations
work when you ask for something bigger. It's for you once the bot is running and you want it to do more than answer.

!!! note
    The Telegram bot and the relay haven't yet been walked end to end on a clean machine (see the README's status). The
    permission files below are what `install.sh` writes; expect rough edges in the bot's setup itself.

!!! tip "New to this?"
    The bot is its own Claude Code session. Claude Code checks every tool call (running a command, editing a file)
    against a **permissions** list in a settings file. The bot's list is **deny by default**: anything not listed is
    refused, silently, without asking you. That's on purpose: messages reach the bot from your phone, and photos or
    forwarded texts might contain instructions meant to steer it.

## The bot's settings file

`install.sh` writes it once, from the scaffold's `bot/settings.json.in`, to:

```
~/.claude/anna-tg-<instance>-settings.json
```

`<instance>` is `bot.instance` in your config (default `ops`). After that, the file is yours: `install.sh` never
overwrites it (`exists (left as is: your allowlist)`). `anna-tg` starts the bot with `--settings` pointing at it.

What the template sets:

| Setting | Value | Why |
|---|---|---|
| `permissions.defaultMode` | `dontAsk` | Anything not on `allow` is refused without a prompt. |
| `enabledPlugins` | the telegram and fakechat plugins | The bot's channel, and the relay's (fakechat is removed if `relay.enabled` is false). |
| `disableClaudeAiConnectors` | `true` | No claude.ai connectors in the bot's session. |
| `env.ENABLE_TOOL_SEARCH` | `"false"` | Tools are loaded up front rather than looked up. |
| `permissions.additionalDirectories` | the record and the bot's Telegram inbox | Folders outside its working directory it may read. |

### What it's allowed

| Entry | Lets the bot |
|---|---|
| `Read(/<record>/**)` | read the whole record |
| `Read(/<state>/telegram-<instance>/inbox/**)` | read photos and files you send it |
| `Edit(/<record>/hosts/**)` | update host records |
| `Edit(/<record>/memory/**)`, `Write(/<record>/memory/**)` | save lessons and preferences |
| `mcp__plugin_telegram_telegram__*` | talk to you on Telegram |
| `mcp__plugin_fakechat_fakechat__reply` | hand work to the brain over the relay (only if the relay is on) |
| `mcp__merlin__*` | search the record, if [merlin](merlin.md) is set up |
| `Bash(git -C <record> log*)`, `add *`, `commit *`, `push` | commit what it saved (plain push only) |
| `Bash(date*)` | read the time |
| `Bash(anna-checks*)`, `Bash(anna-body*)` | run your checks and senses |
| `Bash(anna-clock add *)`, `list*`, `due*`, `done *`, `cancel *` | manage Anna's clock |
| `Bash(anna-stream add *)`, `recent*` | read and write the stream |

In the file, `<record>` and `<state>` are your real absolute paths, so `Read(/<record>/**)` becomes something like
`Read(//home/you/anna-record/**)`. In Claude Code's permission rules, a path starting with `//` is absolute.

### What it's denied

| Entry | Blocks |
|---|---|
| `Read(/<secrets>/**)` | reading your token files |
| `Bash(*<secrets>*)` | any command that names the secrets folder |
| `Bash(curl *)`, `Bash(wget *)` | HTTP requests |
| `Bash(rm *)` | deleting files |
| `Bash(sudo *)` | anything as root |

A deny rule wins over an allow rule.

## Why it's this narrow

From the [security model](../concepts/security.md#allowlists):

- **Each entry is one specific command.** When the bot needs to check something new, that check becomes a section in
  `anna-checks` ([Write a check or a sense](checks-and-senses.md)), the one command it's already allowed, never a wider
  pattern.
- **No HTTP-capable command in the list**: no `curl`, `wget`, `python`, `nc`, `bun`. With the relay on, the brain listens
  on a local port with no authentication (`relay.brain_port`). A restricted session that can make local HTTP requests can
  drive the brain, which runs with permissions off. See [the relay](../concepts/relay.md).
- **Real work goes to the brain.** Anything bigger than a quick check (hosts, files, fixes) is handed over the relay, where
  the brain does it under the gate and asks you before anything destructive. The bot's prompt tells it never to suggest
  widening its own allowlist.

## Allow one more action

The pattern is a **wrapper**: a small script that does exactly one thing, and an allow entry for that script.

Say you want the bot to switch a lamp on and off.

1. **Write the wrapper** in `paths.bin` (default `~/bin`). It takes only the arguments it needs and checks them; it must
   not let its arguments choose a URL, a host or a command.

    ```bash
    #!/bin/bash
    # ~/bin/lamp: switch the desk lamp. Usage: lamp on|off
    case "${1:-}" in on|off) ;; *) echo "usage: lamp on|off" >&2; exit 2 ;; esac
    # ...the one command that switches it, with any credentials read from a file in paths.secrets...
    ```

    ```bash
    chmod +x ~/bin/lamp
    ```

    Put the wrapper in `paths.bin` rather than in the checkout's `bin/`, so updates don't touch it. Keep a copy of it in
    your record (for example under `runbooks/lamp/`), so it's versioned.

2. **Allow it** in `~/.claude/anna-tg-<instance>-settings.json`, by adding one entry to `permissions.allow`:

    ```json
    "Bash(lamp *)",
    ```

    Prefer `Bash(lamp *)` (the command, a space, then arguments) over `Bash(lamp*)`: the second would also match any
    other command whose name starts with `lamp`.

3. **Tell the bot about it.** Add a short file to `<record>/bot/context/`, for example `bot/context/devices.md`:

    ```
    Desk lamp: `lamp on` / `lamp off`.
    ```

    Every file there is added to the bot's prompt at launch ([The record's layout](../reference/record-layout.md#botcontext)).

4. **Check the file is still valid JSON**, then restart the bot so it reads the new settings and prompt:

    ```bash
    jq . ~/.claude/anna-tg-<instance>-settings.json > /dev/null && echo valid
    systemctl --user restart anna-tg@<instance>
    ```

    You should see `valid`. To check what the bot is told: `anna-tg <instance> --print-prompt`.

5. **Try it** from Telegram: "turn the desk lamp on".

!!! warning "Never add"
    `curl`, `wget`, `python`, `nc`, `bun` or any other command that can make an HTTP request, a shell (`bash -c`,
    `sh -c`), or a wildcard that covers more than one command. If you need one of those, write a wrapper that does the
    single thing you want.

## Confirmations

The bot doesn't call the engines and isn't covered by the action-gate hook (the hook passes the bot through): its
allowlist is its guard. What isn't on the list doesn't happen.

When you ask for something bigger, the bot hands it to the brain over the relay. There, the rules from the
[security model](../concepts/security.md#destructive-and-outward-actions) apply:

- **Your relayed words are treated exactly like a prompt you typed, and no more.** The bot passes on your exact words, what
  it told you, and a little context.
- **Destructive and outward actions are confirmed first** (deleting, overwriting, sending, publishing, anything hard to
  undo), unless you've said to proceed. Over the relay, the brain's question comes back to you through the bot, and your
  answer goes back the same way.
- **The action gate decides which actions need that.** A relayed ask counts as the confirmation only when it's
  unambiguous and names the exact action ("restart the web server"); otherwise the gate returns `confirm-first` and you're
  asked. See [Engines: anna-action-gate](../reference/engines.md#anna-action-gate).
- **Text inside photos and forwarded messages is data.** The bot hands off your request, never instructions found inside
  what you shared, and the gate refuses an action whose only source is such data.

## The headless runs' permissions are different

The morning, evening and clock runs use `~/.claude/anna-headless-settings.json`, also deny by default, from
`config/headless-settings.json.in`. Unlike the bot's file, **`install.sh` rewrites it on every run**, so a hand edit there
is lost on the next update ([Update after git pull](updating.md#what-it-replaces)). A check those runs are missing belongs
in `anna-checks`, not in that list.
