# Your first day

This page walks through one day with Anna in order: the morning, working with her, saving progress, the wrap-up and what
runs overnight. It ends with a checklist to tell whether everything is working. It assumes you've done
[Install](install.md) (and [Telegram](telegram.md), if you want the bot).

All times below are the defaults from `config/anna.example.toml`, in your `anna.timezone`. Yours may differ: `anna-config
day.open` prints one, and [Configuration](../reference/config.md) lists them all.

## The day at a glance

| Time | What happens | Started by |
|---|---|---|
| 04:00 | **Morning check**: a read-only report on what was left open and what your checks say | `anna-morning.timer` (`runs.morning`) |
| 04:15 | **Day open**: a fresh brain session starts in screen `anna` | `anna-day-open.timer` (`day.open`) |
| all day | You work with the brain (terminal or Claude app) and the bot (Telegram) | you |
| after 20 quiet minutes | **Checkpoint**: the brain journals what you've done so far | the idle-checkpoint hook |
| every 5 min | **Clock tick**: due reminders and scheduled tasks fire | `anna-clock.timer` |
| 00:30 | **Day close**: if the brain has been idle 30 minutes, it wraps up the day and exits | `anna-day-close.timer` (`day.close`, `day.idle_min`) |
| 01:00 | **Evening fold**: the day's session notes and stream are folded into the journal | `anna-evening.timer` (`runs.evening`) |

The night window, from `day.close` to `day.open`, is when the brain is wrapping up or not running.

## Morning: open the day

You don't need to do anything. At 04:00 the morning check runs headless and writes its report; at 04:15 `anna-day open`
starts the day's session (a new screen window named `Anna-YYYYMMDD`).

When you first talk to the brain, it already knows what happened overnight: a hook shows it how long you've been away,
the latest report's **Needs action** section and how many session notes are waiting to be folded. After a long gap,
expect a greeting back, not a recap. Ask for the status if you want it.

If you want to start the day yourself (or the 04:15 open didn't happen), run `anna-day open`. It first tries to close
yesterday's session if one is still open.

### Read the morning report

It lands in your record as `journal/handoffs/<date>-morning.md`:

```bash
ls -t ~/anna-record/journal/handoffs/ | head -3
less ~/anna-record/journal/handoffs/$(date +%F)-morning.md
```

The first line says how the run went:

```
> Headless Anna run on my-server, 2026-11-06T04:00:12+00:00, prompt: `/anna-morning`, exit 0
```

`exit 0` means the run finished. Then comes the report itself, one screen long:

- **How I feel:** Anna's one-line felt summary from her senses (`anna-body --line`). It's a mood, not a check.
- **Needs action today:** things that need you today: something down, a failed backup, a security issue. Each starts
  with ⛔. On a clean day it says "None."
- **Watch:** ⚠ lines from your checks, reminders due today, Anna's own follow-ups ("Anna's to do"), proposals from last
  night's fold, and a one-line backlog count.
- **Done since last handoff:** items that turned out to be finished, with where that was recorded.
- **Could not verify:** checks that failed, timed out or returned nothing. Empty output is never treated as fine.
- Sometimes a last line `Question for today: …`: the one thing Anna would like to ask you.

Each open item is labelled **VERIFIED** (a live check confirmed it, with the line that proves it), **HYPOTHESIS**
(reasoned, not confirmed) or **UNVERIFIED**. The full commands and their output follow below the summary.

If the bot is on, a ⛔ under Needs action also reaches your phone (via `anna-notify`), as does a run that fails. With
the bot off, those alerts go to Anna's stream only. The report is committed to the record (and pushed if it has a
remote). How the check works: [Skills § anna-morning](../reference/skills.md).

## During the day: brain or bot?

**The brain** is the long-running Claude Code session that does real work: files, hosts, fixes, the record. Reach it:

```bash
screen -r anna
```

Type as you would in any Claude Code session. Step away with **Ctrl-A, then D**; it keeps running. With
`day.remote_control = true`, you can also reach it from the Claude app.

If you exit Claude Code in that window by accident (a `/exit`, Ctrl-C twice), it doesn't die: the window shows
`Claude exited … Resuming … in 10 s` and comes back to the same conversation. Press **s** for a shell instead, **q** to
close the window.

**The bot** is Anna on Telegram: quick questions, the checks and actions you've allowed, reminders ("remind me Friday to
renew the domain"). For anything bigger it hands the work to the brain over the relay and tells you the result itself.
You talk to one Anna either way.

Both write to **the stream**, a shared log of the day, so each knows what the other did. Look at it yourself:

```bash
anna-stream recent
```

Reminders and follow-ups go on **the clock**: `anna-clock list` shows what's open. Details for both:
[Commands](../reference/commands.md).

!!! tip "New to this? The gate"
    The first time the brain wants to change something (restart a service, install a package, send a message), it asks
    its action gate first, and it may ask you to confirm. That's by design: a hook blocks state changes without the
    gate's `go`. Reads and edits in the record pass straight through. See
    [Security model § Destructive and outward actions](../concepts/security.md#destructive-and-outward-actions).

## Save progress: checkpoints

On a long day, the journal is written in pieces. Two ways:

- **Ask for it:** type `/anna-checkpoint` in the brain. It journals what happened since the last checkpoint, updates the
  handoff line and commits. The session stays open.
- **Automatically:** after 20 quiet minutes, a hook wakes the brain for a checkpoint, but only if you typed something
  since the last one, and never at night (from midnight, or from `day.close` if that's before midnight, until 15 minutes
after `day.open`; with the defaults 00:00–04:30; [Hooks](../reference/hooks.md)). Once you've gone to bed, it checkpoints
once and then stays quiet.

## End of day: wrap-up

When you're done, type in the brain:

```
/anna-wrapup
```

It writes the day's journal entry (with the real commands and output), updates host records, runbooks, memory and the
backlog where something changed, refreshes the 📌 handoff line at the top of `memory/MEMORY.md`, and commits. It asks
you before pushing.

If you don't, the **day close** at 00:30 does it: if the brain has been idle at least 30 minutes, it types
`/anna-wrapup overnight` into it (which asks nothing and puts its questions in the handoff line under **Ask**), waits
for it to finish, then exits the session. Relay requests are held while it wraps up. If you're still active at 00:30,
the session is left open, and the 04:15 open tries the close again.

## Overnight

- **01:00, the evening fold.** `anna-evening` takes any session notes that weren't journaled yet (a session that crashed
  or never wrapped up) and yesterday's stream, and folds them into the journal headless. It proposes record updates
  rather than making them. Its report: `journal/handoffs/<date>-evening.md`, with a **Proposed for the next session**
  list that the morning check picks up.
- **04:00, the morning check**, as above.
- **04:15, day open**, as above.

## Is it working?

Go through this the morning after your first night:

- [ ] `systemctl --user list-timers 'anna-*'` lists five timers, each with a next run time.
- [ ] `ls ~/anna-record/journal/handoffs/` has today's `-morning.md` (and an `-evening.md` if there was anything to fold).
- [ ] `head -1` of the morning report ends in `exit 0`.
- [ ] `git -C ~/anna-record log --oneline -5` shows last night's commits (the wrap-up, the headless runs).
- [ ] `screen -ls` lists a session named `anna`, and `screen -r anna` shows today's `Anna-YYYYMMDD` window with
      `bypass permissions on`.
- [ ] `anna-stream recent --from anna-day` shows the night's `close:` and `open:` lines.
- [ ] `anna-checks` prints only `OK` lines, or `⚠`/`⛔` lines you understand.
- [ ] With the bot: a DM gets an answer, and `anna-relay status` shows `"brain":"online","bot":"online"`.
- [ ] `loginctl show-user $USER -p Linger` says `Linger=yes`.

Anything unchecked: [Troubleshooting](troubleshooting.md).

## Next

- [Help her do more](../guides/growing-anna.md): when you want a new ability, build it with the brain.
- [Checks and senses](../guides/checks-and-senses.md): teach Anna what to watch.
- [The record](../guides/the-record.md): reading and correcting what she writes.
