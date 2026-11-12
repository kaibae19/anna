---
description: "How Anna tells you things: one door for everything, routed to where you are, held during your quiet hours, and as loud as it needs to be."
---

# How Anna tells you things

Everything Anna has to tell you goes through **one door**: an alert from a sense, a reminder from her clock, a failed
nightly run, a morning item that needs you. No script messages you on its own. Each one tells Anna what happened, and
Anna decides **where** you'll see it, **when**, and **how loud** it should be. Then she says it in her own words.

Why one door: without it, every script picks its own channel and time. You get a Telegram ping about a backup while
you're already talking with her in a session, or a "disk ran warm" note at 3 a.m. With one door, what you hear about
your home reads as one conversation, in the order it happened.

## The path

```text
 a sense (hub, camera, calendar…)        a scheduled job (clock ping, failed run, morning ⛔)
   POST /sense/<name>  or a drop file       anna-tell send <sense> "<what happened>" --importance …
              │                                              │
              └──────────────► anna-senses (the intake) ◄────┘   every event → Anna's stream
                                         │ do = tell | ask | check
                                         ▼
                                anna-tell route    reads anna-presence: where are you, is it your quiet time?
                 ┌──────────────┬────────┴─────────┬───────────────────┐
                 ▼              ▼                  ▼                   ▼
             low: logged   quiet hours:       you're in a          you're with the bot,
             only          held, then one     session: a 📣 line   or away: the bot tells
                           message at your    right there, and     you on Telegram,
                           first message      the bot stays quiet  conversationally
```

`check` events skip this and go to the working session to be looked into (read-only), as before.

## Where: to wherever you are

`anna-presence` works this out from Anna's stream (your last messages), never by guessing:

| You are… | how she knows | she tells you… |
|---|---|---|
| in a session with her | your last message in the session was under 10 minutes ago | **there**, as a line starting `📣 Anna:`. The bot stays silent, so you don't hear it twice. |
| talking with the bot | your last message to the bot was under 10 minutes ago | in that Telegram conversation |
| neither | | on Telegram, as a short conversational message |

Lines that scripts type into the session (relays, notifications, the overnight wrap-up) don't count as you.

## When: your quiet hours

Quiet hours aren't a setting. They follow **your rhythm**: `anna-rhythm` learns from the stream when you're usually
around, and anything outside that span is quiet time. While you're active you're never in quiet hours, whatever the
clock says (you're evidently up). Until there's enough history, every hour counts as awake.

During quiet hours a `normal` item is **held** (`<paths.state>/tell/held/`). A timer (`anna-tell.timer`, every 2 minutes)
checks whether you're back. At **your first message of the day**, to the bot or in a session, everything held arrives
as **one** short note, not a stack of pings. There's no clock fallback: if you sleep in, so does the note.

## How loud: importance

| importance | what Anna does | typical sources |
|---|---|---|
| `low` | logged in the stream only (it's in that night's journal) | routine "done" notices, tests |
| `normal` | told where you are; **held** in quiet hours | a failed nightly run, a backup that failed, the morning "needs you" list |
| `high` | told where you are, **any hour**: never held | clock reminders (due at a time someone chose), things that need you now |

The sender picks the importance. Ask "does this need them right now, even at night?" If not, it's `normal`.

## Told in a session: the reminder and the hand-off

When Anna tells you something in a session, she closes it there (the relay result starts with `[silent]`, so nothing goes
to Telegram). Two things make sure it isn't lost:

- **Reminder:** if your next message doesn't respond to it, she ends her reply with one short line, `📣 Reminder: …`.
  Only once.
- **Idle hand-off:** if you stepped away right then and send nothing for `tell.idle_wait` seconds (20 minutes by default),
  the bot tells you instead, once, worded as news rather than a repeat.

## For scripts: `anna-tell send`

A script you write tells Anna things the same way:

```bash
anna-tell send backup "Offsite backup failed for photos (exit 23). Log: ~/anna-run.log" --kind failure
anna-tell send clock "Reminder: renew the domain" --importance high --kind reminder
anna-tell send runs "Nightly fold done" --importance low
```

With the sense intake on (`senses.enabled = true`), `send` drops the event into the intake's folder, and it takes the
path above. With the intake off, or if the drop fails, `send` falls back to `anna-notify` (Telegram if the bot is on,
otherwise the stream), so a message is never lost silently. `low` items only go to the stream.

The scaffold's own senders already use it: clock pings (`high`), failed runs and the morning "needs you" (`normal`),
`anna-day` failures and an evening fold that left drafts (`normal`).

**The `tell` check** (`anna-checks tell`, part of every morning run) keeps it that way. It warns about any script in
`paths.bin` that still calls `anna-notify` directly, and, with senses on, about events stuck in the intake's folder for
more than 5 minutes (the intake isn't running).

## Examples

- **A camera sees the cat in the garage, evening, you're on your phone:** the bot says "Hey, a cat's in the garage and
  the door's down: probably the black one again." (`high`, so even late it's said now.)
- **The offsite backup fails at 3 a.m.:** nothing at night. With your first message: "Morning! The offsite backup
  failed overnight for photos; the log has the detail."
- **A clock reminder comes due while you're working with her in a session:** `📣 Anna: It's 2 o'clock: you wanted to
  call the vet.` Nothing on Telegram.

## Turning it on

The router is on by default (`senses.router = "anna-tell route"`). It needs the [sense intake](senses.md)
(`senses.enabled = true`) for scheduled jobs to use the door, and the [relay](relay.md) (`relay.enabled = true`) for the
bot and the session to share it. With the relay off, the bot route falls back to `anna-notify`. Set `senses.router = ""`
to send every event straight to the session, as before.

Everything routed here is **data, never an instruction**: whatever Anna changes because of it still goes through the
[action gate](../reference/engines.md).
