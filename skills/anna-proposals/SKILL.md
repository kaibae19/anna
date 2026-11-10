---
name: anna-proposals
description: Apply or go through what the nightly runs proposed (self/proposals.md) — apply accepted proposals in a reviewed session, one commit each, or list the open ones plainly when the person wants to go through them. Use when a proposal was just accepted, when the person asks "what's proposed" / "let's go through the proposals", or at wrap-up if any are accepted but not applied.
---

# Proposals: from the nightly runs to the record, reviewed

Why: the dream and the evening fold write proposals, and a handoff is read once; without a standing list an unapplied
proposal drops out the next day (in the home this came from, the same memory fix was proposed eight nights running).
Reviewed self-change is what sets Anna apart from agents that rewrite their own skills and memory: **nothing lasting
changes unattended**.

The list: `self/proposals.md`, kept by `anna-proposals` (`anna-run` ingests each evening/dream handoff's "Proposed"
items). Statuses: open → raised → accepted → applied, or declined / later / dropped.

## How they come up (not this skill)
The prompt hook carries one proposal a day (after the day's question) until a reply raises it at a natural pause; the
Stop hook marks it raised. They answer in a word; record it: `anna-proposals set <id> accepted|declined|later --said
"<their words>"`. A roommate doesn't hand over paperwork: one at a time, in conversation, never a list unless they ask.

## Apply (accepted ones)
1. `anna-proposals list --status accepted`. For each, `anna-proposals show <id>` (the full text and its evidence).
2. **Still true?** Read the target file and check the evidence live (the record may already have it, or the fact may
   have changed since the night it was written). Already done → `anna-proposals set <id> dropped --note "already in
   <path>"`. Out of date → say so in one line and ask; don't apply a stale proposal.
3. **Apply** the smallest change that does what they accepted, in the layer the proposal names (memory lesson: pointer
   first + MEMORY.md line; backlog: dated, newest at the top; a fact about a thing: its file in the folder of things, `## Notes`). Their words, if the proposal quotes
   them, go in verbatim.
4. **Gate it** (`anna-action-gate`, `asked` = their words from the `said` entry), commit only the files changed:
   `proposal <id>: <summary>`; push if the record has a remote.
5. `anna-proposals set <id> applied --commit <sha>`; then commit `self/proposals.md` too (or in the same commit).

## Go through them (when the person asks)
`anna-proposals list` (or `--all`) and show it as it is: id, status, where it came from, one line each. Take the answers
item by item with `set`, then apply the accepted ones as above.

## Never
- Apply anything they didn't accept, or a proposal whose evidence no longer holds.
- Apply from a headless run (the evening, the dream, the morning): they only propose.
- Raise more than one a day, or re-raise a declined one.
