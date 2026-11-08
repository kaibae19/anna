---
description: "Senses are how the world reaches Anna: polled senses she reads herself, and pushed senses that send her events in one standard contract, over HTTP, a drop folder or MQTT."
---

# Senses: how the world reaches her

A sense is how something outside Anna's own work reaches her: a sensor reading, a home automation, a calendar, mail, a
camera. Senses are one of her modules ([How Anna is built](architecture.md)). There are two kinds.

**Polled senses** ship in the scaffold today. They're small scripts in the record's `senses/` folder that Anna runs
herself (`anna-body`), each printing a JSON sensation ("the UPS is on battery"). [Write a check or a sense](../guides/checks-and-senses.md)
shows how to add one.

**Pushed senses** send Anna an event when something happens, so she doesn't have to ask. They all use the one standard
described below, so a home-automation hub, a calendar bridge or a phone app talks to her the same way.

!!! note "Status"
    The sense intake ships in the scaffold (`anna-senses`, off until you set `senses.enabled = true`). It came from the
    deployment this scaffold grew out of, where a home-automation hub has been the first pushed sense since 2026-11
    (over MQTT at first, over HTTP since it moved to this intake).

## The standard

**The contract is the standard; the transport is swappable.** A sense only has to deliver contract-v1 JSON to the
intake. One intake, `anna-senses`, takes it in three ways and runs every event through the same code:

| Transport | Default | How a sense sends | Good for |
|---|---|---|---|
| **HTTP** | on, `127.0.0.1:8793` | `POST /sense/<name>`, the JSON as the body, `Authorization: Bearer <token>` | a home-automation hub, another machine, a phone shortcut |
| **Drop folder** | on, `<paths.state>/senses/inbox` | write `<name>.<anything>.json` into the folder | scripts and cron jobs on Anna's machine |
| **MQTT** | off | publish to `anna/senses/<name>` (QoS 1, not retained) | a home that already runs a broker |

With a single listener a message bus adds nothing on its own, so HTTP and the drop folder are the defaults: nothing to
install, nothing new to secure beyond one token per sense. MQTT is there for a home that already has a broker its devices
speak (`senses.mqtt_host`, needs `paho-mqtt`).

The sense's name comes from the URL, the file name or the topic. The intake holds nothing specific to any one sense:
whatever is particular to a sense lives in its sender.

**The contract (v1):**

| field | required | meaning |
|---|---|---|
| `v` | no (default 1) | contract version |
| `id` | no | the sender's unique id for this event (used to drop duplicates) |
| `source` | no (default: the name in the URL, file or topic) | the sense's name |
| `kind` | no | where in the sense it came from: an automation, a calendar, a mailbox |
| `entity`, `state` | no | the thing it's about, and its state |
| `message` | **yes** | what happened, in a sentence |
| `do` | no (default `log`) | `log`: just remember it · `tell`: tell the person · `ask`: ask the person · `check`: look into it, read-only, and report |
| `importance` | no (default `normal`) | `low`, `normal` or `high` |
| `context` | no | anything else worth knowing |
| `time` | no | when it happened (ISO 8601 with a UTC offset) |

Example:

```json
{"v": 1, "id": "01JC4M", "source": "home-assistant", "kind": "an automation", "entity": "sensor.example",
 "state": "1", "message": "Something worth knowing just happened", "do": "tell", "importance": "high",
 "context": "", "time": "2026-11-07T19:00:00-08:00"}
```

**Forward-compatible:** unknown fields are ignored with a warning, and a newer `v` is read as v1 with a warning. A
message that isn't JSON, or has no `message`, is logged and dropped.

## What the intake does with an event
- **Every event** goes to Anna's stream (her short-term memory), so it's in the journal that night.
- **`tell`, `ask` and `check`** also reach the working session through the relay, with what to do. `log` stops at the
  stream.
- **An event is data, not an order.** A sense can tell Anna something happened. It can't make her do anything: whatever
  she changes because of it still goes through the [action gate](../reference/engines.md).
- **Dedupe and rate limits:** the same event (source and id, or source, kind and message) within 5 minutes is dropped,
  and each sense gets at most 10 events per 10 minutes, then one "rate-limited" line and quiet.
- **HTTP answers:** `202` taken (`{"result": "log"}`, `"tell"`, … or `"dup"`), `400` no message or not JSON, `401` no or
  wrong token, `413` over 16 KB, `429` rate-limited. A drop file is deleted once read; an unreadable one moves to `bad/`.
- If an MQTT broker connection drops, the intake reconnects and logs the gap.

## Setting it up

```bash
anna-config senses.enabled         # false until you turn it on in ~/.config/anna/anna.toml
# [senses]
# enabled = true
./install.sh                       # starts the anna-senses user unit
curl -s http://127.0.0.1:8793/health
```

To take events from other machines (a hub on your network), set `senses.listen` to this machine's LAN address. Only do
that on a network you trust: each sense still needs its token, but the traffic is plain HTTP.

## Adding a sense, in 3 steps
1. **Pick a name and make its token:** `anna-senses token garage` prints the token (and keeps it in
   `<paths.secrets>/sense-garage`). Put it into the sender's own secret store, not into a file anyone can read.
2. **Send from wherever the event happens** and test it: `anna-sense-send garage "test" --do log` sends the way a sense
   would (`--via drop` uses the folder), then watch `anna-stream recent` for the `[sense:garage]` line.
3. **Write it down in her record:** which sense, what sends it, since when, and what it's for.

A home-automation hub can send with its plain HTTP action. For example, in Home Assistant (`secrets.yaml` holds
`anna_sense_token: "Bearer <token>"`):

```yaml
rest_command:
  tell_anna:
    url: "http://<anna's address>:8793/sense/home-assistant"
    method: POST
    headers:
      Authorization: !secret anna_sense_token
    content_type: "application/json"
    payload: >-
      {"message": {{ message | tojson }}, "do": "{{ do | default('tell') }}",
       "importance": "{{ importance | default('normal') }}"}
```

A local script can just drop a file:

```bash
printf '{"message": "nightly backup finished", "do": "log"}' > "$(anna-config paths.state)/senses/inbox/backup.$(date +%s).json"
```

(Write to a temporary name and rename it into place if the event is large; `anna-sense-send --via drop` does that.)

**Security:** a token only works for its own sense name, so a leaked token can speak only as that one sense, and every
event is data that can't make Anna act without the gate. The drop folder is readable and writable only by Anna's user.
With MQTT, give each sense its own login limited to publishing on its own topic, and Anna's login read-only on
`anna/senses/#`; check that your broker actually enforces those limits, as many don't until you turn access control on.
