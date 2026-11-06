# Skills

This page lists every skill the scaffold ships: when it runs, what it reads, what it writes and which arguments it takes.
It's for anyone who wants to know what happens when Anna "wraps up" or "does the morning check", and for developers
changing a skill.

!!! tip "New to this?"
    A **skill** is a set of written instructions Claude Code loads when you type its name as a slash command (for
    example `/anna-wrapup`), or when a script types or passes that command for you. Each skill is one file,
    `skills/<name>/SKILL.md`. Nothing in it is a program: it tells the model what to do, step by step.

## Where skills live

| Location | What it is |
|---|---|
| `skills/<name>/SKILL.md` | The source, in your checkout of the scaffold. |
| `~/.claude/skills/<name>/` | The installed copy. `install.sh` deletes and recopies each `skills/*/` folder on every run. |
| `.claude/skills/anna-setup` | A symlink to `skills/anna-setup`, so running `claude` inside a fresh clone offers `/anna-setup` before anything is installed. |

!!! warning "Edits to installed skills are lost on update"
    `install.sh` replaces `~/.claude/skills/<name>/` each time it runs. If you change a skill, change it in the checkout
    (and keep the change as a commit there), not in `~/.claude/skills/`. See [Update after git pull](../guides/updating.md).
    Engines are handled differently: an engine you edited is kept ([Engines](engines.md)).

Every skill finds the record with `anna-config paths.record` (or runs with the record as its working directory, in the
headless runs). Times are in `anna.timezone`.

## Overview

| Skill | Started by | Interactive or headless | Changes the record? |
|---|---|---|---|
| [`/anna-setup`](#anna-setup) | you | interactive | yes: creates it |
| [`/anna-morning`](#anna-morning) | `anna-morning.timer` at `runs.morning`, or you | both | no (the headless runner commits the report) |
| [`/anna-wrapup`](#anna-wrapup) | you, or `anna-day close` at `day.close` | interactive | yes |
| [`/anna-checkpoint`](#anna-checkpoint) | you, or the `anna-idle-checkpoint` hook | interactive | yes |
| [`/anna-evening`](#anna-evening) | `anna-evening.timer` at `runs.evening` | headless only | journal and handoff only |

## anna-setup

**Runs:** when you type `/anna-setup`, or say "set up Anna", in a Claude Code session. Safe to rerun: it reads an existing
config and record and fills only what's missing.

**Reads:** the scaffold's `README.md` and `docs/`, `config/anna.example.toml`, an existing `~/.config/anna/anna.toml` and
record if there are any, `install.sh`'s output.

**Checks (read-only):** whether Anna's disk is encrypted (`lsblk -no TYPE -s "$(findmnt -no SOURCE /)"`; a `crypt`
line means LUKS). If not, it recommends full-disk encryption and encrypted off-machine backups before going on; it
doesn't block, and your answer goes into day one's journal entry. Inside a VM it asks whether the host encrypts the
storage, since that doesn't show from inside.

**Writes:**

- `~/.config/anna/anna.toml`, with only the keys that differ from the example (shown to you first).
- Runs `./install.sh`, which creates the record from `record-template/` and makes its first commit. If `git config
  user.name` / `user.email` are empty, it asks what the record's commits should be authored as and sets that in the record
  only (`git -C <record> config user.name …`), never in your global git config.
- In the record: `memory/user-<slug>.md` (who you are) and its line in `memory/MEMORY.md`; rows in `CLAUDE.md` § Hosts at
  a glance; `hosts/<name>.md` files (read-only probes such as `uname`, `uptime`, `df -h`, `systemctl --failed`, only with
  your OK); `planning/backlog.md`.
- A first check in `checks/` and a first sense in `senses/`, copied from `examples/`.
- Day one's journal entry `journal/YYYY/MM/<today>.md`, the 📌 handoff line, a commit.
- A clock note for tomorrow: `anna-clock add "tomorrow 09:00" "Read the first morning report with …"`.

**Steps:** 1 who and where, 2 which parts (rollover, morning/evening runs, bot, relay, merlin), 3 config and install,
4 start the record, 5 a first check and sense, 6 the bot (if on), 7 day one, 8 hand over.

**Won't do:** ask you to paste a token (you create the files in `paths.secrets` yourself), run `sudo` (it gives you the
`loginctl enable-linger` command), or accept Claude Code's Bypass Permissions dialog for you. The first `anna-day open` is
yours.

## anna-morning

**Runs:** headless every morning: `anna-morning.timer` (at `runs.morning`, default `04:00`) starts `anna-morning.service`,
which runs `anna-run /anna-morning morning`. Also interactively when you ask for "the morning check" or "where are we".

**Rule:** read-only. No restarts, edits or commits. In a headless run, one simple command per Bash call (no `;`, `&&`,
`cd` or pipes), because the headless allowlist refuses compound commands one by one.

**Reads:**

- The 📌 handoff line at the top of `memory/MEMORY.md`, then the newest file in `journal/handoffs/`.
- The newest one or two journal day files: headline, Day index, every `Open:` line.
- The top of `planning/backlog.md`.
- `anna-clock due`.
- The newest `journal/handoffs/*-evening.md`: its "Proposed for the next session" list.
- merlin's `index_status`, if merlin is configured.
- `anna-checks` (always tried), and `anna-body --line` for the first line.
- The engines `anna-goals` (with `anna-clock due`, `backlog-age`, `goal_status: none` unless your record has a goal tool,
  `raised: none`) and `anna-curiosity` (with the open "Ask" items, `anna-stream recent --hours 72`, `anna-rhythm`).

**Writes:** nothing itself. Its output is one screen:

```
How I feel: <anna-body --line>
## Needs action today
## Watch
## Done since last handoff
## Could not verify
Question for today: <question> (why: <why>)      ← only if anna-curiosity returned one
```

Each item is labelled **VERIFIED** (a live output line proves it), **HYPOTHESIS** (reasoned, not confirmed) or
**UNVERIFIED** (the check failed, timed out or returned nothing). The headless runner `anna-run` saves the output as
`journal/handoffs/<date>-morning.md`, commits only that file and pushes if the record has a remote.

**Alerts:** a line starting with `⛔` under `## Needs action` in the morning report makes `anna-run` send you a Telegram
message (through `anna-notify`, if installed). The skill keeps ⛔ for things that need you today: something down, a failed
backup, a security issue.

**Interactively:** it ends with the checklist and asks what to take on first.

## anna-wrapup

**Runs:**

- When you type `/anna-wrapup`, or say "wrap up" or "document the day".
- At night: `anna-day close` (timer at `day.close`, default `00:30`) types the value of `day.wrap` (default
  `/anna-wrapup overnight`) into the brain, if the brain has been idle at least `day.idle_min` minutes. It waits for the
  wrap-up to finish, then exits the session.

**Argument:** `overnight`. In overnight mode the skill asks nothing and waits for nothing: where a step would ask, it
leaves the record as it is and puts the question in the 📌 handoff line under **Ask**. It always pushes at the end if the
record has a remote. Its reply goes to the stream, not to you.

**Reads:** the record's `CLAUDE.md` (where a new thing goes), `journal/README.md` (format), the session draft
(`anna-session-draft --scan 24`, then `<paths.state>/drafts/<session id>.md`).

**Writes:**

1. The day file `journal/YYYY/MM/<day the session started>.md`: appends a `## YYYY-MM-DD (session N) — …` block with a
   Day index and one `###` per topic (`Did:` / `Hit:` / `Decided:` / `Open:`), with commands and output pasted verbatim.
   It never rewrites an earlier block.
2. Other layers, only where the session produced something: `runbooks/<topic>/`, `hosts/<host>.md` § Notes, a lesson in
   `memory/` plus its `MEMORY.md` line, `planning/backlog.md`, `planning/ideas.md`, `anna-clock add` for dated follow-ups,
   `(superseded YYYY-MM-DD: see § X)` on stale sections.
3. Calls `anna-goals` and `anna-curiosity` (step 3b). Interactively, a question may be asked now and logged with
   `anna-stream add --from curiosity`; overnight it goes under **Ask**.
4. The 📌 handoff line in `memory/MEMORY.md`.
5. `anna-session-draft --mark-folded <draft>`, so the evening fold doesn't repeat it.
6. One commit, after scanning the staged diff with `git diff --cached | grep -nEi 'token|passw|secret|api[_-]?key|BEGIN
   .*PRIVATE'`. It pushes when you say so (overnight: always, if there's a remote).
7. Locks a password manager if your setup unlocked one for the session.

## anna-checkpoint

**Runs:** when you type `/anna-checkpoint` or say "checkpoint" / "save our progress". Also when the
[`anna-idle-checkpoint` hook](hooks.md#anna-idle-checkpoint) wakes the brain after a quiet spell (20 minutes by default)
with prompts that aren't journaled yet.

**What it is:** a short wrap-up that doesn't end the session.

**Reads:** `journal/README.md`, `/anna-wrapup` step 2, the session draft (`anna-session-draft --scan 24`). The draft holds
only what wasn't folded yet, so it starts where the last checkpoint ended.

**Writes:**

- Journal: the first checkpoint of a session writes `## YYYY-MM-DD (session N) — … · checkpoint in-session (<sid[:8]>;
  session stays open, later work appends)`; later ones write `## YYYY-MM-DD (session N, continued after checkpoint K) — …`.
  Other unfolded drafts from today are folded too, oldest first, as their own blocks.
- Only missing layer updates (host fact, runbook step, lesson, backlog item, clock note).
- The 📌 handoff line, with `checkpoint N`.
- `anna-session-draft --mark-folded` for each draft it journaled.
- A commit `YYYY-MM-DD checkpoint N: <topics>` after the same secret scan; pushes if the record has a remote.

It reports in 3–5 lines and leaves the session open.

## anna-evening

**Runs:** headless only, as `/anna-evening`. `anna-evening.timer` (at `runs.evening`, default `01:00`) starts
`bin/anna-evening`, which:

1. runs `anna-session-draft --scan 36` to draft any session the SessionEnd hook missed;
2. picks yesterday's stream file `<paths.state>/stream/YYYY-MM-DD.jsonl` unless it's listed in `stream/.folded`;
3. if there are drafts or a stream file, runs `anna-run "/anna-evening <draft paths> STREAM: <stream path>" evening` with
   the state directory added as readable (`ANNA_ADD_DIR`);
4. reads the last `FOLDED:` line of the report and marks those drafts folded and the stream file done.

**Arguments:** the draft paths, then optionally `STREAM: <path>`. No drafts and no stream: it writes "no drafts", an empty
`FOLDED:` line, and stops.

**Reads:** each draft (front matter: `session`, `day`, `started`/`ended`, `transcript_lines`, `wrapped_up_in_session`),
the stream file, the day files it appends to, memory files whose topics come up.

**Writes:**

- A `## The bot and the day (Anna's stream)` section in that day's journal file: what you said, asked or decided through
  the bot, actions the bot took, clock items fired, alerts sent, relay hand-offs and results. This is the bot's only
  journal record: the bot's own sessions are never drafted.
- For each draft not already wrapped up: `## YYYY-MM-DD (session N, folded by the evening run from <session[:8]>, not
  reviewed)`, with output copied verbatim.
- The 📌 handoff line, only if a folded session left something mid-flight (marked `(evening run <date>)`).
- A commit `evening fold <date> (<n> sessions)`, pushed if there's a remote.

**Won't do:** edit host records, runbooks, memory lessons or the backlog. It lists what it would change under **Proposed
for the next session** (file, change, evidence line), plus a **Proposed → memory** list from its memory consolidation step
(contradicted, resolved-but-still-"pending" or duplicated claims). The next morning check carries those under Watch.

**Output:** what it folded where, the proposals, ⚠ anything odd, and a last line exactly `FOLDED: <path> <path> …`. A
draft left off that line stays and is retried the next night; `anna-evening` notifies you if any are left.

## Related

- [Hooks](hooks.md): the session draft, idle checkpoint and session-start hooks the skills rely on.
- [Engines](engines.md): `anna-goals` and `anna-curiosity`, which the morning check and the wrap-up call.
- [The record's layout](record-layout.md): where each skill writes.
- [Timers](timers.md): when the scheduled ones run.
