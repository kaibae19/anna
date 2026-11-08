---
description: "The systemd user timers Anna installs: what each runs and when, how to change the time, and how to read their logs."
---

# Timers

This page lists the systemd user units and timers Anna installs: what each one runs, when, which setting controls the
time, and how to check on them and read their logs. It's for you when you want to know what runs on its own, and when
something didn't.

!!! tip "New to this?"
    systemd is the part of Linux that starts and schedules programs. A **service** (`.service`) says what to run; a
    **timer** (`.timer`) says when to start its service. Anna's units are *user* units: they run as you, not as root, so
    every command takes `--user` and needs no `sudo`.

## What runs and when

| Timer | Runs | Default time | Set by |
|---|---|---|---|
| `anna-clock.timer` | `anna-clock.service` → `~/bin/anna-clock tick` | every 5 minutes (`*:0/5`) | fixed |
| `anna-morning.timer` | `anna-morning.service` → `~/bin/anna-run /anna-morning morning` | 04:00 | `runs.morning` |
| `anna-evening.timer` | `anna-evening.service` → `~/bin/anna-evening` | 01:00 | `runs.evening` |
| `anna-dream.timer` | `anna-dream.service` → `~/bin/anna-run /anna-dream dream` | 01:30 | `runs.dream` |
| `anna-day-close.timer` | `anna-day-close.service` → `~/bin/anna-day close` | 00:30 | `day.close` |
| `anna-day-open.timer` | `anna-day-open.service` → `~/bin/anna-day open` | 04:15 | `day.open` |

All times are in `anna.timezone`. With the defaults, one night looks like this:

```text
00:30  anna-day close     wrap up the brain's session (if idle) and close it; relay paused
01:00  anna-evening       fold the day's session drafts and yesterday's stream into the journal
01:30  anna-dream         sort the own journal into lately, wonders and proposals
04:00  anna-morning       read-only morning check → journal/handoffs/<date>-morning.md
04:15  anna-day open      start the new day's brain session; relay released
every 5 min  anna-clock tick   fire due pings and scheduled runs
```

Two long-running services have no timer:

| Service | Runs | Started |
|---|---|---|
| `anna-relay.service` | `~/bin/anna-relay bridge` (the bot-to-brain relay) | enabled by `install.sh` when `relay.enabled = true`; `Restart=always` after 3 s |
| `anna-tg@<instance>.service` | `screen -DmS anna-tg-<instance> ~/bin/anna-tg <instance>` (the bot) | by you, once the bot token is in place; `Restart=on-failure` after 30 s |

## Each unit in detail

### `anna-clock.timer` and `anna-clock.service`

Fires due `ping` and `run` items from Anna's clock ([`anna-clock`](commands.md#anna-clock)). The service sets
`ANNA_CLOCK_BY=tick`. `Persistent=true`: a tick missed while the machine was off runs at the next boot, and the tick
itself catches up on anything overdue. A `--run` item starts as its own transient unit, `anna-clock-run-<id>`.

### `anna-morning.timer` and `anna-morning.service`

The scheduled headless morning check: [`anna-run`](commands.md#anna-run) with the `/anna-morning` skill, label
`morning`. Output goes to `journal/handoffs/<date>-morning.md` in the record; ⛔ lines under `## Needs action` notify you.
`Persistent=true`: missed while off, it runs at the next boot. `TimeoutStartSec=40min`.

### `anna-evening.timer` and `anna-evening.service`

The nightly fold, [`anna-evening`](commands.md#anna-evening). `Persistent=true`. `TimeoutStartSec=40min`. Put
`runs.evening` after the time your late sessions usually end; drafts carry their own start day, so a fold after midnight
still files them under the right date.

### `anna-day-close.timer` and `anna-day-close.service`

[`anna-day close`](commands.md#anna-day): wraps up and closes the brain's session if it's been idle for `day.idle_min`.
`Persistent=false`: a close missed while the machine was off is skipped, not run late. `TimeoutStartSec=50min` (the
wrap-up may take up to 40 min); `KillMode=process`.

### `anna-day-open.timer` and `anna-day-open.service`

[`anna-day open`](commands.md#anna-day): starts the new day's brain session in screen `day.screen`. `Persistent=false`,
`TimeoutStartSec=50min`, `KillMode=process` (so the screen session it starts outlives the service). After a reboot, start
it by hand with `anna-day open`.

### `anna-relay.service`

The relay bridge, [`anna-relay bridge`](commands.md#anna-relay). Its `PATH` includes `~/.bun/bin` (the bridge runs under
`bun`), and it sets `ANNA_ROLE=relay`. `WantedBy=default.target`: it starts with your user session.

### `anna-tg@.service`

A template: the part after `@` is the bot instance (`bot.instance`, default `ops`). It runs
[`anna-tg`](commands.md#anna-tg) inside a detached screen session, so you can attach and watch:

```bash
screen -r anna-tg-ops
```

Detach again with **Ctrl-A** then **D**. `install.sh` doesn't enable it; when the token is in place:

```bash
systemctl --user enable --now anna-tg@ops
```

## How install.sh renders and installs them

`install.sh` (unless you pass `--no-systemd`):

1. Copies every `systemd/*.service` and `systemd/*.timer` file as is into `~/.config/systemd/user/`.
2. Renders each `systemd/*.timer.in` into a `.timer` there, filling in your config:

    | Placeholder | Key | Used in |
    |---|---|---|
    | `@CLOSE@` | `day.close` | `anna-day-close.timer` |
    | `@OPEN@` | `day.open` | `anna-day-open.timer` |
    | `@MORNING@` | `runs.morning` | `anna-morning.timer` |
    | `@EVENING@` | `runs.evening` | `anna-evening.timer` |
    | `@DREAM@` | `runs.dream` | `anna-dream.timer` |
    | `@TZ@` | `anna.timezone` | all five |

    The result is a line like `OnCalendar=*-*-* 04:15:00 Europe/Berlin`.
3. Runs `systemctl --user daemon-reload`.
4. Unless you pass `--no-enable`: enables and starts the six timers, enables `anna-relay.service` when
   `relay.enabled = true`, and prints the command to start the bot when `bot.enabled = true`.
5. Warns if user lingering is off.

So after you change a time in `anna.toml`, run `./install.sh` again: the timers are rendered at install time, not read
from the config when they fire.

!!! warning "Lingering: timers that keep running when you log out"
    User units normally stop when you log out. For Anna to run overnight, turn on lingering once:

    ```bash
    sudo loginctl enable-linger $USER
    ```

    `install.sh` prints `⚠ user lingering is off: timers stop when you log out` if it isn't on.

The unit files in `systemd/` say `%h/bin/anna-…` (`%h` is your home directory). `install.sh` replaces that with your
`paths.bin` as it copies them, so the installed units always point at the scripts it installed.

## Check on them

List Anna's timers, with the last and next run:

```bash
systemctl --user list-timers 'anna-*'
```

You should see five lines, one per timer, each with a `NEXT` time in the future. A timer missing from the list isn't
enabled: run `./install.sh` again, or `systemctl --user enable --now anna-<name>.timer`.

See one unit's state and its last few log lines:

```bash
systemctl --user status anna-morning.service
```

A oneshot service that finished cleanly shows `inactive (dead)` with `status=0/SUCCESS`. The relay and the bot should show
`active (running)`.

Check the rendered time of a timer:

```bash
systemctl --user cat anna-day-open.timer
```

## Read the logs

Each service's output goes to the user journal:

```bash
journalctl --user -u anna-morning.service --since today
journalctl --user -u anna-day-close.service -n 50
journalctl --user -u anna-relay.service -f        # follow live; Ctrl-C to stop
journalctl --user -u anna-tg@ops.service
```

Other places to look:

| What | Where |
|---|---|
| A headless run's full output | `journal/handoffs/<date>-<label>.md` in the record |
| Clock `--run` items | `<paths.state>/anna-run.log` (default `~/.local/state/anna/anna-run.log`) |
| What every part did today | `anna-stream recent` (each script writes its outcome there) |

## Run one by hand

Starting a service runs it now, exactly as its timer would:

```bash
systemctl --user start anna-morning.service
```

Or run the script directly, for example `anna-day open`, `anna-clock tick` or `anna-evening`. Stop everything Anna
schedules:

```bash
systemctl --user disable --now anna-clock.timer anna-morning.timer anna-evening.timer anna-dream.timer anna-day-close.timer anna-day-open.timer
```
