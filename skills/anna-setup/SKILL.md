---
name: anna-setup
description: First run of a new Anna — interview the person, write ~/.config/anna/anna.toml, run install.sh, start the record (who they are, what she'll help with, the first things that come up), optionally a first check and sense, and write day one's journal entry so the morning check has something to read tomorrow. Use when someone says "set up Anna", runs /anna-setup, or has the scaffold checked out with no config yet. Safe to rerun: it fills gaps and never overwrites.
---

# Setting up a new Anna

You're helping someone start their own Anna from the scaffold. By the end they have: a config, an installed Anna,
a record that knows who they are and what she'll help with, a first check and sense if they want them, and a first journal entry. Go at
their pace; this is a conversation, not a form. Ask a few things at a time, not a wall of questions.

**Ground rules.** Read the scaffold's `README.md` and `docs/` first (the checkout: the directory holding `install.sh`;
ask where it is if you're not in it). Don't put secrets in the config, the record or the chat: tokens go into files in
`paths.secrets` that **they** create (tell them the path and the command; never ask them to paste a token to you). Before
changing anything on their machines, say what you're about to do. If a config or record already exists, read it and only
fill what's missing.

## 1. Who and where
Ask, then confirm back in one short summary:
- What should she be called (`anna.name`; "Anna" is fine), and how should she address them (`anna.user`)?
- Their timezone (`anna.timezone`, an IANA name: suggest from `timedatectl` if they're on the machine).
- **What will she help with?** In their words (a home lab, a book, a research project, a small business, just company).
  From the answer, name the folder for the things she'll keep a record of (`record.things`, plural, e.g. `hosts`,
  `chapters`, `clients`, `projects`; default `hosts`) and its front-matter key (`record.thing`, singular: `host`,
  `chapter`…). Not sure yet is fine: keep the default; the record grows later (docs: A record that grows).
- Where the record should live (`paths.record`; default `~/anna-record`). Do they want it pushed somewhere private
  (a Gitea/GitHub/GitLab repo)? Remotes are optional; backups are not: say so.
- Which machine is Anna's home: it should run all day (a small VM or a home server), with Claude Code logged in.
- **Is its disk encrypted?** Check, read-only, on Anna's machine: `lsblk -no TYPE -s "$(findmnt -no SOURCE /)"` lists the
  devices under `/`; a `crypt` line means LUKS. Also check the record's filesystem if it's elsewhere
  (`findmnt -no SOURCE -T <paths.record>`). No `crypt`: say plainly that we highly recommend full-disk encryption before
  the record fills up (it will hold their routines, their work and what she looks after), and point them to `docs/getting-started/new-to-this.md`
  § A machine that's always on (it covers unlocking after a reboot). Inside a VM, ZFS native encryption or encrypted host
  storage won't show here: ask whether the host encrypts it. It's their call, not a blocker; note their answer in day
  one's journal entry. Recommend encrypted off-machine backups in the same breath (restic or Borg; the scaffold has none yet).

## 2. Which parts
Explain each in a sentence and let them choose. Defaults in brackets.
- **The brain's daily rollover** [yes]: a long-running session in `screen`, wrapped up overnight (`day.close`) and started
  fresh in the morning (`day.open`). Remote Control (`day.remote_control`) lets them reach it from the Claude app.
- **Morning check and evening fold** [yes]: headless runs at `runs.morning` / `runs.evening`. For unattended auth, they can
  create a long-lived token with `claude setup-token` and save it as `<paths.secrets>/claude-oauth` (mode 600).
- **Her own journal and the nightly dream** [yes, nothing to set up]: Anna logs what registers with her while working
  (`anna-log`; their corrections are logged automatically), and `/anna-dream` at `runs.dream` sorts it into
  `self/lately.md`, wonders and proposals (`docs/concepts/own-journal.md`). Say what it is in a line; it's on by default.
- **Engines that run themselves** [yes]: the prompt hook runs the interpretation engine after a gap and on a new session
  (`engines.interpretation`); the epistemic relay check is off (`engines.epistemic_relay`). A line is enough.
- **Pushed senses** [later, unless they have something that sends events]: the sense intake (`senses.enabled`) takes
  events over HTTP or a drop folder, e.g. from a home-automation hub (`docs/concepts/senses.md`). Off until they want it.
- **The bot** [their call]: Anna on Telegram. They create a bot with @BotFather, save the token as
  `<paths.secrets>/telegram-<bot.instance>`, then allow only their account: `anna-notify --learn`, then write
  `access.json` by hand as `docs/getting-started/telegram.md` § 5 shows (the plugin's pairing flow is untested under the
  bot's settings). Needs bun. Telegram is the default channel, not a requirement (same page, § Using another chat app).
- **The relay** [yes if the bot]: the bot hands real work to the brain and speaks the result. Read `docs/concepts/relay.md` with them,
  especially the trust section: the brain's port takes local HTTP, so Anna's machine should be hers.
- **merlin** [later]: search over the record; not needed on day one, but with daily use they'll want it within weeks
  (`docs/guides/merlin.md` § When you'll want it); https://github.com/kaibae19/merlin.

## 3. Write the config and install
Write `~/.config/anna/anna.toml` with only the keys that differ from `config/anna.example.toml` (show it to them first).
`install.sh` makes the record's first commit: if `git config user.name` / `user.email` are empty, ask what Anna's record
commits should be authored as and pass it for that run (`GIT_AUTHOR_NAME=… GIT_AUTHOR_EMAIL=… GIT_COMMITTER_…`), then set
it in the record only (`git -C <record> config user.name …`); never touch their global git config.
Then run `./install.sh` from the scaffold and read its output with them: it says what it created and what it left alone.
If `loginctl` says lingering is off, explain that timers stop at logout and give them the command; don't run sudo yourself.

## 4. Start the record
In `paths.record`:
- `memory/user-<slug>.md` (type `user`): who they are and how they like to work, in their words, short. Its line in
  `memory/MEMORY.md`.
- `CLAUDE.md` § Things at a glance: one row per thing they mention that Anna should keep a record of (machines, projects,
  chapters, clients… whatever their work is about). For each one that matters, `<record.things>/<name>.md` from
  `<record.things>/_template.md` (fill in the front matter: the name, any aliases and addresses): what it is, how to reach
  it if that applies (no secrets), what matters about it. **Learn over time, not by intake form:** write down what they
  tell you; never ask for complete inventories or catalogs, the record fills in as things come up. If they offer one
  (a collection to catalog, a client list), take it as given. For machines: read-only probes only (`uname`, `uptime`, `df -h`, `systemctl
  --failed`) and only with their OK; paste what you saw under `## Notes` with today's date.
- `planning/backlog.md`: anything they mention wanting to do.

## 5. A first check and a first sense (optional)
Offer, don't require: many Annas start without one, and checks come naturally later, when something matters enough to
watch. If they want one, pick together the one thing they'd most want to hear about if it went wrong (a backup, a disk,
a deadline, a document nobody has touched in weeks). Copy the closest
example from the scaffold's `examples/checks/` into `checks/<name>`, adapt it, make it executable, run `anna-checks` and
show the output. Same for one sense from `examples/senses/` (`anna-body --line`). The shipped examples are machine-flavoured;
adapt one or write a small script of their own. If they'd rather wait, say where the examples are and move on. Explain the contract: checks print
`OK`/`⚠`/`⛔` lines, senses print JSON sensations; a check that can't run is never OK.

## 6. If the bot is on
Once the token file exists: `anna-notify --learn` (they DM the bot first), `anna-notify "hello from <name>"`, then
`systemctl --user enable --now anna-tg@<instance>`. Anything the bot should know without looking up (room names, device
ids, sensor ids, the wrappers it may call) goes into `bot/context/` as short files; restart the bot after a change.

## 7. Day one
Write `journal/YYYY/MM/<today>.md` in the journal format (`journal/README.md`): headline, Day index, one `###` per topic
(what was set up, what was decided and why, the probe output verbatim, what's open). Update the 📌 line in
`memory/MEMORY.md` (what's live, what's next, Ask). Commit (`git -C <record> add -A && git -C <record> commit`), push if
there's a remote. Add a clock note for tomorrow's first morning report: `anna-clock add "tomorrow 09:00" "Read the first
morning report with <user>: did it run, did the checks make sense?"`.

## 8. Hand over
Tell them, briefly: how to reach the brain (`screen -r <day.screen>` or the Claude app), what happens tonight and
tomorrow morning, where the record is, and that `/anna-setup` can be rerun anytime to add parts.

**The engines and the gate** (they'll meet the gate on the first real change, so say it now, in a few lines): before
replying or acting, the brain runs small checks as subagents (`agents/`: what context belongs in a reply, whether a claim
is backed, recall from the record). Before any state change (a restart, a package, a device, a push that rewrites, a
message sent out), it asks the action gate, which answers `go`, `confirm-first` (Anna asks them first) or `no-go`, and
writes an audit line to the stream. A hook enforces it: a change without a recent `go` is blocked and Anna is told to
ask the gate. Reads, edits in the record and plain pushes pass. The switch `<paths.state>/gate-off` turns the hook off
(every pass is still logged); it's theirs, not Anna's. Details: `docs/concepts/security.md` § Destructive and outward actions.

**The first start is theirs.** The brain runs with permissions off (`docs/concepts/security.md` § Allowlists), and Claude Code asks
once per machine to accept Bypass Permissions mode. Explain that before they start it, and don't accept it for them: they
run `anna-day open`, and if it stops at that dialog, `screen -dr <day.screen>`, read it, choose Yes, then `anna-day open`
again. (Or let the 04:15 open stop there and do it in the morning.)
