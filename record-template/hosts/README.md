# @THINGS@ — one file per thing she keeps a record of

The folder of *things*: in a home lab, machines and devices; elsewhere chapters, sources, clients, plants, whatever the
work keeps coming back to. It starts empty and grows when the work asks for it (see the scaffold docs, A record that
grows). Its name comes from `record.things` in Anna's config, and the front-matter key from `record.thing`.

`@THINGS@/<name>.md`: what it is, how to reach it if that applies, what matters about it, and `## Notes` (dated facts,
newest first). Use the same name everywhere (journal, checks, senses), so a search can tie them together. Current
practice lives here; the history of how it got that way lives in the journal.

Start a new one from `_template.md`. Keep its front matter (`@THING@:`, `aliases:`, `ips:`): it's how a search index
such as merlin learns which names mean this thing, so the history of a thing and the tags in search results work.
