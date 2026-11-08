---
description: "What can go wrong with Anna, as symptom, check and fix, with the scripts' own messages quoted so you can search for them."
---

# Troubleshooting

This page lists what can go wrong, as symptom, check and fix. The messages are quoted from the scripts, so you can
search this page for the line you see. Most scripts also write what they did to Anna's stream: `anna-stream recent` is
often the fastest first look.

!!! note "Least-tested parts"
    The Telegram bot, the relay and headless login with a token haven't yet been walked on a clean machine. If you hit
    something there that isn't on this page, it's probably a gap in the scaffold, not something you did.

## First: run the tests

The test suites check each piece in throwaway folders (their own config, state and record); they don't touch your
install. From the clone:

```bash
cd ~/projects/anna
tests/run-all
```

You should see one line per suite and a summary:

```
ok   test_body_checks        17 ok
ok   test_clock              20 ok
...
ok   test_relay              11 ok
all suites passed
```

A failing suite prints `FAIL <suite>` with its failed checks indented under it, and `tests/run-all` exits 1. For the
full output of every suite, `tests/run-all -v`. Without bun, the relay suite is skipped (`skip test_relay … (no bun: …)`).
If the tests pass but your install misbehaves, the difference is in your machine or config, which narrows it down.

## Where to look

| What | Command |
|---|---|
| Anna's stream (every part logs here) | `anna-stream recent` (`--hours 48`, `--from anna-day`) |
| A timer's last run | `systemctl --user status anna-morning` (or `anna-evening`, `anna-day-close`, `anna-day-open`, `anna-clock`) |
| A timer's output | `journalctl --user -u anna-morning -n 50` |
| Headless run reports | `ls -t ~/anna-record/journal/handoffs/` |
| Clock `--run` tasks' output | `<paths.state>/anna-run.log` |
| The brain's screen | `screen -r anna` (detach: Ctrl-A, then D) |
| The bot's screen | `screen -r anna-tg-<instance>` |
| Which config is in use | `anna-config --path`, and `anna-config --dump` for every value |

## Install

### `install.sh: 'screen' is required (the brain lives in a screen session)`

Or the same for `python3`, `jq`, `git`, `claude`, or `bun` (`for the relay and the Telegram channel`). Install the
named program ([Requirements](new-to-this.md#requirements-and-how-to-check-each-one)) and run `./install.sh` again.
For bun: it installs into `~/.bun/bin`; open a new terminal so that's on your PATH, or turn off `bot.enabled` and
`relay.enabled` if you don't want them yet.

### `install.sh: Python 3.11+ is required`

`python3 --version` is older than 3.11 (Anna's scripts read TOML with `tomllib`, new in 3.11). Use a newer distribution
release or install a newer Python.

### `Wrote … anna.toml from the example: edit it …`

Not an error: there was no config, so the installer copied the example and stopped without installing anything.
Edit `~/.config/anna/anna.toml` and run `./install.sh` again.

### The record was created but not committed

```
install.sh: created /home/you/anna-record but couldn't commit it (git user.name/email set?)
```

Git doesn't know who to author the commit as. The record folder now exists, so the installer won't create it again:
commit it yourself, setting the name in the record only:

```bash
git -C ~/anna-record config user.name "Your Name"
git -C ~/anna-record config user.email "you@example.com"
git -C ~/anna-record add -A && git -C ~/anna-record commit -m "record: start from the Anna template"
cd ~/projects/anna && ./install.sh
```

### `install.sh: couldn't merge the hooks into ~/.claude/settings.json (left unchanged)`

Your `~/.claude/settings.json` isn't valid JSON. Check with `jq . ~/.claude/settings.json`, which names the line. Fix it
(a timestamped backup `settings.json.bak.*` sits beside it), then rerun.

### `⚠ you edited ~/CLAUDE.md: the new version is at ~/CLAUDE.md.anna-new; rerun /anna-setup to merge them, or diff by hand`

Your `~/CLAUDE.md` differs from the version the installer last put there, so it isn't overwritten. (If you had never
edited it, the update would have replaced it and said `~/CLAUDE.md updated`.) The brain reads `~/CLAUDE.md` at every
start, so bring the new parts in: rerun `/anna-setup`, which merges `~/CLAUDE.md.anna-new` with you, or copy the
sections over by hand and delete the `.anna-new` file. Same idea for `⚠ you edited: anna-goals.md (left as is; new
versions beside them as .anna-new)`: compare `~/.claude/agents/<name>.md` with its `.anna-new` and merge.

### `⚠ … memory is a real directory: move its files into … memory and replace it with a symlink by hand`

Claude Code already had a memory folder for your home directory. Move its files into `<record>/memory/`, remove the
empty folder, and rerun `./install.sh`, which then creates the symlink.

### `⚠ user lingering is off: timers stop when you log out`

Run `sudo loginctl enable-linger $USER` once. Without it, nothing runs at night unless you're logged in.

### `anna-day: command not found`

`~/bin` isn't on your PATH yet. Open a new terminal or log in again (most distributions add `~/bin` when it exists).
Check with `echo $PATH`.

### Timers run but nothing happens, `status=203/EXEC`

The unit can't find the script it runs. `systemctl --user cat anna-morning` shows the path in `ExecStart=`; compare it
with `paths.bin` (`anna-config paths.bin`). If you changed `paths.bin`, run `./install.sh` again: it writes the new path
into the units.

### `anna-config: no such key: …`

A script asked for a key that isn't in the defaults, or you typed one wrong. Every key and its spelling:
[Configuration](../reference/config.md).

## The brain

### `open: Claude Code asks you to accept Bypass Permissions mode …`

Expected the first time on each machine. `screen -dr anna`, read the dialog, choose Yes if you agree, detach (Ctrl-A, D),
run `anna-day open`. Why: [Security model § Allowlists](../concepts/security.md#allowlists).

### `open: Anna-… didn't reach the prompt in 80 s (screen -dr anna)`

Claude Code started but didn't show its ready prompt. Attach with `screen -dr anna` and look: often a login prompt, an
update notice or a question. Answer it, then use the session, or exit and run `anna-day open` again.

### `open: trust prompt for an unexpected folder; left waiting`

The trust prompt named a folder other than your home folder. `anna-day` only answers it for `$HOME`. Attach and read
it. The brain should start in `~`.

### `open: couldn't select 'Yes' on the trust prompt; left waiting`

The arrow key didn't register. Attach (`screen -dr anna`), choose "Yes, I trust this folder" yourself, detach.

### `open: yesterday's session still open; no new session`

At open, yesterday's session was still busy (active in the last `day.idle_min` minutes), so `anna-day` left it alone
instead of starting a second one. Finish your work, then `/anna-wrapup` and `/exit` in it (press **q** at the resume
prompt), and `anna-day open`.

### `close: session … active N min ago; left open`

Not an error: you were still working at `day.close`. The 04:15 open tries the close again.

### `close: wrap-up of … didn't finish in 40 min; left open`

The overnight wrap-up turn didn't end. Attach and see what it's doing; often it's waiting on something. The relay stays
paused until the next `anna-day open`.

### `claude exited 3 times within 15 s (rc …). Shell here; resume by hand: claude --resume <id>`

Claude Code crashes right at start. Run `claude --version` and `claude` in that shell to see the error (login expired,
an update, a broken setting in `~/.claude/settings.json`). Once `claude` starts, type `exit` to close the window and run
`anna-day open`.

### The brain blocks a command: `anna-gate: this looks like a state change on …`

Working as designed: the action gate's hook stopped a state change that had no recent `go` from the `anna-action-gate`
engine. The brain should call the gate and then retry, or ask you. If the hook blocks something it shouldn't (a read),
that's a bug worth reporting. The switch `<paths.state>/gate-off` turns the hook off (passes are still logged); it's
yours to use, not Anna's. [Security model § Destructive and outward actions](../concepts/security.md#destructive-and-outward-actions).

## The night runs

### No morning report

Check the timer ran: `systemctl --user status anna-morning` and `journalctl --user -u anna-morning -n 50`. The last
line of a run is `… morning exit=<rc> -> journal/handoffs/<date>-morning.md`. Common causes:

- `no record at …`: `paths.record` points to a folder that doesn't exist.
- `pull failed`: the record has a remote, and `git pull --ff-only` failed (diverged history, network, credentials).
  Run `git -C ~/anna-record pull --ff-only` yourself and fix what it says.
- No line at all: lingering is off and you weren't logged in.

### The report's first line ends in `exit 1` (or another nonzero code)

The headless session failed. The report file holds its output: read it. A login problem shows up here: run `claude -p
"say hi"` in a terminal to check your login, or make a token ([Install § token](install.md#optional-a-token-for-the-night-runs)).
With the bot on, you also got `⛔ anna-run morning failed (exit …)` on Telegram.

### The report says it couldn't run a command

Headless runs are deny-by-default: only the commands in `~/.claude/anna-headless-settings.json` run. A check you want in
the morning report belongs in `anna-checks` as a section (`<record>/checks/<name>`), not as a new allowlist entry.
[Checks and senses](../guides/checks-and-senses.md).

### `evening: run did not exit 0, drafts kept`, or `⚠ evening fold left N session draft(s) unfolded; retried tomorrow`

The fold didn't finish or didn't fold everything. Nothing is lost: the drafts stay in `<paths.state>/drafts/` and the
next night tries again. The report `journal/handoffs/<date>-evening.md` says why.

`evening: no drafts, no stream, no run` is not an error: there was nothing to fold.

## Checks and the clock

### `⛔ clock: ping/run items past due and not fired (anna-clock.timer?)`

The clock tick isn't running. `systemctl --user status anna-clock.timer` should be active; `systemctl --user enable --now
anna-clock.timer` if not. After downtime it catches up on the next tick.

### `⚠ <name>: check failed to run (exit N): …`

Your check in `<record>/checks/<name>` errored before printing an `OK`/`⚠`/`⛔` line. Run it by hand
(`~/anna-record/checks/<name>`) to see why. A check that can't run is never reported as OK.

### `⚠ <name>: no such section`, `⚠ checks: … has a built-in's name …`

The section doesn't exist or isn't executable (`chmod +x`), or your check is named `relay`, `clock` or `disk`, which are
built in and would always win: rename it.

### `anna-clock: --ping needs a time`, `anna-clock: … is in the past`, `anna-clock: can't read WHEN`

`--ping` and `--run` items need a time of day (`"fri 09:00"`, `"+2h"`); plain notes can be a date alone. WHEN is anything
`date -d` understands, plus `+3d`, `+2h`, `+90min`. [Commands](../reference/commands.md).

## The bot

### `anna-tg: no bot token at …/telegram-ops`

The token file is missing or empty. Create it as in [Telegram § Save the token](telegram.md#4-save-the-token).

### `anna-notify: no DM found; message the bot first`

Send your bot any message in Telegram, then run `anna-notify --learn` again. If the bot is already running, it's
reading the messages instead: `systemctl --user stop anna-tg@ops`, DM the bot, `anna-notify --learn`, start it again.

### `anna-notify: no chat id yet (anna-notify --learn)`, `anna-notify: send failed`

The first: run `anna-notify --learn`. The second: check the token with `anna-notify --me`; `{"ok":true,…}` means it's
fine, and the chat ID in `<paths.state>/telegram-ops.chat` may be wrong (learn it again).

### `anna-notify: the bot is off (bot.enabled = false in your config)`

Set `bot.enabled = true` in your config and rerun `./install.sh`. With the bot off, alerts go to the stream only.

### The bot doesn't answer

1. `systemctl --user status anna-tg@ops`: is it running?
2. `screen -r anna-tg-ops`: is the session waiting on a question (folder trust, login)? Answer it.
3. Did you get a pairing code back? Then you're not on its allowlist yet: [Telegram § allow only you](telegram.md#5-find-your-chat-and-allow-only-you).
4. Is the plugin installed? `claude plugin list` should list `telegram@claude-plugins-official` (with `Status: ✘
   disabled` at user scope: that's right, the bot's own settings turn it on).

### Every Claude Code session tries to start the bot

The telegram or fakechat plugin is enabled at user scope. `jq .enabledPlugins ~/.claude/settings.json` should show
`false` for both; set them to `false`. Only the bot's and the brain's own settings files turn them on.

## The relay

### `anna-relay status` shows `"brain":"offline"` or `"bot":"offline"`

- Between `day.close` and `day.open` the brain is expected to be offline (or `"paused":true` while it wraps up). Requests
  wait in the queue.
- Otherwise, the session on that side wasn't started with the relay's channel. Restart it: the bot with
  `systemctl --user restart anna-tg@ops`; the brain by typing `/exit` in it: it resumes after 10 s and reads the config
  again, relay included.
- `offline (orphaned fakechat)`: a leftover channel server holds the port. The launchers clear it on the next start, and
  the bridge clears it too.

`anna-checks relay` sums it up: `⛔ relay: bridge …` means the service isn't running (`systemctl --user status
anna-relay`); `⛔ relay: bot side …` means hand-offs will stall.

### `⚠ anna-brain: fakechat port held by a live session; relay to … won't work`

Another live Claude Code session holds the brain's port (`relay.brain_port`, default 8791), usually a second brain
window or a session started with the fakechat plugin enabled. Close it and restart the brain.

### `⚠ relay <id>: no result from the brain after N min`

The brain got the request but hasn't answered (`relay.alarm_min`, default 30). Attach to the brain and look: it may be
waiting on a confirmation or still working. `anna-relay list` shows what's open.

### `⚠ relay: more than 5 hand-offs from the bot in 2 min; intake stopped (loop?)`

The breaker tripped, usually a loop between the bot and the bridge. Look at `anna-relay list` and the bot's screen, then
`systemctl --user restart anna-relay`.

How the relay works and why these guards exist: [The relay](../concepts/relay.md).
