# hosts — one file per machine or device

`hosts/<name>.md`: what it is, how to reach it, what runs on it, and `## Notes` (dated facts, newest first). Use the same
name everywhere (journal, checks, senses), so a search can tie them together. Current practice lives here; the history of
how it got that way lives in the journal.

Start a new one from `_template.md`. Keep its front matter (`host:`, `aliases:`, `ips:`): it's how a search index such as
merlin learns which names mean this host, so `host_history` and host tags in search results work.
