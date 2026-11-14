# Example pushed senses

Two small senses that push events into Anna's sense intake (`anna-senses`), from the deployment the scaffold grew out
of. Each is one script on Anna's machine, run by a timer, sending contract-v1 events with `anna-sense-send --via drop`
(same machine, no token). How senses work: `docs/concepts/senses.md`.

| Script | Sense | What it tells Anna | Run |
|---|---|---|---|
| `prometheus-alerts` | `prometheus` | an alert started or stopped firing; Prometheus itself can't be reached (dead-man) | every minute |
| `container-updates` | `updates` | one digest a day: what Watchtower auto-updated, which pinned containers have an update waiting, errors | daily |

They show the two shapes most pushed senses take: **an edge detector** (remember what was firing, send only changes, and
say so when you go blind) and **a digest** (gather a day's worth, send one message or nothing).

## Try one

```bash
cp examples/pushed-senses/prometheus-alerts ~/.local/bin/
PROMETHEUS_URL=http://<prometheus>:9090 prometheus-alerts --dry-run     # prints the events it would send
cp examples/pushed-senses/container-updates ~/.local/bin/
HOSTS="local nas" container-updates --print                              # prints the digest it would send
```

Then a user timer for each (`~/.config/systemd/user/`):

```ini
# prometheus-alerts.service
[Service]
Type=oneshot
Environment=PROMETHEUS_URL=http://<prometheus>:9090
ExecStart=%h/.local/bin/prometheus-alerts

# prometheus-alerts.timer
[Timer]
OnCalendar=*:*:00
[Install]
WantedBy=timers.target
```

```ini
# container-updates.service
[Service]
Type=oneshot
Environment="HOSTS=local nas"
ExecStart=%h/.local/bin/container-updates

# container-updates.timer: a few hours after Watchtower's own run
[Timer]
OnCalendar=*-*-* 08:00:00
Persistent=true
[Install]
WantedBy=timers.target
```

`systemctl --user enable --now prometheus-alerts.timer container-updates.timer`, then watch `anna-stream recent` for
`[sense:prometheus]` and `[sense:updates]` lines.

## Making your own from these
- **Let the source decide how loud.** Alert rules carry `anna_do` and `severity` labels, so you tune what reaches you in
  Prometheus, not in Anna. The digest maps its own findings: errors are `high`, waiting updates `normal`, routine
  auto-updates `low` + `log` (in the journal, never a message).
- **Send changes, not states.** Polling every minute and sending every firing alert would flood the intake (it rate-limits
  at 10 events per 10 minutes). Keep state, send the edge.
- **Report your own blindness.** A sense that silently stops working looks exactly like "all is well". The dead-man
  event is how Anna learns she can't see.
- **Stable ids.** The intake drops a repeat of the same id within 5 minutes; the digest uses `digest-<date>`, so a
  rerun the same day doesn't tell you twice.
