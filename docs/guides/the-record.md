---
description: "Read Anna's record, correct something she has wrong, and see how a file changed over time. No git experience needed."
---

# Read and correct the record

This guide shows you how to read Anna's record, fix something she has wrong, and see how a file changed over time. It
also lists what Anna writes there on her own and what she leaves to you. It's for anyone using Anna day to day; no git
experience needed beyond the commands shown.

!!! tip "New to this?"
    The record is just a folder of Markdown text files, kept in **git**. git is a tool that remembers every saved version
    of every file. Saving a version is called a **commit**: a snapshot with a short message saying what changed. Anna
    commits as she works, so you can always see who changed what, when, and undo it.

## Find it

```bash
anna-config paths.record
```

The default is `~/anna-record`. The rest of this page uses `~/anna-record`; replace it with your path if it differs.
What's in each folder: [The record's layout](../reference/record-layout.md).

## Read it

Open any file in your editor, or in the terminal:

```bash
less ~/anna-record/memory/MEMORY.md                 # the lesson index; the first line is the 📌 handoff
ls ~/anna-record/journal/$(date +%Y/%m)/            # this month's journal days
less ~/anna-record/journal/$(date +%Y/%m/%F).md     # today's journal
ls -t ~/anna-record/journal/handoffs/ | head        # the newest morning, evening and clock reports
```

Good starting points:

- **"What's going on?"** The 📌 line at the top of `memory/MEMORY.md`, then the newest `journal/handoffs/*-morning.md`.
- **"What happened on Tuesday?"** That day's file in `journal/YYYY/MM/`. Each session is a `## ` block; each topic a `###`.
- **"What do we know about this thing?"** (a machine, a chapter, a client…) `hosts/<name>.md`.
- **"How do we do this?"** `runbooks/<topic>/README.md`.

To find a word anywhere in the record:

```bash
grep -rn "backup" ~/anna-record --include='*.md'
```

Or ask Anna: "when did we change the backup schedule?" The memory engine answers with the file and section it found it
in, so you can open it yourself.

## Correct a wrong fact

When Anna has something wrong, fix the file. The file is the truth; there's no hidden copy to update.

1. **Find where it's written.** Ask Anna where she got it ("where does it say the NAS has 4 disks?"), or search with
   `grep` as above.

2. **Edit the file.** Which file depends on the kind of fact:

    | It's… | Fix it in |
    |---|---|
    | a fact about a machine | `hosts/<name>.md`. Change the line, or add a dated line under `## Notes`. |
    | a wrong lesson or preference | `memory/<slug>.md`. If the lesson is simply wrong, delete the file **and** its line in `memory/MEMORY.md`. |
    | an outdated procedure | `runbooks/<topic>/README.md`. Fix it, or mark the old section `(superseded YYYY-MM-DD: see § X)` on its first line. |
    | a wrong handoff item | the 📌 line at the top of `memory/MEMORY.md`. |
    | a journal entry | Usually leave it: the journal is what was seen that day. Add the correction in today's file or in the host record instead. |

3. **Commit it**, so Anna's next session (and the nightly runs) see a clean record and the history shows who changed it:

    ```bash
    cd ~/anna-record
    git add hosts/nas.md
    git commit -m "hosts/nas: 6 disks, not 4"
    ```

    You should see a line like `[main 3f2a1c4] hosts/nas: 6 disks, not 4` followed by `1 file changed`.

4. **Push it** if your record has a remote (a private repository it's backed up to). `git remote -v` shows whether it has
   one.

    ```bash
    git push
    ```

!!! tip "Commit right away"
    Anna's own commits add only the files she changed, but an uncommitted edit of yours sitting in the record is easy to
    lose track of. Commit as soon as you've made it.

You can also just tell Anna, on Telegram or in the brain: "the NAS has 6 disks, not 4". The bot saves facts like that in
`hosts/` or `memory/` and commits them as `bot: <what>`; the brain does the same in its wrap-up.

!!! note "If you edit from another computer"
    All parts of Anna share one working copy of the record on Anna's machine. If you keep a second clone elsewhere, run
    `git pull` there before you edit and `git push` after. The headless runs start with `git pull --ff-only`, and a run
    whose pull fails stops with `pull failed`.

## See how a file changed

Every change is a commit, so you can see the whole story of any file:

```bash
cd ~/anna-record
git log --oneline -15                 # the last 15 changes to the record
git log --oneline -- hosts/nas.md     # every change to one file
git log -p -- hosts/nas.md            # the same, with what each change added (+) and removed (-)
git show 3f2a1c4                      # one change in full
```

Commit messages tell you who made a change:

| Message | Written by |
|---|---|
| `record: start from the Anna template` | `install.sh`, once |
| `YYYY-MM-DD checkpoint N: …` | `/anna-checkpoint` |
| `evening fold <date> (<n> sessions)` | the evening run |
| `<host>: morning <date> (headless, exit 0)` | `anna-run` saving a report |
| `clock: add #<id> …`, `clock: #<id> …` | `anna-clock` (adding, closing or firing an item; one month file per commit) |
| `bot: …` | the bot |
| your own messages | you |

The wrap-up's commit message isn't fixed; it describes the session.

### Undo a change

To undo one commit, whoever made it:

```bash
git revert 3f2a1c4
```

This makes a new commit that reverses it. Nothing is erased, so the history still shows both.

## What Anna writes, and what she doesn't

| Who | Writes | Doesn't |
|---|---|---|
| **The brain, in a session** | Anything the layer rules call for: journal, host records, runbooks, lessons, backlog, ideas, clock items, checks, senses. It commits as it goes and at wrap-up. | Rewrite an earlier session's journal block. Commit a credential (every committing skill scans the staged diff first). Put secrets in any file. |
| **`/anna-wrapup overnight`** (at `day.close`) | Journal, layers, the 📌 line; commits and pushes. | Ask anything or guess: where a step would ask, it leaves the record as it is and puts the question under **Ask**. |
| **The evening run** (`/anna-evening`) | The day's journal (drafts and the stream), the 📌 line if something is mid-flight; commits and pushes. | Edit host records, runbooks, lessons or the backlog. It lists them under **Proposed for the next session** for a reviewed session to apply. |
| **The morning run** (`/anna-morning`) | Nothing itself; `anna-run` saves and commits only the report file in `journal/handoffs/`. | Any other change. |
| **Clock runs** (`anna-clock … --run`) | Their report in `journal/handoffs/<date>-clock-<id>.md`, through `anna-run`. | Anything outside their deny-by-default allowlist. |
| **The bot** | `hosts/**` and `memory/**` (facts and preferences you tell it), committed as `bot: …`; clock items through `anna-clock`. | Other folders. It can read the whole record. |

The headless runs can't force-push, `git reset --hard`, `git clean` or delete files (`rm`): their settings deny it. The
bot's settings deny `rm` too.

## Things that aren't in the record

The stream (`<paths.state>/stream/`) and session drafts (`<paths.state>/drafts/`) are kept outside the record on purpose:
they're raw. The evening run folds what matters into the journal. Secrets live in `paths.secrets` and never go into the
record.
