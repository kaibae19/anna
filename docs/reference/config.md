# Configuration

This page lists every setting in Anna's configuration file: what it does, its default, and which part of Anna reads it.
It's for you when you edit `anna.toml` by hand, and for developers who want to know exactly where a value ends up.

## Where the file lives

Anna reads one TOML file:

| What | Where |
|---|---|
| Your config | `~/.config/anna/anna.toml`, or the path in `$ANNA_CONFIG` if you set it |
| The defaults | `config/anna.example.toml` in the scaffold checkout (installed copy: `~/.local/share/anna/config/anna.example.toml`) |

You don't need to copy every key. Anna loads the defaults first, then lays your file over them, section by section. A key
you leave out keeps its default.

!!! tip "New to this?"
    TOML is a plain text format for settings. A line in `[brackets]` starts a section; each line below it is
    `key = value`. Text goes in quotes (`"04:15"`), numbers and `true`/`false` don't. A `#` starts a comment.

The easiest way to write the file is the `/anna-setup` skill in Claude Code: it interviews you and writes it. By hand:

```bash
cd ~/projects/anna
./install.sh          # first run: writes ~/.config/anna/anna.toml from the example, then stops
nano ~/.config/anna/anna.toml
./install.sh          # second run: installs using your values
```

The first run prints `Wrote /home/you/.config/anna/anna.toml from the example: edit it (or run /anna-setup in Claude Code),
then run install.sh again.`

## How values are read

Every script reads the config through `anna-config` (see [Commands](commands.md#anna-config)). Keys are dotted:
section, dot, key.

```bash
anna-config day.open
```

```text
04:15
```

What it does with a value:

- A path that starts with `~` comes back with `~` expanded to your home directory.
- `true`/`false` come back as `true`/`false`.
- A list or table comes back as JSON.
- An unknown key is an error (exit 2, `anna-config: no such key: …`), so a typo never reads as an empty value.

Two more forms:

```bash
anna-config --path     # which file is in use; "(missing: defaults only)" if yours doesn't exist
anna-config --dump     # the merged config (defaults + yours) as JSON
```

The Python scripts and hooks use `bin/anna_cfg.py`, which calls `anna-config --dump` once and reads from the result. If
that fails (no config, a broken file), they fall back to built-in defaults instead of failing: a missing config must never
break a hook.

### Where the defaults come from

`anna-config` looks for the defaults file in this order and uses the first that exists:

1. `$ANNA_HOME/config/anna.example.toml`, if `ANNA_HOME` is set
2. `../config/anna.example.toml` next to the `anna-config` script (running from the checkout)
3. `~/.local/share/anna/config/anna.example.toml` (the copy `install.sh` makes)

### Environment variables

These override or add to the config file. Most are for tests or are set by Anna's own scripts; you rarely set them by hand.

| Variable | Read by | What it does |
|---|---|---|
| `ANNA_CONFIG` | `anna-config`, `install.sh` | path of your config file instead of `~/.config/anna/anna.toml` |
| `ANNA_HOME` | `anna-config` | a scaffold checkout whose `config/anna.example.toml` holds the defaults |
| `MERLIN_PATH` | `anna_cfg.py` | a merlin checkout: its redaction patterns are used instead of the built-in ones |
| `ANNA_TG_MODEL` | `anna-tg` | the bot's model, instead of `models.bot` |
| `ANNA_ADD_DIR` | `anna-run` | one extra directory the headless run may read (`anna-evening` sets it to the state directory) |
| `ANNA_CLOCK_BY` | `anna-clock` | who added an item (default `session`; the bot sets `bot`, the tick sets `tick`) |
| `ANNA_NOTIFY_FROM` | `anna-notify` | the sender name written to the stream (`clock #a3f2`, `anna-run morning`, …) |
| `ANNA_ROLE` | `anna-stream`, hooks | `bot` (set by `anna-tg`) or `relay` (set by `anna-relay.service`); the stream source and hook behaviour follow it |
| `ANNA_HEADLESS` | hooks, `anna-stream` | set to `1` by `anna-run`: the session hooks stay quiet |
| `ANNA_RELAY_DIR` | `anna-relay` | the relay queue directory instead of `<paths.state>/relay` (tests) |
| `RELAY_BRAIN_PORT`, `RELAY_BOT_PORT` | `anna-relay` | override `relay.brain_port` / `relay.bot_port` (tests) |
| `RELAY_SETTLE_MS`, `RELAY_TICK_MS` | `anna-relay` | how long a side must be connected before it counts as online (default 5000 ms), and the bridge's tick (default 2000 ms) |
| `ANNA_RELAY_NOSTREAM` | `anna-relay` | `1` = don't write stream lines (tests) |
| `ANNA_IDLE_WAIT`, `ANNA_IDLE_TEST` | `anna-idle-checkpoint` hook | idle wait before a checkpoint (default 1200 s) and a test switch; see [Hooks](hooks.md) |

## What install.sh does with it

`install.sh` reads your config and uses it to place and fill everything:

- It creates `paths.bin`, `paths.state` and `paths.secrets` (the last with mode 700), copies the scripts and hooks into
  `paths.bin`, and creates the record at `paths.record` from `record-template/` if nothing is there yet.
- It fills placeholders in templates with your values: `@NAME@` (`anna.name`), `@USER@` (`anna.user`), `@TZ@`
  (`anna.timezone`), `@RECORD@`, `@STATE@`, `@SECRETS@` (the paths), `@INSTANCE@` (`bot.instance`) and `@HOME@`.
  That covers the engines in `~/.claude/agents/`, the record's `CLAUDE.md` and `memory/MEMORY.md`, `~/CLAUDE.md`, the
  headless settings and the bot settings.
- It renders the timers from your times: `day.close`, `day.open`, `runs.morning`, `runs.evening` and `anna.timezone`
  (see [Timers](timers.md)).
- `relay.enabled = true` writes `~/.claude/anna-brain-settings.json` and enables `anna-relay.service`;
  `bot.enabled = true` writes `~/.claude/anna-tg-<instance>-settings.json` (only if it doesn't exist yet). Either one
  makes `bun` a requirement.

It never overwrites your config file. After you change a value, run `./install.sh` again so the timers and settings pick
it up. Scripts that read the config at run time (most of them) see the change straight away.

!!! warning "Changing a time needs install.sh"
    The timer times are written into the unit files at install time. Editing `day.open` or `runs.morning` changes nothing
    until you run `./install.sh` again.

## `[anna]`: who she is

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `name` | `"Anna"` | What she's called. The bot speaks as this name; the brain's daily session is named `<name>-YYYYMMDD`. | `install.sh` (`@NAME@`), `anna-day`, `anna-tg` (bot prompt), `anna_cfg.py` |
| `user` | `"you"` | The person she works with, as she should address them. Also the prefix of your lines in the stream (`<user>: …`), which `anna-rhythm` counts as your activity. | `install.sh` (`@USER@`), `anna-stream`, `anna-rhythm`, `anna-clock`, `anna-relay`, `anna-tg`, the hooks |
| `timezone` | `"UTC"` | Every time she writes or reads: journal, clock, stream day files, the nightly window, and the timers' `OnCalendar` zone. An IANA name like `"Europe/Berlin"`. | every script; `install.sh` renders it into the timers |

!!! note
    The `user` value is matched literally against stream lines. If you change it later, `anna-rhythm` won't count lines
    written under the old name.

## `[paths]`: where things live

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `record` | `"~/anna-record"` | Your record: journal, hosts, runbooks, planning, memory. A git repo, created from `record-template/` by `install.sh`. Your checks (`checks/`), senses (`senses/`), clock (`clock/`) and bot context (`bot/context/`) live here too. | `install.sh`, `anna-run`, `anna-clock`, `anna-checks`, `anna-body`, `anna-evening`, `anna-tg`, `backlog-age`, hooks |
| `state` | `"~/.local/state/anna"` | Runtime state, outside the record: the stream, the clock lock, the relay queue, session drafts, the Telegram chat id, `anna-run.log`. | `anna-stream`, `anna-clock`, `anna-relay`, `anna-day`, `anna-brain`, `anna-evening`, `anna-notify`, `anna-tg`, `anna-rhythm`, hooks |
| `bin` | `"~/bin"` | Where `install.sh` puts the scripts and hooks. Scripts add it to their `PATH`; `install.sh` rewrites the hook commands in `~/.claude/settings.json` to point here. | `install.sh`, most scripts (`PATH`), `anna-clock` (the `--run` command), `anna-gate-hook` |
| `secrets` | `"~/.config/anna/secrets"` | Secret files, directory mode 700. `claude-oauth` (optional: a long-lived token for headless runs) and `telegram-<instance>` (the bot token, one line). | `install.sh`, `anna-run`, `anna-notify`, `anna-tg` |

`install.sh` writes `paths.bin` into the systemd units as it installs them, so the timers find the scripts wherever
you put them. Change `bin`, then run `./install.sh` again.

## `[models]`: which model each part runs

Empty means "the harness default" (whatever `claude` picks with no `--model`). Any model name `claude --model` accepts works.

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `brain` | `""` | The brain, the long-running interactive session. Passed as `--model` when set. | `anna-brain` |
| `bot` | `"sonnet"` | The Telegram bot. Always passed as `--model`; `ANNA_TG_MODEL` overrides it. | `anna-tg` |
| `headless` | `""` | Scheduled headless runs (morning, evening, clock `--run` items). Passed as `--model` when set. | `anna-run` |

!!! note
    `anna-tg` always passes `--model "$(anna-config models.bot)"`. If you set `bot = ""`, that becomes `--model ""`.
    <!-- TODO: verify how claude treats an empty --model; anna-brain and anna-run skip the flag when empty, anna-tg doesn't. -->

## `[day]`: the brain's daily rollover

`anna-day` closes the brain's session overnight and opens a fresh one in the morning. See
[Commands](commands.md#anna-day) and [Timers](timers.md).

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `screen` | `"anna"` | Name of the `screen` session the brain lives in. Attach with `screen -r anna`. | `anna-day` |
| `close` | `"00:30"` | When the day's session is wrapped up and closed (if idle). `HH:MM`, in `anna.timezone`. Also the start of the nightly window, when the brain is expected to be away. | `install.sh` (`anna-day-close.timer`), `anna-checks` (relay check), `anna-relay` (the "wrapping up" message), `anna-idle-checkpoint` |
| `open` | `"04:15"` | When the new day's session starts. `HH:MM`, in `anna.timezone`. The nightly window ends 5 min after it (`anna-checks`). | `install.sh` (`anna-day-open.timer`), `anna-checks`, `anna-relay`, `anna-idle-checkpoint` |
| `idle_min` | `30` | Minutes without activity before `close` may wrap up. A session active more recently is left open, and the stream says so. | `anna-day` |
| `wrap` | `"/anna-wrapup overnight"` | What `close` types into the brain before `/exit`. `anna-rhythm` ignores stream lines with this text so it doesn't count them as you. | `anna-day`, `anna-rhythm` |
| `remote_control` | `false` | `true` = after `open`, type `/remote-control` into the new session (and resume with `--remote-control` after a crash). Needs a claude.ai login; lets you reach the brain from the Claude app. | `anna-day`, `anna-brain` |

## `[runs]`: scheduled headless runs

Each run is one `claude -p` session through `anna-run`, with deny-by-default settings
(`~/.claude/anna-headless-settings.json`).

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `morning` | `"04:00"` | Time of the morning run, `/anna-morning`: a read-only check, written to `journal/handoffs/<date>-morning.md` in the record. ⛔ lines under `## Needs action` notify you. | `install.sh` (`anna-morning.timer`) |
| `evening` | `"01:00"` | Time of the evening run, `anna-evening`: folds the day's session drafts and yesterday's stream into the journal. | `install.sh` (`anna-evening.timer`) |

## `[drafts]`: session drafts

When an interactive session ends, the `anna-session-draft` hook writes a raw, redacted draft of it into
`<paths.state>/drafts/` for the evening run to fold. Drafts stay outside the record.

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `secret_commands` | `["bw", "bw-session", "op", "pass", "vault", "secret-tool", "secret-put"]` | Commands whose output is never drafted. Add your own password tools here. If the key is missing entirely, only `bw` is used. | `anna-session-draft` hook |

## `[relay]`: bot to brain

The relay moves requests from the Telegram bot to the brain and results back, over two local fakechat channels. See
[The relay](../concepts/relay.md).

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `enabled` | `false` | Turn the relay on. `install.sh` then writes the brain's fakechat settings and enables `anna-relay.service`; `anna-brain` and `anna-tg` load the fakechat channel; `anna-checks` checks it. | `install.sh`, `anna-brain`, `anna-tg`, `anna-checks` |
| `brain_port` | `8791` | Local port of the brain's fakechat channel. | `anna-brain` (`FAKECHAT_PORT`), `anna-relay` |
| `bot_port` | `8792` | Local port of the bot's fakechat channel. | `anna-tg` (`FAKECHAT_PORT`), `anna-relay` |
| `alarm_min` | `30` | Minutes a hand-off may wait for a result before a ⚠ line goes to the stream (`anna-relay`) and the relay check warns (`anna-checks`). | `anna-relay`, `anna-checks` |

!!! note
    The relay and the Telegram bot have not yet been walked through on a clean machine. Expect rough edges.

## `[bot]`: Telegram

| Key | Default | What it does | Who reads it |
|---|---|---|---|
| `enabled` | `false` | Turn the Telegram bot on. `install.sh` writes the bot's settings file and tells you how to start `anna-tg@<instance>`. With `false`, `anna-notify` writes to the stream only, and `anna-day` doesn't notify on failures. | `install.sh`, `anna-notify`, `anna-day` |
| `instance` | `"ops"` | The bot instance name: lowercase letters and digits. It names the token file `<paths.secrets>/telegram-<instance>`, the state directory `<paths.state>/telegram-<instance>`, the settings `~/.claude/anna-tg-<instance>-settings.json`, the working directory `~/anna-<instance>` and the unit `anna-tg@<instance>`. | `install.sh`, `anna-tg`, `anna-notify` |

## A complete example

```toml
[anna]
name = "Anna"
user = "Sam"
timezone = "America/Chicago"

[paths]
record = "~/anna-record"

[day]
close = "23:30"
open = "06:00"

[runs]
morning = "05:45"
evening = "00:15"

[bot]
enabled = true
instance = "home"
```

Every key not listed keeps its default. After saving, run `./install.sh` again and check the timers:

```bash
systemctl --user list-timers 'anna-*'
```
