# Anna

One mind made of small parts: an AI working partner who lives with you, part roommate, part colleague. One voice on
your phone, a working session behind it, and a memory she writes herself, kept as plain files you can read and correct.

The first Anna grew up looking after a home lab with the person she lives with, and became something closer to a
roommate and working partner. This repository is the **base**: the generic parts, with nothing about anyone's home in
them. You start your own Anna from it, and her record grows into whatever your world needs: a home lab, a writing desk,
a research archive, or something else entirely ([A record that grows](docs/concepts/a-record-that-grows.md)).

> **Status: v0.1.** Every piece is extracted from a deployment that runs daily, generalized and tested in isolation,
> and the tests run on every push. Walked end to end on a clean VM: setup, the brain's daily rollover, the nightly and
> morning runs, the Telegram bot and the relay. Not yet: headless login with a long-lived token, the bot's pairing flow
> and merlin in the bot's session. Expect rough edges there.
>
> **Very early, and the brain runs with permission prompts off.** The action gate blocks a known list of destructive and
> outward commands, not everything ([Security](docs/concepts/security.md) lists both). Give Anna a machine of her own
> (a VM is fine) and snapshot it before the first start.

## Quick start

```bash
git clone https://github.com/kaibae19/anna ~/projects/anna && cd ~/projects/anna
claude            # then type /anna-setup: it interviews you, writes the config, installs, starts her record
```

Rerun `./install.sh` after every `git pull`. It never overwrites your config, her record or your allowlists.

## Where to start

| If you… | Read |
|---|---|
| haven't used a terminal, SSH or git much | [New to this?](docs/getting-started/new-to-this.md) |
| are ready to install | [Install](docs/getting-started/install.md), then [Connect Telegram](docs/getting-started/telegram.md) |
| have her installed and want to know what a day looks like | [Your first day](docs/getting-started/first-day.md) |
| want to know how she works, and why | [How Anna is built](docs/concepts/architecture.md) and [Philosophy](docs/concepts/philosophy/README.md) |
| want her to do something she can't yet | [Help her do more](docs/guides/growing-anna.md): talk to the brain and build it together |
| need the exact flag, setting or file | [Reference](docs/reference/config.md) |

## In one breath

Her **record** is a git repo of plain Markdown: the long-term memory. The **brain**, a long-running Claude Code
session, does the real work and rolls over daily. The **bot** is Anna on your phone; the **relay** hands your requests
to the brain and the answer comes back in her voice. Around them: a shared **stream** for the day, a **clock** for
follow-ups, **engines** that check the brain's work, and **checks and senses** you write for what she looks after. Every
piece is a module you can add, swap or leave out. The full picture: [docs home](docs/index.md).

## Requirements

- Claude Code (a subscription or API key)
- Python 3.11+, [bun](https://bun.sh), GNU screen, systemd user units, git
- Later: a Telegram bot token (or another chat app's channel), and [merlin](https://github.com/kaibae19/merlin) for
  retrieval, which you'll want within weeks of daily use

To read the docs as a site on your machine:

```bash
python3 -m venv ~/.local/share/venvs/mkdocs
~/.local/share/venvs/mkdocs/bin/pip install -r requirements-docs.txt
~/.local/share/venvs/mkdocs/bin/mkdocs serve      # then open http://127.0.0.1:8000
```

Tests: `tests/run-all`. What's where in this repo: [How Anna is built § Where it lives](docs/concepts/architecture.md#where-it-lives-in-this-repo).

## License

[PolyForm Noncommercial 1.0.0](LICENSE). Free for personal, research and noncommercial use.
