---
description: "Install Anna: clone the scaffold, let /anna-setup interview you, and check that everything is in place."
---

# Install

This page takes you from an empty machine to a running Anna: clone the scaffold, let `/anna-setup` interview you, and
check that everything is in place. It's for anyone comfortable typing commands in a terminal; if terms like SSH, git or
screen are new, read [New to this?](new-to-this.md) first.

There are two ways in. **`/anna-setup`** (recommended) is a conversation in Claude Code that writes your config, runs
the installer and starts your record with you. **By hand**, you edit the config yourself and run `./install.sh`. Both end
in the same place.

## 1. Check the prerequisites

On Anna's machine, check that each of these prints a version rather than "command not found":

```bash
python3 --version     # Python 3.11 or newer
jq --version
git --version
screen --version
claude --version
```

You should see a version line for each. If you plan to use the Telegram bot or the relay, also check `bun --version`.
Where to get a missing piece: [Requirements](new-to-this.md#requirements-and-how-to-check-each-one).

Claude Code must be logged in. Run `claude` once: if it asks you to log in, do that now, then type `/exit`.

The installer makes a git commit in your new record. If git doesn't know your name yet, `/anna-setup` asks what the
record's commits should be signed as. By hand, check first:

```bash
git config user.name; git config user.email
```

Two lines (a name and an email) mean you're set. Empty output means the first install will stop with
`install.sh: created … but couldn't commit it (git user.name/email set?)`. See [Troubleshooting](troubleshooting.md#the-record-was-created-but-not-committed).

## 2. Clone the scaffold

```bash
git clone https://github.com/kaibae19/anna ~/projects/anna
cd ~/projects/anna
```

`git clone` prints a few `Receiving objects` lines and ends without an error. `ls` in the new folder shows `install.sh`,
`bin`, `skills`, `config` and the rest.

!!! tip "New to this? What clone did"
    You now have your own copy of the scaffold in `~/projects/anna`. Updating it later is `git pull` in that folder,
    then `./install.sh` again: [Updating](../guides/updating.md).

## 3. Start Claude Code in the clone

```bash
claude
```

Claude Code starts in the scaffold folder. The first time, it asks whether you trust this folder: choose **Yes**. The
clone carries the setup skill with it (`.claude/skills/anna-setup`), so `/anna-setup` is available before anything is
installed.

## 4. Run `/anna-setup`

Type:

```
/anna-setup
```

It's a conversation, not a form: it asks a few things at a time, summarizes back, and says what it's about to do before
it changes anything. It never asks you to paste a token into the chat; it tells you the file to create instead.

### What it asks

1. **Who and where**
    - What she's called (`anna.name`; "Anna" is fine) and how she should address you (`anna.user`).
    - **What will she help with?** In your words: a home lab, a book, a research project, a small business, just company.
      From that it names the folder for the things she'll keep a record of (`record.things`, e.g. `hosts`, `chapters`,
      `clients`; default `hosts`). Not sure yet is fine: the record grows later ([A record that grows](../concepts/a-record-that-grows.md)).
    - Your timezone (`anna.timezone`, an IANA name such as `Europe/Berlin`; it suggests one from `timedatectl`).
    - Where the record lives (`paths.record`, default `~/anna-record`) and whether you want it pushed to a private
      remote. Remotes are optional; backups are not, and it says so.
    - Which machine is Anna's home (one that runs all day, with Claude Code logged in), and whether its disk is
      encrypted (a read-only check; it recommends full-disk encryption, but it's your call).
2. **Which parts** (defaults in brackets)
    - The working session's daily rollover [yes]: close at `day.close`, open at `day.open`, and optionally Remote Control
      (`day.remote_control`) so you can reach the working session (Anna's slow side) from the Claude app.
    - Morning check and evening fold [yes]: the headless runs at `runs.morning` and `runs.evening`.
    - Her own journal and the nightly dream [yes, nothing to set up]: `/anna-dream` at `runs.dream`
      ([Her own journal](../concepts/own-journal.md)).
    - Engines that run themselves [yes]: the interpretation engine from the prompt hook; the epistemic relay check stays
      off ([Engines](../reference/engines.md#engines-that-run-themselves)).
    - Pushed senses [later, unless something already sends events]: the sense intake (`senses.enabled`;
      [Senses](../concepts/senses.md)).
    - The Telegram bot [your call] and the relay [yes if the bot]. It reads the relay's trust section with you.
    - merlin, retrieval over the record [later; you'll want it within weeks of daily use]. See [merlin](../guides/merlin.md).
3. **What she'll look after**: whatever you mention, written down as it comes up. There's no inventory to fill in; she
   learns over time, and takes a full list if you offer one. For machines it may offer read-only probes (`uname`,
   `uptime`, `df -h`, `systemctl --failed`), only with your OK.
4. **A first check and a first sense** (optional): the one thing you'd most want to hear about if it went wrong. Fine to
   skip and add later.

### What it writes, and where

| What | Where |
|---|---|
| Your config, only the keys that differ from the defaults (shown to you first) | `~/.config/anna/anna.toml` |
| Everything `install.sh` writes (next section) | see below |
| Who you are and how you like to work | `<record>/memory/user-<you>.md` and its line in `memory/MEMORY.md` |
| The things she looks after (machines, chapters, clients, …) | `<record>/CLAUDE.md` § Things at a glance, `<record>/<things>/<name>.md` (`record.things`, default `hosts/`) |
| Things you want to do | `<record>/planning/backlog.md` |
| A first check and a first sense, if you want them, from `examples/` | `<record>/checks/<name>`, `<record>/senses/<name>` |
| Day one's journal entry and the handoff line | `<record>/journal/YYYY/MM/<today>.md`, the 📌 line in `memory/MEMORY.md` |
| A clock note for tomorrow: read the first morning report together | `<record>/clock/YYYY-MM.md` |

It runs `./install.sh` and reads its output with you. If git has no name or email, it sets them **in the record only**
(`git -C <record> config user.name …`) and never touches your global git config.

At the end it tells you how to reach the working session, what happens tonight and tomorrow morning, and where the record is. You
can rerun `/anna-setup` any time to add parts: it reads what exists and fills only the gaps.

!!! note "The first start of the working session is yours"
    The working session (Anna's slow side) runs Claude Code with permission prompts off (`--dangerously-skip-permissions`). Claude Code asks once per
    machine to accept that mode, and Anna leaves that choice to you. `/anna-setup` explains it before you start the
    session. Details in [step 6](#6-start-the-working-session).
    With prompts off, the action gate and Anna's own habits are the only checks on what she runs, and the gate catches a
    known list of commands, not everything ([Security](../concepts/security.md)). Use a VM of her own and snapshot it
    before the first start.

## 5. The by-hand alternative

If you'd rather not use the interview:

```bash
cd ~/projects/anna
./install.sh
```

The first run finds no config and copies the example:

```
Wrote /home/you/.config/anna/anna.toml from the example: edit it (or run /anna-setup in Claude Code), then run install.sh again.
```

It stops there: nothing else is installed yet, so your record and timers start from your own values, not the
example's. Edit the config (every key is in it, with comments; full list in [Configuration](../reference/config.md)):

```bash
nano ~/.config/anna/anna.toml
```

At least set `anna.name`, `anna.user` and `anna.timezone`. Leave `bot.enabled` and `relay.enabled` at `false` until
you've done [Telegram](telegram.md). Then run the installer again:

```bash
./install.sh
```

Rerunning is safe: `install.sh` never overwrites your config, your record, your `~/CLAUDE.md` or your bot's allowlist.
Run it again after every `git pull`.


### What `install.sh` does

Its output lists each step. A typical first run (relay and bot off):

```
Installing Anna (Anna, for you) from /home/you/projects/anna
  scripts and hooks → /home/you/bin
  skills → ~/.claude/skills (anna-checkpoint anna-dream anna-evening anna-morning anna-proposals anna-setup anna-wrapup )
  engines → ~/.claude/agents (anna-action-gate anna-curiosity anna-epistemic anna-goals anna-interpretation anna-memory )
  record created at /home/you/anna-record (git init; add a remote when you want it backed up)
  ~/.claude/anna-headless-settings.json
  hooks merged into ~/.claude/settings.json (backup kept); fakechat/telegram off at user scope
  ~/CLAUDE.md (the brain's home)
  brain memory → /home/you/anna-record/memory (symlink)
  units → /home/you/.config/systemd/user
  timers enabled
Done. Start the brain with: anna-day open   (or wait for 04:15)
```

| Step | Result |
|---|---|
| Scripts and hooks | every file in `bin/` and `hooks/anna-*` copied to `paths.bin` (default `~/bin`) |
| Skills | `~/.claude/skills/anna-*/` |
| Engines (subagents) | `~/.claude/agents/anna-*.md`. One you edited is left alone, with the new version beside it as `<name>.md.anna-new` |
| Shared data | `~/.local/share/anna/` (the default config, the bot's prompt template, the contracts) |
| The record | `paths.record`, from `record-template/`, with `git init` and a first commit. Only if it doesn't exist yet |
| Settings for the scheduled runs | `~/.claude/anna-headless-settings.json` (deny by default) |
| Working-session settings (relay on) | `~/.claude/anna-brain-settings.json` (enables fakechat for the working session only) |
| Bot settings (bot on) | `~/.claude/anna-tg-<instance>-settings.json` (deny by default). Only if it doesn't exist yet |
| Hooks | merged into `~/.claude/settings.json`, each once; a timestamped backup `settings.json.bak.*` is kept |
| The working session's home | `~/CLAUDE.md`. If you already have one, the template goes to `~/CLAUDE.md.anna-new` for you to merge |
| Working-session memory | `~/.claude/projects/<your home folder>/memory` → a symlink into `<record>/memory` |
| systemd user units | `~/.config/systemd/user/`, timers filled from your config times, then enabled |

Options: `./install.sh --no-systemd` skips the units; `./install.sh --no-enable` installs them without enabling.
Every installed piece is described in [Commands](../reference/commands.md), [Timers](../reference/timers.md) and
[Skills](../reference/skills.md).

### Turn on lingering

If the installer prints

```
  ⚠ user lingering is off: timers stop when you log out (sudo loginctl enable-linger you)
```

your timers only run while you're logged in. Fix it once:

```bash
sudo loginctl enable-linger $USER
```

Nothing is printed. Check with `loginctl show-user $USER -p Linger`, which should say `Linger=yes`.

### Optional: a token for the night runs

The morning and evening runs are headless Claude Code sessions (`claude -p`). They use your normal login, or, if the file
exists, a long-lived token from `<paths.secrets>/claude-oauth`. To make one:

```bash
claude setup-token
```

Follow its prompts; it prints a token at the end. Save it without it landing in your shell history:

```bash
umask 077
read -rs TOKEN          # paste the token, press Enter (nothing is shown)
printf '%s\n' "$TOKEN" > ~/.config/anna/secrets/claude-oauth
unset TOKEN
```

The path is `paths.secrets` (default `~/.config/anna/secrets`, mode 700). Never put the token in the config or the
record.

!!! note "Not yet tested on a clean machine"
    The headless login with this token hasn't yet been walked end to end on a fresh machine (setup, the daily rollover,
    the nightly and morning runs, the bot and the relay have). Expect rough edges here, and see
    [Troubleshooting](troubleshooting.md).

## 6. Start the working session

```bash
anna-day open
```

If `anna-day` is "not found", open a new terminal (or log out and in) so `~/bin` is on your PATH.

`anna-day open` starts a screen session called `anna` (from `day.screen`) with a window named `Anna-YYYYMMDD`, answers
Claude Code's folder-trust prompt for your home folder, and waits for the session to be ready. On success it prints a
line ending in

```
anna-day: open: Anna-20261105 started in screen anna
```

**The first time**, it stops instead with:

```
anna-day: ⚠ open: Claude Code asks you to accept Bypass Permissions mode (once per machine; docs/concepts/security.md). That's your call, not Anna's: screen -dr anna, read it, choose Yes, then anna-day open again
```

That's expected. Attach, read the dialog, decide:

```bash
screen -dr anna
```

If you choose Yes, detach with **Ctrl-A, then D**, and run `anna-day open` again. Why the session runs this way:
[Security model § Allowlists](../concepts/security.md#allowlists). If you'd rather not now, leave it: the 04:15 open will
stop at the same place, and you can answer it in the morning.

To talk to the working session, attach with `screen -r anna`. You'll see Claude Code with `bypass permissions on` at the bottom.

## 7. Check that it worked

**Files.** Each of these should exist:

```bash
ls ~/.config/anna/anna.toml ~/CLAUDE.md ~/.claude/anna-headless-settings.json
ls ~/bin/anna-day ~/bin/anna-run ~/bin/anna-config
ls ~/.claude/skills ~/.claude/agents
git -C ~/anna-record log --oneline
```

The last one shows at least `record: start from the Anna template` (plus `/anna-setup`'s commits if you used it).

**The config reads back.**

```bash
anna-config anna.name
anna-config --path
```

You should see her name and `/home/you/.config/anna/anna.toml`.

**Timers.**

```bash
systemctl --user list-timers 'anna-*'
```

You should see seven timers with their next run time: `anna-clock.timer` (every 5 minutes), `anna-tell.timer` (every 2
minutes), `anna-day-close.timer`, `anna-evening.timer`, `anna-dream.timer`, `anna-morning.timer` and `anna-day-open.timer`. With the default times, close
is 00:30, the evening fold 01:00, the dream 01:30, the morning check 04:00 and open 04:15, in your timezone. What each does: [Timers](../reference/timers.md).

**Checks.**

```bash
anna-checks
```

A header line, then one section per check, each line starting with `OK`, `⚠` or `⛔`. On a fresh install with the relay
off you'll see `OK relay: not enabled`, an `OK clock: …` line, `OK disk: / …%` and an `OK tell: …` line, plus any checks
`/anna-setup` added. `⚠ access: no entries in 7 d (no log yet)` is expected until the working session has read a
file in the record.

**The tests (optional).** From the clone:

```bash
tests/run-all
```

One line per suite and `all suites passed` at the end. The suites run in throwaway folders and don't touch your install.

## Next

- [Telegram](telegram.md): the bot and the relay, if you want Anna on your phone.
- [Your first day](first-day.md): what happens tonight, and how to read the first morning report.
