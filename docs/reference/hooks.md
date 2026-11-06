# Hooks

This page lists every Claude Code hook Anna installs: which event runs it, what it does, what it reads and writes, and how
to turn it off. It's for anyone who sees hook output in a session and wants to know where it came from, and for developers.

!!! tip "New to this?"
    A **hook** is a command Claude Code runs by itself at a fixed moment: when a session starts, when you send a prompt,
    before a tool runs, and so on. Hooks are listed in `~/.claude/settings.json`. What a hook prints can become context
    for the model, and a `PreToolUse` hook can block a tool call. You can see the installed hooks in Claude Code with
    the `/hooks` command.

## The hooks at a glance

| Event | Matcher | Command | Timeout | What it does |
|---|---|---|---|---|
| `SessionStart` | `startup` or `resume` | `anna-session-start` | 10 s | Tells a new session what happened while no one was looking. |
| `SessionEnd` | (all) | `anna-session-draft` | 30 s | Turns the session's transcript into a redacted draft for the journal. |
| `UserPromptSubmit` | (all) | `anna-stream hook` | 5 s | Logs your message to the stream; shows the session what other parts did. |
| `Stop` | (all) | `anna-stream hook` | 5 s | Logs Anna's reply to the stream. |
| `Notification` | `idle_prompt` | `anna-idle-checkpoint` | 1800 s, `asyncRewake` | Wakes the brain for `/anna-checkpoint` after a quiet spell. |
| `PreToolUse` | `Bash` or `mcp__.*` | `anna-gate-hook` | 5 s | Blocks a state change without a recent `go` from the action gate. |

The four `anna-*` hook scripts live in `hooks/`; `anna-stream` lives in `bin/`. `install.sh` copies all of them into
`paths.bin` (default `~/bin`).

## Which session each hook acts in

Every part of Anna runs Claude Code, so every part sees these hooks. Two environment variables tell them apart:

| Variable | Set by | Effect |
|---|---|---|
| `ANNA_ROLE=bot` | `anna-tg` (the bot) | The gate hook and the idle checkpoint pass. The stream hook logs Telegram messages and replies. |
| `ANNA_HEADLESS=1` | `anna-run` (morning, evening, clock runs) | Session start, session draft, idle checkpoint and the gate hook do nothing. The stream hook only adds context. |
| (neither) | the brain | Everything runs. |

The bot and headless runs have their own deny-by-default allowlists instead of the gate
([What the bot may do](../guides/bot-permissions.md)).

## How install.sh merges the hooks

The hook list lives in `hooks/settings.hooks.json`. On every run, `install.sh`:

1. creates `~/.claude/settings.json` as `{}` if it doesn't exist;
2. backs it up as `~/.claude/settings.json.bak.<YYYYmmddHHMMSS>`;
3. for each event, rewrites a leading `~/bin` in each command to your `paths.bin`, and **adds an entry only if that exact
   command isn't already listed for that event**. Your other hooks, and Anna's hooks already present, are left as they
   are;
4. sets `enabledPlugins` for `fakechat@claude-plugins-official` and `telegram@claude-plugins-official` to `false` at user
   scope, unless you already set a value (the brain and the bot enable them in their own settings files).

If the merge fails, the file is left unchanged and `install.sh` exits with an error.

## Turning a hook off

Remove its entry from `hooks.<Event>` in `~/.claude/settings.json` (back the file up first), then start a new session.

!!! warning "install.sh adds it back"
    Because the merge adds any Anna hook command that's missing, the next `./install.sh` (for example after a `git pull`)
    puts a removed hook back. There's no setting to keep one off across updates.
    <!-- TODO: verify whether a per-hook opt-out is planned. -->

The action gate has its own switch that survives updates: [the override file](#the-override-file).

---

## anna-session-start

**Event:** `SessionStart`, on `startup` and `resume`.

**What it does:** prints a short block that Claude Code adds to the session's context. It's headed `## Since the last
session (anna-session-start hook) — BACKGROUND: true when written; verify live before stating it as current` and shows:

- **Hours since the last interactive activity**, from the newest timestamp in any other transcript under
  `~/.claude/projects/*/*.jsonl` (headless transcripts, `"entrypoint":"sdk-cli"`, don't count). It reads the last
  `timestamp` entry, not the file's modification time, because Claude Code keeps appending untimestamped lines to idle
  transcripts. At **8 hours or more** it adds: greet back, don't recite the handoff, the morning run already did the check.
- **The latest headless report** in `<record>/journal/handoffs/20*-*.md`: its first line and its `## Needs action`
  section (up to 15 lines).
- **How many session drafts** wait in `<paths.state>/drafts/` for the evening fold.

**Reads:** transcripts, the record's `journal/handoffs/`, the drafts folder, the config. **Writes:** nothing.

**Quiet when:** `ANNA_HEADLESS` is set, or the config module can't be imported.

## anna-session-draft

**Event:** `SessionEnd`. Also a command, used by the skills and `anna-evening`.

**What it does:** turns a transcript into a raw, redacted Markdown draft at `<paths.state>/drafts/<session>.md`. The
draft is outside the record: raw extracts are never committed or indexed. It holds your prompts, Anna's text, each tool
call (Bash commands, file paths, skills, MCP calls) and Bash/MCP output, each capped in length. The front matter records
`session`, `day`, `started`, `ended`, `cwd`, `transcript_lines`, `prompts`, `tool_calls` and `wrapped_up_in_session`.

**Incremental:** `<paths.state>/folded.json` maps each session to the transcript lines already folded, so a resumed or
still-open session drafts only what's new.

**Skips:** headless transcripts, the bot's sessions (working directory `~/anna-<instance>`), and sessions with no tool
calls or no prompts. Output of commands listed in `drafts.secret_commands` is never drafted (the line says
`_(vault command: output not drafted)_`).

**Redaction:** merlin's patterns if `merlin.redact` is importable (set `MERLIN_PATH` to a merlin checkout), otherwise the
built-in patterns in `bin/anna_cfg.py`.

**Command use:**

```bash
anna-session-draft --scan 24              # draft every interactive transcript touched in the last 24 hours (default 36)
anna-session-draft --mark-folded <draft>  # after journaling: record its line mark, move it to <paths.state>/folded/
```

**Never fails a session:** as a hook, any error is printed to stderr and it exits 0.

## anna-stream hook

**Events:** `UserPromptSubmit` and `Stop`. The script is `bin/anna-stream`; `hook` is its subcommand.

**What it does:**

- **UserPromptSubmit:** logs your message to `<paths.state>/stream/YYYY-MM-DD.jsonl` (in the bot, only the text inside
  Telegram channel blocks), then adds as context the lines other parts of Anna wrote since this session's last turn (on
  the first turn, the last 12 hours). Headless runs get the context only.
- **Stop:** logs Anna's reply (in the bot, the text of the Telegram reply tool).

Lines are redacted and capped. A hook never blocks a prompt: any error exits 0. Full command reference:
[Commands](commands.md).

## anna-idle-checkpoint

**Event:** `Notification` with matcher `idle_prompt` (Claude Code is waiting for your input). It runs in the background
(`asyncRewake: true`, timeout 1800 s).

**What it does:** waits, then wakes the brain to run `/anna-checkpoint`, so a long day is journaled in pieces. It waits
`ANNA_IDLE_WAIT` seconds (default **1200**, 20 minutes) and wakes the session only if all of these hold:

- it's the brain (no `ANNA_ROLE`, no `ANNA_HEADLESS`);
- the transcript didn't change while it waited;
- you typed at least one prompt since the last fold mark in `<paths.state>/folded.json` (after you go to sleep it
  checkpoints once, then stays quiet);
- it's not the night window: from midnight (or from `day.close`, if that's before midnight) until 15 minutes after
  `day.open`.

To wake the session it exits 2 with the message `Idle <m> min with <user>'s prompts not yet journaled (auto-checkpoint,
anna-idle-checkpoint): run /anna-checkpoint. …`. Otherwise it exits 0 and does nothing.

**Writes:** a lock file per session in `<paths.state>/idle-checkpoint/` (one waiter per session). Any error exits 0.

**Test knob:** `ANNA_IDLE_TEST=1` makes it ask for the word `PONG` instead of a checkpoint (for throwaway sessions).

## anna-gate-hook

**Event:** `PreToolUse`, matcher `Bash|mcp__.*`.

**What it does:** in the brain, it blocks a state-changing call unless the [`anna-action-gate`](engines.md#anna-action-gate)
engine returned `verdict: go` for that host in the last **15 minutes**. The bot and headless runs pass through.

**What counts as a state change:**

- **Bash** commands matching any of: `systemctl` start/stop/restart/reload/enable/disable/mask/unmask/kill/daemon-reload;
  `reboot`, `shutdown`, `poweroff`; `apt`/`apt-get` install/remove/purge/upgrade/full-upgrade/dist-upgrade/autoremove;
  `docker` (and `docker compose`) up/down/rm/stop/start/restart/kill/pull/run/create; `docker-compose` up/down/rm/stop/
  start/restart/pull; `qm`/`pct` lifecycle verbs (start, stop, destroy, create, set, snapshot, rollback, …);
  `iptables`/`ip6tables`/`nft`/`ufw` rule changes; `zfs` destroy/rollback/set/create/rename; `ha-do`; `ha-later` (except
  `--list`); `tg-send`; `git push` with `--force` or `-f`; `gh pr|issue|release|repo` create/comment/merge/close/edit/
  delete/review; `gh api -X POST|PUT|PATCH|DELETE`.
- **Writes elsewhere:** a command run through `ssh`, `docker exec`, `pct exec` or `qm guest exec` that contains `rm`,
  `mv`, `chmod`, `chown`, `setfacl`, `tee`, `truncate`, `dd`, `mkfs`, `kill` or `pkill`. Reading there passes.
- **`sudo`** of any command not on a read-only list (`cat`, `ls`, `grep`, `journalctl`, `systemctl`, `docker`, `git`, …;
  for the ones that have write verbs, those verbs are caught by the patterns above).
- **Outward MCP tools** whose name matches `send_message`, `__reply`, `__forward`, `trash`, `delete`, `mark_*spam`,
  `create_label` or `update_label`.

Reads, edits to files, plain `git push` and other MCP tools (merlin search, for example) pass. Heredoc bodies are treated
as data (file contents), except a heredoc fed to `ssh`, which is the remote script and is checked.

**Which `go` counts:** only an `anna-gate` block inside the result of a real `anna-action-gate` call, matched by its tool
call ID (either the tool result or a task notification naming that ID). A block in Anna's own text, or one that shows up
in a command's output, doesn't count. For `ssh <host> …` the go's `audit:` line must name that host; options such as
`-o ConnectTimeout=5` and a `user@` prefix are skipped when finding the host. A local command, or a host given as a
`$variable`, accepts any go in the window.

**On allow:** the go's audit line is written to the stream with `anna-stream add --from gate`, once per go (it checks the
last two stream day files for the same line).

**On block:** the hook denies the call with this reason (shortened): `anna-gate: this looks like a state change on <host>
("<command>") and there's no go from anna-action-gate for <host> in the last 15 min. Call the anna-action-gate subagent
with the action block …, wait for its verdict, then retry. confirm-first → ask <user>, then re-gate with their yes as
asked.`

**Fails open:** if the hook itself errors, the call is allowed and `⚠ anna-gate-hook error, call allowed: …` goes to the
stream, so a bug in the hook can't lock the brain out. It never grants a permission: on allow it only stays out of the way.

### The override file

Creating `<paths.state>/gate-off` (default `~/.local/state/anna/gate-off`) turns the gate hook off. It's your switch, not
Anna's. While the file exists, every call that would have been checked passes and is logged to the stream as
`⚠ gate OFF (override file): passed <host> "<command>"`.

```bash
touch ~/.local/state/anna/gate-off     # gate off
rm ~/.local/state/anna/gate-off        # gate on again
```

The file isn't touched by `install.sh`, so it stays in effect across updates until you remove it.

## Related

- [Engines](engines.md): the action gate's input and verdicts.
- [Security model](../concepts/security.md): why the gate is enforced and the other engines aren't.
- [Skills](skills.md): the checkpoint and wrap-up the draft and idle hooks feed.
