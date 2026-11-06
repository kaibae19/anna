# Commands

This page describes every script Anna installs into `paths.bin` (default `~/bin`): what it's for, its exact usage, the
files it touches, who runs it, and an example. It's for you when you run a command by hand, and for developers who need
the details. The hooks in `hooks/` are on [Hooks](hooks.md); the timers that run these scripts are on [Timers](timers.md).

!!! tip "New to this?"
    Each of these is a small program you run in a terminal by typing its name. `install.sh` copies them into `~/bin`.
    If your shell says `command not found`, `~/bin` isn't on your `PATH`: log out and back in, or run them as
    `~/bin/anna-clock …`. Most print their usage when you run them with no arguments.

All scripts read your settings through [`anna-config`](#anna-config); the keys are on [Configuration](config.md).

| Command | In one line |
|---|---|
| [`anna-body`](#anna-body) | how Anna feels, from your senses (read-only) |
| [`anna-brain`](#anna-brain) | runs the brain's `claude` in its screen window, resuming after a stray exit |
| [`anna-checks`](#anna-checks) | fixed, read-only checks: relay, clock, disk, plus yours |
| [`anna-clock`](#anna-clock) | Anna's own schedule: notes, pings, scheduled runs |
| [`anna-config`](#anna-config) | read the configuration |
| [`anna-day`](#anna-day) | the brain's daily rollover: close overnight, open in the morning |
| [`anna-evening`](#anna-evening) | the nightly fold of session drafts into the journal |
| [`anna-notify`](#anna-notify) | send you a Telegram message (or a stream line with no bot) |
| [`anna-relay`](#anna-relay) | the bot-to-brain relay: bridge daemon and queue tools |
| [`anna-rhythm`](#anna-rhythm) | when you're usually around, computed from the stream |
| [`anna-run`](#anna-run) | one headless Anna session with deny-by-default settings |
| [`anna-stream`](#anna-stream) | Anna's shared log of the day, and its hook |
| [`anna-tg`](#anna-tg) | the Telegram bot session |
| [`backlog-age`](#backlog-age) | open backlog items with their age in days |

## `anna-body`

How Anna "feels", from your systems' state. Read-only. It isn't a monitor (that's [`anna-checks`](#anna-checks)); it's a
short felt summary the morning report opens with.

```text
anna-body [--pretty | --line]
```

| Flag | Output |
|---|---|
| (none) | the body state as one line of JSON |
| `--pretty` | the same JSON, indented |
| `--line` | only the one-line feeling |

**Senses.** A built-in `self` sense looks at this machine: rebooted less than an hour ago (`sore`), 15-minute load of 1.5
or more per CPU (`feverish`), root filesystem 90% or more full (`tired`), otherwise `rested`. Every executable file in
`<paths.record>/senses/` is another sense. A sense prints one JSON object per line:

```json
{"severity": 0, "sensation": "fed", "why": "battery 98%"}
```

Severity 0 is pleasant or neutral, 1 mild, 2 clear, 3 needs you. Senses run in parallel; each gets 10 s and the whole
run 12 s. A sense that fails, times out or prints nothing readable is felt as `numb` ("can't feel X"), never as fine.
It always exits 0. How to write a sense: [Write a check or a sense](../guides/checks-and-senses.md).

**Reads:** `<paths.record>/senses/`, `/proc/uptime`, `/proc/loadavg`, the root filesystem. **Writes:** nothing.

**Called by:** the `/anna-morning` skill (`anna-body --line`, allowed in the headless settings); the bot may run it
(`anna-body*` is in the bot's allowlist); `/anna-setup` when you add your first sense.

```bash
anna-body --line
```

```text
fine: rested (up 3.2 d, / 41%)
```

## `anna-brain`

Runs the brain's `claude` in its screen window. `anna-day open` starts it; you can also run it by hand inside screen.

```text
anna-brain NAME [SESSION_ID]
```

- `NAME` is the session name (`anna-day` uses `<anna.name>-YYYYMMDD`).
- With `SESSION_ID`, it resumes that conversation (`claude --resume`); without, it starts a new one with a fresh id.

It runs `claude --dangerously-skip-permissions -n NAME`, plus `--model <models.brain>` if set. If claude exits without
`anna-day`'s stop marker (a stray Ctrl-C or Ctrl-D, a `/exit` you typed), the window stays and it resumes the same
conversation after 10 s. While it waits you can press **Enter** (resume now), **s** (a shell; it prints the command to
resume later) or **q** (close the window). Three exits within 15 s each count as a crash loop: it stops retrying and
gives you a shell with the `claude --resume <id>` command to run.

With `relay.enabled = true` it also loads the fakechat channel on `relay.brain_port`
(`--settings ~/.claude/anna-brain-settings.json --channels plugin:fakechat@claude-plugins-official`), and clears an
orphaned fakechat server from that port before every launch (`anna-relay clear-port brain`). With
`day.remote_control = true`, a resume adds `--remote-control`. It reads these settings again before every resume, so a
change (turning the relay on, a new model) takes effect at the next `/exit` without closing the window.

**Reads:** config (`paths.state`, `paths.bin`, `models.brain`, `relay.*`, `day.remote_control`), the session transcript
under `~/.claude/projects/` (to tell resume from new). **Writes:** removes `<paths.state>/brain-stop` when it stops on it.

**Called by:** [`anna-day open`](#anna-day).

```bash
anna-brain Anna-20261105 2b1f6c1e-1d2a-4c43-9f0e-3a7d5e8b9c10
```

## `anna-checks`

Fixed, read-only checks for the morning report, the bot and you.

```text
anna-checks [section...]
```

With no arguments it runs every section: the built-ins, then yours. Name sections to run only those.

| Built-in section | What it checks |
|---|---|
| `relay` | If `relay.enabled`: `anna-relay.service` active, `anna-relay status` readable, bot side online, brain side online outside the nightly window (`day.close` to `day.open` + 5 min), and no hand-off waiting longer than `relay.alarm_min`. Disabled: `OK relay: not enabled`. |
| `clock` | No `ping`/`run` clock items past due and still open (that would mean `anna-clock.timer` isn't running). |
| `disk` | This machine's root filesystem: ⚠ from 85%, ⛔ from 95%. |

**Your checks:** every executable in `<paths.record>/checks/` is a section named after the file. A check must be
read-only, print one line per finding starting with `OK `, `⚠ ` or `⛔ ` (⛔ = needs you today: the morning run notifies
on it), and exit 0. It gets 60 s. A check that fails to run is reported as ⚠ (unverified), never as OK. A check with a
built-in's name never runs; you get a ⚠ asking you to rename it. How to write one:
[Write a check or a sense](../guides/checks-and-senses.md).

Allowlist this one command for headless runs and the bot, never the commands inside the checks: that's how the
shipped settings do it.

`anna-checks --in-night HHMM CLOSE OPEN` prints `1` or `0` (inside the nightly window or not). It exists for the tests.

**Reads:** config, `<paths.record>/checks/`, `anna-relay status`, `anna-clock due`, `df`. **Writes:** nothing.

**Called by:** the `/anna-morning` skill (first thing it verifies with), the bot (`anna-checks*` is allowlisted), you.

```bash
anna-checks disk clock
```

```text
# anna-checks 2026-11-05 08:12:40 UTC from my-server

$ disk
OK disk: / 41%

$ clock
OK clock: 2 item(s) due
```

## `anna-clock`

Anna's own schedule. Anything with a date ("check tomorrow", "expires on the 17th") goes here, not only into prose.

```text
anna-clock add WHEN [--ping|--run] TEXT
anna-clock list [--all]
anna-clock due [--days N]
anna-clock done ID [note]
anna-clock cancel ID [note]
anna-clock tick
```

| Subcommand | What it does |
|---|---|
| `add WHEN TEXT` | A **note**: shows in the morning check from its day on. |
| `add WHEN --ping TEXT` | A **ping**: a message to you at that time, through [`anna-notify`](#anna-notify). Needs a clock time. |
| `add WHEN --run TEXT` | A **run**: a headless [`anna-run`](#anna-run) with TEXT as the task, at that time. Needs a clock time. |
| `list` | Open items. `--all`: every line, closed ones included. |
| `due` | Open items due by today (overdue included). `--days N`: due by today + N. |
| `done ID [note]` | Mark an item done, with an optional note. |
| `cancel ID [note]` | Cancel an item. |
| `tick` | Fire due ping and run items. `anna-clock.timer` runs it every 5 minutes; it catches up after downtime; a ping or run that fires more than an hour late says so in its message (`(late: was due …)`). |

`WHEN` takes anything GNU `date -d` reads, plus shorthands: `"2026-10-21"`, `"2026-10-21 09:00"`, `"tomorrow 09:00"`,
`mon`, `+3d`, `+2h`, `+90min`. Without a clock time (or `+Nh`/`+Nmin`) the item is date-only. A time in the past is
refused. `ID` is the four hex digits after `#`, with or without the `#`.

**Files.** One Markdown file per due month, `<paths.record>/clock/YYYY-MM.md`, one line per item:

```text
- [ ] 2026-10-21 09:00 ping #a3f2 text (added 2026-10-18 by session)
```

Date-only items have `--:--` as the time. States: `[ ]` open, `[x]` done or fired, `[-]` cancelled; closing appends
` — <what happened>`. Every change commits just that month file in the record (and pushes if there's a remote; a failed
push is reported, not fatal). A lock, `<paths.state>/clock.lock`, keeps the tick, you and the bot from writing at once.
Changes also go to the stream. A `--run` item starts as a transient user unit `anna-clock-run-<id>`, logs to
`<paths.state>/anna-run.log` and writes `journal/handoffs/<date>-clock-<id>.md`.

`$ANNA_CLOCK_BY` names who added an item (default `session`; the bot sets `bot`).

**Called by:** `anna-clock.timer` (`tick`); the brain and the bot (`add`, `list`, `due`, `done`, `cancel` are in the bot's
allowlist); the `/anna-morning`, `/anna-wrapup` and `/anna-checkpoint` skills; `anna-checks` (`due`).

```bash
anna-clock add "tomorrow 09:00" --ping "Check the backup finished"
```

```text
added #5c1e 2026-11-06 09:00 ping: Check the backup finished
```

```bash
anna-clock due
```

```text
#5c1e 2026-11-06 09:00 ping Check the backup finished (added 2026-11-05 by session)
```

## `anna-config`

Reads Anna's configuration. Every other script uses it.

```text
anna-config KEY
anna-config --dump
anna-config --path
anna-config --help
```

| Form | Output |
|---|---|
| `KEY` | One value; dotted key such as `relay.brain_port`. A leading `~` is expanded; booleans print `true`/`false`; lists and tables print as JSON. Unknown key: exit 2. |
| `--dump` | The merged config (defaults + yours) as JSON. |
| `--path` | The config file in use, or `<path> (missing: defaults only)`. |
| `--help`, `-h` | Usage. With no argument at all it prints usage and exits 2. |

**Reads:** `$ANNA_CONFIG` or `~/.config/anna/anna.toml`, plus the defaults file. Details:
[Configuration](config.md#how-values-are-read).

```bash
anna-config paths.record
```

```text
/home/you/anna-record
```

### `anna_cfg.py`

Not a command: the shared helper the Python scripts and hooks import (`from anna_cfg import CFG, get, path, TZ, USER,
redact`). It runs `anna-config --dump` once, gives `get("dotted.key", default)` and `path(...)`, the constants `TZ`,
`USER`, `NAME`, `STATE`, `RECORD`, and `redact()`: merlin's redaction if `MERLIN_PATH` points at a merlin checkout,
else a built-in set of secret patterns. If the config can't be read it falls back to defaults, so a hook never breaks.

## `anna-day`

The daily rollover of the brain's session: wrapped up and closed overnight, a fresh session started in the morning.

```text
anna-day close
anna-day open
```

**`close`** finds the interactive claude running in screen `day.screen`. If it was idle for at least `day.idle_min`
minutes, it pauses the relay (`<paths.state>/relay/paused`), types `day.wrap` (default `/anna-wrapup overnight`) into it,
waits for the turn to end (the reply line in the stream, then 90 s quiet; at most 40 min), then types `/exit`. A busy
session is left open and the stream says so. A session that was never used is closed without a wrap-up.

**`open`** retries `close` first if a session is still open (and gives up for today if that one is still busy). Then it
starts screen `day.screen` if needed, opens a new window running `anna-brain <anna.name>-YYYYMMDD` in your home directory,
answers Claude Code's folder-trust prompt (only for your home directory), and waits up to 80 s for the prompt. With
`day.remote_control = true` it types `/remote-control` and waits for the confirmation. Last, it removes the relay's
`paused` file so queued hand-offs go to the new session.

It types with `screen -X stuff` and reads the screen with `screen -X hardcopy`.

!!! warning "The one-time Bypass Permissions prompt"
    The first time on a machine, Claude Code asks you to accept Bypass Permissions mode. `anna-day open` won't answer
    that for you: it stops and tells you. Attach with `screen -dr anna`, read it, choose Yes, then run `anna-day open`
    again. Why: [Security](../concepts/security.md).

Every outcome goes to the stream; failures also go to [`anna-notify`](#anna-notify) when `bot.enabled = true`. With no
argument it prints usage and exits 2.

**Reads:** config (`day.*`, `anna.name`, `anna.timezone`, `paths.*`, `bot.enabled`), `~/.claude/sessions/*.json`, the
session transcript. **Writes:** `<paths.state>/brain-stop` (tells `anna-brain` the `/exit` is meant),
`<paths.state>/relay/paused`.

**Called by:** `anna-day-close.timer` and `anna-day-open.timer`; you (`anna-day open` after install).

```bash
anna-day open
anna-stream recent --from anna-day --max 3
```

```text
- Thu 08:20 [anna-day] open: Anna-20261105 started in screen anna
```

## `anna-evening`

The nightly fold (Anna's sleep). No arguments.

```text
anna-evening
```

1. Drafts any interactive session the SessionEnd hook missed (a crash, a session still open):
   `anna-session-draft --scan 36`.
2. If there are drafts in `<paths.state>/drafts/` or yesterday's stream file hasn't been folded yet, runs
   `anna-run "/anna-evening <drafts> STREAM: <file>" evening` with the state directory readable (`ANNA_ADD_DIR`).
   Nothing to fold: no run.
3. Reads the run's report, `journal/handoffs/<date>-evening.md`. If the run didn't exit 0, the drafts are kept. Otherwise
   it retires the drafts named on the report's `FOLDED:` line (`anna-session-draft --mark-folded`) and adds the stream
   file to `<paths.state>/stream/.folded`.
4. Drafts left over are retried the next night; it tells you through `anna-notify`.

**Called by:** `anna-evening.timer` (`runs.evening`). The fold itself is the `/anna-evening` skill
([Skills](skills.md)).

```bash
anna-evening
```

```text
2026-11-06T01:00:02+00:00 evening: no drafts, no stream, no run
```

## `anna-notify`

Sends you a message over the bot (Telegram `sendMessage`). For scripts' alerts and clock pings.

```text
anna-notify "text"
anna-notify --me
anna-notify --learn
```

| Form | What it does |
|---|---|
| `"text"` | Send `text` to your chat, then log it to the stream as `<sender> → Telegram`. |
| `--me` | Check the token (`getMe`): prints `{"ok":true,"bot":"…","name":"…"}`. |
| `--learn` | Store the chat id of the most recent private message to the bot. DM the bot first, and run this before the bot session is polling: Telegram allows only one reader of a bot's updates at a time. |

With `bot.enabled = false`, a message goes to the stream only (as `<sender> (no bot)`) and it exits 0; `--me` and
`--learn` exit 2. `$ANNA_NOTIFY_FROM` names the sender (`clock #a3f2`, `anna-run morning`, …).

**Reads:** the token `<paths.secrets>/telegram-<bot.instance>` (one line). The token reaches `curl` through a config on
stdin, never the command line. **Writes:** the chat id to `<paths.state>/telegram-<instance>.chat` (`--learn`; not a
secret).

**Called by:** `anna-clock tick` (pings), `anna-run` (failed runs, ⛔ lines), `anna-evening` (drafts left), `anna-day`
(failures), `/anna-setup` (first test).

```bash
anna-notify --learn
anna-notify "hello from Anna"
```

```text
stored chat for ops: Sam (@sam_example)
```

## `anna-relay`

The relay between the bot and the brain over two fakechat channels: the brain does the work, the bot speaks. Runs under
`bun`. Background and trust caveats: [The relay](../concepts/relay.md).

```text
anna-relay bridge
anna-relay status
anna-relay list [DIR...]
anna-relay send TEXT
anna-relay clear-port brain|bot
```

| Subcommand | What it does |
|---|---|
| `bridge` | The daemon (`anna-relay.service`): holds both fakechat websockets, moves messages, keeps the queue. |
| `status` | JSON: `brain` and `bot` (`online`, `offline`, `offline (orphaned fakechat)`), `paused`, counts (`new`, `brain_open`, `out`, `done`) and `oldest_open`. |
| `list [DIR...]` | Items in `new`, `brain`, `out` or `done`, one per line (tab-separated: dir, id, from, text). Default: the open ones (`new brain out`). |
| `send TEXT` | Queue TEXT for the brain as if from a script (tests, scheduled jobs). Prints the new id plus the status. |
| `clear-port brain\|bot` | Kill an orphaned fakechat server on that side's port. Exit 1 if a live session holds it. `anna-brain` and `anna-tg` run it before starting claude. |

How a hand-off flows: the bot calls `reply` on its own fakechat with a message starting `RELAY:`; the bridge queues it in
`new/` and posts it into the brain's fakechat as `[relay <id> from the bot] …`; the brain answers with its own `reply`
(`reply_to` = the id); the bridge stores it in `out/` and posts it to the bot, which tells you on Telegram in its own
words. Messages starting `[progress]` are interim. Only explicit `RELAY:` hand-offs count; more than 5 in 2 minutes opens
a breaker that stops intake until you restart the bridge. While `paused` exists (`anna-day close` to `open`) nothing is
pushed to the brain, and the bot is told once that the request is queued. A hand-off with no result after
`relay.alarm_min` writes a ⚠ line to the stream.

**Files:** the queue, `<paths.state>/relay/{new,brain,out,done}/<id>.json` (`ANNA_RELAY_DIR` overrides). State changes
are atomic renames; nothing is deleted. **Reads:** `relay.brain_port`, `relay.bot_port`, `relay.alarm_min`, `anna.user`,
`anna.timezone`, `day.close`, `day.open`. Test overrides: [Configuration](config.md#environment-variables).

**Called by:** `anna-relay.service` (`bridge`), `anna-brain` and `anna-tg` (`clear-port`), `anna-checks` (`status`;
`anna-relay status` is also allowed in headless runs).

```bash
anna-relay status
```

```text
{"brain":"online","bot":"online","paused":false,"new":0,"brain_open":0,"out":0,"done":12,"oldest_open":null}
```

!!! note
    The relay and the bot have not yet been walked through on a clean machine.

## `anna-rhythm`

When you're usually around, computed from the stream so no model has to guess or do date arithmetic. Input for the
curiosity and goals engines ([Engines](engines.md)).

```text
anna-rhythm [--days N] [--min-share F]
anna-rhythm --json
```

| Flag | Default | Meaning |
|---|---|---|
| `--days N` | `28` | How many days of stream to look at. |
| `--min-share F` | `0.3` | An hour counts as active for a weekday if you wrote in it on at least this share of that weekday's observed days. |
| `--json` | | The same as JSON. |

Activity = a stream line whose text starts `<anna.user>: ` (your messages to the bot or the brain), minus what scripts
type into the session (the `day.wrap` command, relays, task notifications). Output fields: `now`, `last_active`,
`gap_now`, `typical`, `today`, `by_weekday` (each with `n=` observed days, so few samples are visible) and `asked_today`
(whether a `curiosity` line was written today).

**Reads:** `<paths.state>/stream/*.jsonl`. **Writes:** nothing.

**Called by:** the `/anna-morning` and `/anna-wrapup` skills; the brain (its `CLAUDE.md` tells it to); allowed in
headless runs.

```bash
anna-rhythm --days 14
```

```text
rhythm (stream 2026-10-23..2026-11-05, 14 observed days, Sam's messages, UTC; window = hours with messages on ≥30% of that weekday's days)
now: Thu 2026-11-05 08:30
last_active: Thu 2026-11-05 08:12 (session)
gap_now: 0 h 18 min
typical: 07–10, 19–22
today: Thu 07–10 (n=2)
by_weekday: Mon 07–09 (n=2); Tue 19–22 (n=2); …
asked_today: no
```

## `anna-run`

One headless Anna session (`claude -p`) with deny-by-default settings. Every scheduled run goes through it.

```text
anna-run PROMPT [LABEL]
```

- `PROMPT` is what the session is asked (a skill like `/anna-morning`, or a task).
- `LABEL` names the output (default `run`).

What it does: changes into the record, pulls (`git pull --ff-only`, if there's a remote), runs
`claude -p PROMPT --settings ~/.claude/anna-headless-settings.json --output-format text` (plus `--model <models.headless>`
if set, and `--add-dir $ANNA_ADD_DIR` if set) with a 30-minute limit, and writes the output to
`journal/handoffs/<date>-<LABEL>.md`. The first line of that file records the host, time, prompt and exit code. It
commits only that file (and pushes if there's a remote), logs one line to stdout and one to the stream, and sets
`ANNA_HEADLESS=1` so the session hooks stay quiet.

**Auth:** `<paths.secrets>/claude-oauth` if present (a long-lived token from `claude setup-token`), else your normal
`claude` login.

**Alerts** (if `anna-notify` is installed): a run that exits non-zero, and, for `morning` and `clock-*` runs, up to five
⛔ lines under `## Needs action` in the output.

**Called by:** `anna-morning.service` (`anna-run /anna-morning morning`), `anna-evening`, `anna-clock tick` (`--run`
items, label `clock-<id>`).

```bash
anna-run "/anna-morning" morning
```

```text
2026-11-05T04:03:41+00:00 morning exit=0 -> journal/handoffs/2026-11-05-morning.md
```

!!! note
    Headless login (`claude-oauth`) has not yet been walked through on a clean machine.

## `anna-stream`

Anna's shared short-term memory: one running log of the day that every part of Anna writes and reads. The bot, the brain,
the scripts and the scheduled runs each know only their own conversation; the stream is how each sees what the others did.

```text
anna-stream add [--from SRC] [--for brain] TEXT
anna-stream recent [--hours H] [--max N] [--from SRC]
anna-stream hook
```

| Subcommand | What it does |
|---|---|
| `add TEXT` | Append a line. `--from SRC` names the source (default `$ANNA_ROLE`, else `session`). `--for brain` marks it as a hand-off for the brain to pick up (the only value allowed). `--from gate` is the action gate's audit line, written by `anna-gate-hook`. |
| `recent` | Print recent lines: last `--hours` (default 24), at most `--max` (default 30), filtered by `--from`. |
| `hook` | The Claude Code hook (UserPromptSubmit and Stop). On a prompt it logs your message and adds, as context, the lines other parts wrote since this session's last turn (first turn: the last 12 h). On Stop it logs Anna's reply. Behaviour follows the role: `ANNA_ROLE=bot`, `ANNA_HEADLESS=1` (context only, nothing logged), else the interactive session. A hook never blocks a prompt: any error exits 0. |

**Files:** `<paths.state>/stream/YYYY-MM-DD.jsonl` (local day in `anna.timezone`), one JSON object per line:
`{"ts", "from", "sid"?, "for"?, "text"}`. Text is redacted and capped at 600 characters. `<paths.state>/stream-seen/`
remembers each session's last turn.

**Called by:** the hook entries in `~/.claude/settings.json` (see [Hooks](hooks.md)); almost every script (`add`); the
bot (`add`, `recent` are allowlisted); the skills (`recent --hours 72`, `add --from curiosity`).

```bash
anna-stream add --for brain "Sam asked for the printer to be checked; bot couldn't reach it"
anna-stream recent --hours 2
```

```text
- Thu 08:31 [session → for the brain] Sam asked for the printer to be checked; bot couldn't reach it
```

## `anna-tg`

The bot: one Claude Code session on the Telegram channel.

```text
anna-tg [INSTANCE] [--print-prompt]
```

- `INSTANCE` defaults to `bot.instance`; lowercase letters and digits only.
- `--print-prompt` prints the system prompt the bot would get and exits (put it second: `anna-tg ops --print-prompt`).

It builds the prompt from the scaffold's `bot/prompt.md` (or `~/.local/share/anna/bot/prompt.md`), fills in your name,
user, record path and timezone, and appends every file in `<paths.record>/bot/context/` (except `README*`) as its own
section: your rooms, devices, tools, whatever the bot should know without looking it up. Then it changes into
`~/anna-<instance>` (so its chats stay out of the brain's) and runs
`claude --model <models.bot> --channels plugin:telegram@claude-plugins-official --settings ~/.claude/anna-tg-<instance>-settings.json --append-system-prompt <prompt>`.
With `relay.enabled = true` it also loads fakechat on `relay.bot_port`, after clearing an orphaned server from that port.
It sets `ANNA_ROLE=bot` and `ANNA_CLOCK_BY=bot`.

**Reads:** the token `<paths.secrets>/telegram-<instance>`; the channel state `<paths.state>/telegram-<instance>`.
`ANNA_TG_MODEL` overrides the model. What the bot may run: [What the bot may do](../guides/bot-permissions.md).

**Called by:** `anna-tg@<instance>.service`, which runs it in a detached screen session `anna-tg-<instance>`.

```bash
anna-tg ops --print-prompt | less
```

!!! note
    The Telegram bot has not yet been walked through on a clean machine.

## `backlog-age`

Open backlog items with their age in days, precomputed for the goals engine so no model does date arithmetic.

```text
backlog-age [--min-days N] [--file PATH]
```

| Flag | Default | Meaning |
|---|---|---|
| `--min-days N` | `0` | List only items at least N days old. |
| `--file PATH` | `<paths.record>/planning/backlog.md` | Read another file. |

It reads entries of the form `- **(YYYY-MM-DD) title:** …`, skips done ones (✅ or a `~~struck~~` title in the bold lead),
and lists an open item with ✅ further on as `(part done: ✅ in its text)`. Age is days since the entry's date, not
"untouched for": an item edited in place keeps its date. Oldest first; `none` if nothing matches.

**Called by:** the `/anna-morning` skill (`backlog-age --min-days 14`) and `/anna-wrapup`; allowed in headless runs.

```bash
backlog-age --min-days 14
```

```text
21d  2026-10-15  Replace the UPS battery
```
