# Coffee Logic

> *"If I gave this to my neighbor who has a dog named Potato and lives in Tokyo, would it still work?"*

Coffee Logic is the design principle every part of Anna has to pass, and it's named after a real bug.

Early on, Anna correctly learned one person's habit: a set number of cups of coffee a day. Over time that pattern leaked
from what she knew about *one* person into how the system worked, and she started assuming *everyone* drinks that much
coffee. One person's routine had become a universal assumption, quietly, and the name stuck as a reminder of how easily
individual learning turns into hardcoded bias.

**The rule:** learn what *this* person does; never assume what *all* people do.

## What it rules out
- **Cultural assumptions:** religion, customs, food, family shapes, work weeks, holidays.
- **Place and time:** every time is in the person's own timezone; no assumptions about seasons, daylight or weekends.
- **Language:** names of any length or shape, any script, any way of writing.
- **Routines:** no "morning = coffee + email". Mornings, nights, rest days and rhythms are learned, never defaulted.
- **Demographics:** no prediction from a category a person belongs to. Only what this person has shown or said.

## The test
Before anything ships, ask:
1. **Anywhere:** would this work for someone in a different country, climate and timezone, including one that changes its
   clocks twice a year?
2. **Anyone:** for someone who fasts, doesn't drink caffeine, works nights, or rests on weekdays?
3. **Any amount:** for someone who never does the thing, does it six times a day, or does something else entirely?
4. **Edge cases:** a one-word name, a shared device, a week with no routine at all?

## How the scaffold applies it
- **No person in the code.** Scripts and prompts say "the person" (or the name from your config). Names, timezone, hosts,
  routines and thresholds come from `anna.toml` and from your record, never from the scaffold.
- **Learned values are inputs.** A goal's window and target live in its file; the person's active hours are computed from
  their own history (`anna-rhythm`); the engines are handed these values and told not to invent any.
- **Neutral when unknown.** No learned pattern means no assumption: the curiosity engine waits for the next session instead of
  guessing when someone is awake; the goals engine says `unknown` rather than doing its own date math.
- **The engine prompts pass the Potato test.** The neighbor with a dog named Potato in Tokyo can install the six files in
  `agents/` with her own record, and nothing in them is wrong for her.

## Common slips
| Slip | Instead |
|---|---|
| The server's timezone in a calculation | The configured timezone |
| A routine written into a prompt ("after their morning coffee") | A window read from the person's own goal or rhythm |
| A person's name, host or habit in a script | A config key or a record file |
| A threshold picked by the developer ("stalled after 14 days") | A value the person set, or none |
| A default that's someone's habit | A neutral default, then learning |

Coffee Logic isn't only about avoiding bugs. It's the difference between an agent that fits one person and one that can fit
anyone, by learning them.
