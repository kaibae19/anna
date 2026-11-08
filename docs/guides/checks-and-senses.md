---
description: "Give Anna a new check (something she verifies) or a new sense (something she notices), from the examples to your own."
---

# Write a check or a sense

This guide shows you how to give Anna a new **check** (something she verifies, like "is last night's backup there?") and
a new **sense** (something she feels, like "the UPS is on battery"). It walks through the examples in the scaffold's
`examples/` folder, then shows how to write your own and test it.

!!! tip "New to this?"
    Both are small shell scripts that you put in your record. Anna runs them herself, with two commands:
    `anna-checks` runs every check, `anna-body` runs every sense. Each script only has to print one line in a fixed
    format. You don't need to be a programmer to adapt one of the examples: most changes are a single line near the top.

## Checks and senses: which one you want

| | Check | Sense |
|---|---|---|
| Answers | "Is this OK?" | "How does this feel?" |
| Run by | `anna-checks` | `anna-body` |
| Lives in | `<record>/checks/<name>` | `<record>/senses/<name>` |
| Prints | lines starting `OK `, `⚠ ` or `⛔ ` | JSON lines: `{"severity": 0-3, "sensation": "...", "why": "..."}` |
| Time limit | 60 s | 10 s each (12 s for all senses together) |
| If it can't run | reported as `⚠ … check failed to run` | felt as `numb` ("can't feel …") |
| Used for | the morning report's items and alerts | the morning report's first line, "How I feel: …" |

A check is the operational source: a `⛔` line in the morning run sends you a Telegram message. A sense is only how Anna
describes the same facts; the morning check never turns a sense into an item or an alert.

`<record>` is your record's folder (default `~/anna-record`). Print it with:

```bash
anna-config paths.record
```

## The rules every check follows

From `bin/anna-checks` and `record-template/checks/README.md`:

- **Read-only.** It looks; it never changes anything.
- **One line per finding**, starting with `OK `, `⚠ ` or `⛔ ` (the symbol, then a space).
- `⛔` means **needs you today** (something down, a failed backup). The morning run notifies you on it. Use `⚠` for
  everything that can wait.
- **Exit 0.** A check that exits non-zero without printing an `OK`/`⚠`/`⛔` line is reported as `⚠ <name>: check failed to
  run (exit N): …`. One that prints a finding and then exits non-zero gets an extra `⚠ <name>: check exited N`.
- **Finish within 60 seconds.** `anna-checks` kills it after that.
- A check that can't tell is never `OK`: print `⚠ … (unverified)` instead.
- The file name is the section name. Don't name one `relay`, `clock` or `disk`: those are built in, and a check with a
  built-in's name never runs (`anna-checks` warns about it).

!!! warning "Why read-only matters"
    The headless runs and the bot are allowed to run `anna-checks`, and only that one command. The commands *inside* your
    checks run without any further permission check. That's the design (a missing check becomes a new file here, never a
    wider allowlist), and it's why a check must never change anything.

## Example: the backup-age check

`examples/checks/backup-age` reports how old the newest file in a backup folder is:

```bash
#!/bin/bash
# Example check: the newest file in a backup directory must be younger than MAX_H hours. Copy to <record>/checks/backup
# and set DIR (local path, or run `ssh host find …` the same way). ⛔ when stale: a failed backup needs the user today.
DIR=${DIR:-/var/backups}; MAX_H=${MAX_H:-26}
n=$(find "$DIR" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1)
[ -n "$n" ] || { echo "⚠ backup: nothing found in $DIR (unverified)"; exit 0; }
age=$(( ($(date +%s) - ${n%%.*}) / 3600 ))
if [ "$age" -lt "$MAX_H" ]; then echo "OK backup: newest ${age}h old (${n#* })"; else echo "⛔ backup: newest is ${age}h old (${n#* })"; fi
```

Line by line:

- `DIR=${DIR:-/var/backups}` sets the folder to watch, and `MAX_H` the age limit in hours. This is the line you change.
- `find … | sort -n | tail -1` finds the newest file.
- Nothing found → `⚠ … (unverified)`: an empty folder isn't proof the backup is fine, and isn't proof it failed either.
- Younger than `MAX_H` → `OK`; older → `⛔`.

### Install it

1. Copy it into your record, under the name you want the section to have:

    ```bash
    cp ~/projects/anna/examples/checks/backup-age "$(anna-config paths.record)/checks/backup"
    ```

2. Open `<record>/checks/backup` in an editor and change the defaults on the `DIR=` line to your backup folder, for
   example `DIR=${DIR:-/srv/backups/nightly}; MAX_H=${MAX_H:-26}`.

    Change the default in the file rather than setting `DIR` in your shell: the morning run starts `anna-checks` from a
    timer, where your shell's variables don't exist.

3. Make it executable. `anna-checks` only runs files that are executable:

    ```bash
    chmod +x "$(anna-config paths.record)/checks/backup"
    ```

### Test it

Run just that section:

```bash
anna-checks backup
```

You should see something like:

```
# anna-checks 2026-11-05 09:12:03 UTC from my-server

$ backup
OK backup: newest 7h old (/srv/backups/nightly/db-2026-11-05.sql.gz)

```

Then run them all, the way the morning run does:

```bash
anna-checks
```

That prints the built-in sections (`relay`, `clock`, `disk`) and then each of yours. If you see `⚠ backup: no such
section`, the file isn't executable or isn't in `<record>/checks/`.

Try the failure path too: set `MAX_H` to `0` for one run and you should get the `⛔` line.

```bash
MAX_H=0 anna-checks backup
```

### Commit it

Your check is part of the record, so commit it:

```bash
git -C "$(anna-config paths.record)" add checks/backup
git -C "$(anna-config paths.record)" commit -m "checks: backup age"
```

## Checking another machine

The example's comment says to run `ssh host find …` the same way. A check on another machine uses ssh with a key, and
`-o BatchMode=yes` so it fails instead of waiting for a password:

```bash
#!/bin/bash
# checks/nas-backup: the newest file in the NAS's backup folder must be under 26 h old.
HOST=nas; DIR=/srv/backups; MAX_H=26
n=$(timeout 20 ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" \
      "find '$DIR' -type f -printf '%T@ %p\n' | sort -n | tail -1" 2>/dev/null)
[ -n "$n" ] || { echo "⚠ nas-backup: couldn't read $DIR on $HOST (unverified)"; exit 0; }
age=$(( ($(date +%s) - ${n%%.*}) / 3600 ))
if [ "$age" -lt "$MAX_H" ]; then echo "OK nas-backup: newest ${age}h old"; else echo "⛔ nas-backup: newest is ${age}h old"; fi
```

The `timeout 20` keeps a hung connection inside the 60-second limit. Before you rely on it, run the `ssh` part by hand
once as the same user Anna runs as, so the host key is accepted.

## The rules every sense follows

From `bin/anna-body` and `record-template/senses/README.md`:

- Print **one JSON object per line**: `{"severity": 0-3, "sensation": "<word>", "why": "<short reason>"}`.
- **Severity:** `0` pleasant or neutral, `1` mild, `2` clear, `3` needs you.
- **Finish within 10 seconds.** All senses run in parallel and the whole run gets 12 seconds.
- A sense that fails, times out or prints nothing readable is felt as **numb** (`can't feel <name>`), never as fine.
- Words that read well: pain, sore, numb, hungry, starving, peckish, fed, feverish, warm, tired, itchy, rested, sunlit,
  night, exerting.
- The file name is the sense's name. `self` is the built-in sense (this machine's uptime, load and disk); a file named
  `self` would replace it.

## Example: the UPS sense

`examples/senses/ups-nut` reads a UPS through NUT's `upsc`:

```bash
#!/bin/bash
# Example sense: a UPS through NUT (`upsc`). Copy to <record>/senses/ups, set UPS (and run it where upsc can reach it).
UPS=${UPS:-ups@localhost}
r=$(timeout 5 upsc "$UPS" 2>/dev/null) || { echo '{"severity":1,"sensation":"numb","why":"can'"'"'t feel the UPS"}'; exit 0; }
st=$(sed -n 's/^ups.status: //p' <<<"$r"); ch=$(sed -n 's/^battery.charge: //p' <<<"$r"); ch=${ch%.*}
case "$st" in
  *LB*) echo "{\"severity\":3,\"sensation\":\"starving\",\"why\":\"UPS low battery (${ch}%)\"}" ;;
  *OB*) echo "{\"severity\":$([ "${ch:-0}" -lt 50 ] && echo 3 || echo 2),\"sensation\":\"hungry\",\"why\":\"on battery, ${ch}%\"}" ;;
  *)    if [ "${ch:-100}" -lt 80 ]; then echo "{\"severity\":1,\"sensation\":\"peckish\",\"why\":\"UPS recharging, ${ch}%\"}"
        else echo '{"severity":0,"sensation":"fed","why":"on mains, battery full"}'; fi ;;
esac
```

Power reads as food: low battery is `starving` (3), on battery is `hungry` (2, or 3 under 50 %), recharging is
`peckish` (1), full on mains is `fed` (0). If `upsc` can't answer, it says `numb` itself.

To install it, change the `UPS=` default to your UPS name, then:

```bash
cp ~/projects/anna/examples/senses/ups-nut "$(anna-config paths.record)/senses/ups"
chmod +x "$(anna-config paths.record)/senses/ups"
```

## Example: the remote-host sense

`examples/senses/remote-host` feels another machine over ssh. It reads `/proc/uptime`, `/proc/loadavg` and `nproc`:

| What it finds | Severity | Sensation |
|---|---|---|
| ssh and ping both fail | 3 | `pain` ("unreachable") |
| ping answers, ssh doesn't | 2 | `numb` ("answers ping but not ssh": Anna can't tell) |
| rebooted in the last 24 h | 1 | `sore` |
| 15-minute load ≥ 1.5 per CPU | 2 | `feverish` |
| otherwise | 0 | `rested` |

Set `HOST` to the ssh name. If that name is an alias from your `~/.ssh/config` that DNS can't resolve, also set
`PING_HOST` to its address or real name; otherwise a failing ssh would make ping fail too and the host would read as
unreachable. Install one copy per machine, named after it:

```bash
cp ~/projects/anna/examples/senses/remote-host "$(anna-config paths.record)/senses/nas"
# edit: HOST=${HOST:-nas}; PING_HOST=${PING_HOST:-192.0.2.10}
chmod +x "$(anna-config paths.record)/senses/nas"
```

## Test a sense

The one-line feeling, as the morning report shows it:

```bash
anna-body --line
```

```
fine: rested (up 12.3 d, / 41%); fed (on mains, battery full); rested (nas fine)
```

When something is off, the worst sensation leads, for example `a little achy: nas rebooted 3 h ago; otherwise rested,
fed`.

The full state, one block per sense, to see exactly what each script printed:

```bash
anna-body --pretty
```

If your sense shows `numb` with `(exit N, nothing readable)`, run the script directly and check that every line it prints
is valid JSON:

```bash
"$(anna-config paths.record)/senses/ups"
```

Commit senses the same way as checks (`git -C … add senses/<name>` then `commit`).

## Write your own from scratch

A check is any executable that follows the rules above. A small one for a systemd service:

```bash
#!/bin/bash
# checks/web: the web server must be running.
s=$(systemctl is-active nginx 2>&1)
if [ "$s" = active ]; then echo "OK web: nginx active"; else echo "⛔ web: nginx is $s"; fi
```

A sense for the same thing:

```bash
#!/bin/bash
# senses/web
if [ "$(systemctl is-active nginx 2>/dev/null)" = active ]; then
  echo '{"severity":0,"sensation":"rested","why":"web server up"}'
else
  echo '{"severity":2,"sensation":"sore","why":"web server down"}'
fi
```

Put each in its folder, `chmod +x`, run `anna-checks web` or `anna-body --pretty`, and commit.

!!! tip "Let Anna write it"
    You can also ask the brain: "add a check that the nightly backup on the NAS is under a day old". It copies the closest
    example, adapts it, runs `anna-checks` and shows you the output. `/anna-setup` does the same for your first check and
    sense.
