---
description: "Bring your Anna up to date with the scaffold: git pull, ./install.sh, run the tests, and know what an update keeps."
---

# Update after git pull

This guide shows you how to bring your Anna up to date with the scaffold: get the new version with `git pull`, install
it with `./install.sh`, and check it with the tests. It also says exactly what an update keeps and what it replaces.

!!! tip "New to this?"
    Your copy of the scaffold (usually `~/projects/anna`) is a **git checkout**: a folder that knows which version of the
    project it holds and where it came from. `git pull` asks the place it came from for anything newer and updates the
    files in the folder. It doesn't touch anything outside that folder. Anna keeps running the old copies until
    `./install.sh` copies the new ones into place.

## The short version

```bash
cd ~/projects/anna
git pull
./install.sh
tests/run-all
```

## Step 1: get the new version

```bash
cd ~/projects/anna
git pull
```

What you might see:

- `Already up to date.` There's nothing new. You can stop here.
- A list of changed files ending in a line like `12 files changed, 140 insertions(+), 38 deletions(-)`. The new version is
  in your checkout. Go on to step 2.
- An error. See [If git refuses](#if-git-refuses) below.

To see what changed before you install it:

```bash
git log --oneline ORIG_HEAD..HEAD
```

`ORIG_HEAD` is where you were before the pull, so this lists the commits the pull brought in.

## Step 2: install it

```bash
./install.sh
```

`install.sh` is safe to run again and again. It prints one line per thing it did, for example:

```
Installing Anna (Anna, for you) from /home/you/projects/anna
  scripts and hooks → /home/you/bin
  skills → ~/.claude/skills (anna-checkpoint anna-evening anna-morning anna-setup anna-wrapup )
  engines → ~/.claude/agents (anna-action-gate anna-curiosity anna-epistemic anna-goals anna-interpretation anna-memory )
  record exists at /home/you/anna-record (left as is)
  ~/.claude/anna-headless-settings.json
  hooks merged into ~/.claude/settings.json (backup kept); fakechat/telegram off at user scope
  ~/CLAUDE.md exists: the template is at ~/CLAUDE.md.anna-new to merge by hand
  brain memory symlink exists → /home/you/anna-record/memory
  units → /home/you/.config/systemd/user
  timers enabled
Done. Start the brain with: anna-day open   (or wait for 04:15)
```

Read any line that starts with `⚠`.

### What it keeps

These are yours; `install.sh` never overwrites them:

| What | What happens on an update |
|---|---|
| Your config, `~/.config/anna/anna.toml` | Left alone. It's only created (from the example) if it doesn't exist. |
| Anna's record, `paths.record` | Never overwritten. Files that are new in the template and missing from your record (for example `self/README.md` and `planning/wonders.md` when the own journal arrived) are added, not committed (a file your record's git history ever had is left out: you removed it on purpose): `record exists at …: added what's new in the template: …`. Look at them, then commit them in the record. |
| `~/CLAUDE.md` (the brain's home instructions) | Left alone. The new template is written beside it as `~/CLAUDE.md.anna-new`. |
| The bot's allowlist, `~/.claude/anna-tg-<instance>-settings.json` | Left alone (`exists (left as is: your allowlist)`). |
| An engine you edited in `~/.claude/agents/` | Left alone, with the new version beside it as `<name>.md.anna-new` and a `⚠ you edited: …` line. |
| Your other hooks in `~/.claude/settings.json` | Kept. Anna's hooks are added only where missing, and the file is backed up first as `settings.json.bak.<timestamp>`. |
| Your secrets in `paths.secrets` | Not read or changed (the folder is only created, mode 700, if missing). |
| The gate override file `<paths.state>/gate-off` | Not touched. |

### What it replaces

| What | Where |
|---|---|
| The scripts and hooks | `paths.bin` (default `~/bin`), each swapped in atomically so a running script keeps its old copy |
| The skills | `~/.claude/skills/anna-*/`, deleted and recopied |
| Engines you didn't edit | `~/.claude/agents/anna-*.md` |
| The headless runs' permissions | `~/.claude/anna-headless-settings.json`, rewritten from `config/headless-settings.json.in` |
| The brain's relay settings (relay on) | `~/.claude/anna-brain-settings.json` |
| Shared data | `~/.local/share/anna/` (the example config, the bot prompt template, the last installed engines) |
| The systemd user units | `~/.config/systemd/user/`, with the timers rendered again from your config times; then `systemctl --user daemon-reload`, and the timers (and the relay, if on) are enabled and started |

!!! warning "Local edits there are lost"
    Changes you made by hand to an installed skill in `~/.claude/skills/`, to `~/.claude/anna-headless-settings.json`, or
    to a unit in `~/.config/systemd/user/` are overwritten. Make such changes in the checkout instead and keep them as a
    commit there (see [If git refuses](#if-git-refuses) for how that interacts with `git pull`).

To skip the systemd part, run `./install.sh --no-systemd`. To install the units without enabling them, `./install.sh
--no-enable`.

### Merge what was left beside your files

After an update, look for `.anna-new` files and compare:

```bash
ls ~/CLAUDE.md.anna-new ~/.claude/agents/*.anna-new 2>/dev/null
diff ~/CLAUDE.md ~/CLAUDE.md.anna-new
```

Copy over the parts you want, then delete the `.anna-new` file. New features often come with a line or two for the
brain here (when to log to the own journal, which engines now run by themselves), so don't skip this diff. (If you've never edited `~/CLAUDE.md` yourself, you can
simply replace it: `mv ~/CLAUDE.md.anna-new ~/CLAUDE.md`.)

Your bot allowlist is kept as it is, so new entries added to the scaffold's `bot/settings.json.in` don't reach it by
themselves. To compare the allow lists:

```bash
jq '.permissions.allow' ~/projects/anna/bot/settings.json.in
jq '.permissions.allow' ~/.claude/anna-tg-<instance>-settings.json
```

The template has placeholders (`@RECORD@`, `@STATE@`) where your file has real paths. More in
[What the bot may do](bot-permissions.md).

### What it doesn't restart

`install.sh` doesn't restart the bot, the brain or the relay bridge.

- The relay bridge (if `relay.enabled`) keeps running its old copy of `anna-relay` until it restarts:

    ```bash
    systemctl --user restart anna-relay
    ```

- The bot builds its prompt when it starts. To pick up a new prompt or a changed allowlist:

    ```bash
    systemctl --user restart anna-tg@<instance>
    ```

- The brain starts fresh every morning at `day.open` (`anna-day open`), which picks up the new skills, engines and
  `~/CLAUDE.md`.

## Step 3: run the tests

```bash
tests/run-all
```

Each suite runs in a throwaway config, state and record, so this doesn't touch your live Anna. You should see one line per
suite and a last line:

```
ok   test_body_checks        12 ok
ok   test_clock              30 ok
...
all suites passed
```

The counts differ from version to version. If `bun` isn't installed, the relay suite is skipped (`skip test_relay (no
bun: …)`). A failing suite prints `FAIL` with its failing lines, and the command exits 1. Run `tests/run-all -v` to see
every suite's full output.

## If git refuses

`git pull` stops without changing anything when it would overwrite something you changed in the checkout:

```
error: Your local changes to the following files would be overwritten by merge:
        agents/anna-goals.md
Please commit your changes or stash them before you merge.
Aborting
```

First see what you changed:

```bash
git status
git diff
```

Then pick one:

- **You don't need the change.** Throw it away and pull again:

    ```bash
    git restore agents/anna-goals.md
    git pull
    ```

- **You want to keep the change on top of the new version.** Set it aside, pull, then put it back:

    ```bash
    git stash
    git pull
    git stash pop
    ```

    If `git stash pop` reports a conflict, the file now contains both versions between `<<<<<<<`, `=======` and
    `>>>>>>>` markers. Edit it to the version you want, then `git add <file>` and `git stash drop`.

- **You keep a few changes for good.** Commit them in the checkout (`git commit -am "my changes"`), then use
  `git pull --rebase`, which replays your commits on top of the new version.

If `git pull` says your branches **have diverged** and asks how to reconcile them, you have commits of your own;
`git pull --rebase` is the usual answer.

!!! tip "Fewer edits in the checkout, fewer conflicts"
    Most of what makes your Anna yours doesn't belong in the checkout at all: settings go in `~/.config/anna/anna.toml`,
    checks, senses, the records of things and lessons go in her record, and edits to an installed engine are kept by
    `install.sh`. The checkout only needs changes for skills, the templates and the scripts.
