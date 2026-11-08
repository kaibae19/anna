---
description: "Senses are how the world reaches Anna: polled senses she reads herself, and pushed senses that send her events in one standard contract over MQTT."
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
    The pushed-sense interface is designed and running in the deployment this scaffold came from, with a home-automation
    hub as the first sense. The intake isn't in the scaffold yet ([roadmap](../roadmap.md)). This page is the contract a
    sense should follow, so senses written now keep working when it lands.

## The standard

**Transport:** MQTT. Each sense publishes to its own topic, `anna/senses/<name>`, one JSON object per message, not
retained, QoS 1. One listener on Anna's machine, the sense intake, subscribes to `anna/senses/+`. It holds nothing
specific to any one sense: whatever is particular to a sense lives in its sender.

**The contract (v1):**

| field | required | meaning |
|---|---|---|
| `v` | no (default 1) | contract version |
| `id` | no | the sender's unique id for this event (used to drop duplicates) |
| `source` | no (default: the topic's last part) | the sense's name |
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
- If the broker connection drops, the intake reconnects and logs the gap.

## Adding a sense, in 3 steps
1. Pick a name and publish contract-v1 JSON to `anna/senses/<name>` from wherever the event happens: a hub's automation,
   a script, an app.
2. Test it with a sample sender (one JSON publish is enough) and watch Anna's stream for the `[sense:<name>]` line.
3. Write it down in her record: which sense, what sends it, since when, and what it's for.

**Security:** each sense should have its own MQTT login, limited by the broker to publishing on its own topic, and Anna's
login should only read `anna/senses/#`. Check that your broker actually enforces those limits: many don't until you turn
access control on.
