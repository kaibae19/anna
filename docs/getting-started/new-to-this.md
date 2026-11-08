---
description: "New to servers, SSH or git? What Anna needs, why, and how to check you have each piece before you install."
---

# New to this?

This page is for you if you haven't run a server, used SSH or worked with git before. It explains what Anna needs, why,
and how to check that you have each piece. If you already run Linux machines, skip to [Install](install.md).

## What you're setting up

Anna is a set of scripts around **Claude Code**, Anthropic's command-line agent. One Claude Code session (the **brain**)
runs all day on a machine of yours and does the real work. An optional Telegram bot lets you talk to Anna from your
phone. Everything Anna learns goes into a folder of plain text files on that machine (the **record**), which you can read
and correct. Architecture in more detail: [Architecture](../concepts/architecture.md).

## A machine that's always on

Anna lives on one machine and runs on a schedule: she wraps up the day around midnight, runs a check at 4 in the morning
and starts a fresh session after it. If the machine is off or asleep, none of that happens. So you need a Linux machine
that stays on:

- **A small virtual machine (VM)** on a home server (Proxmox, a NAS that runs VMs, or similar). This is the best choice:
  Anna gets a machine of her own.
- **A spare Linux box** (an old laptop or mini PC) that you leave running.
- A cloud VM also works, as long as you're comfortable with your record living there.

It doesn't need much: Anna's own scripts are light, and the model runs at Anthropic, not on your machine. Two cores, 2 to
4 GB of memory and a few GB of disk are plenty to start.

!!! warning "Give Anna her own machine"
    The brain runs with Claude Code's permission prompts off, and the relay between the bot and the brain listens on a
    local port without a password. Don't share Anna's machine with other people or with services that fetch web pages
    for others. Why: [Security model](../concepts/security.md).

!!! warning "Encrypt the drive, and keep encrypted backups"
    We highly recommend both, from the start. Within weeks, Anna's record holds a detailed picture of your life and
    your systems: your machines and how to reach them, your routines, the people in your home, what you said to her.
    Her machine also holds the tokens she runs on.

    - **Encrypt the disk** when you install the operating system. Debian, Ubuntu and Fedora all offer it in the
      installer ("encrypt", "LVM and encryption"); it's much harder to add later. For a VM, encrypt the VM's own disk
      the same way, or put it on encrypted storage on the host.
    - **Plan for reboots.** An encrypted disk asks for its passphrase at boot, so after a power cut Anna stays offline
      until someone unlocks it. If that's a problem, look at unlocking with the machine's TPM (`systemd-cryptenroll`),
      over the network (Clevis and Tang), or over SSH from the boot screen (dropbear in the initramfs).
    - **Back up encrypted, to somewhere else.** Use a tool that encrypts before anything leaves the machine (restic or
      Borg) and send it to a second place: another machine, a NAS, a cloud bucket. Include the record, Anna's state
      (`~/.local/state/anna`), her config (`~/.config/anna`) and `~/.claude`. Keep the backup's key somewhere other
      than Anna's machine (a password manager), and try a restore once so you know it works.

    The scaffold doesn't set up backups for you yet (it's on the [roadmap](../roadmap.md)).

Anna uses **systemd user timers** (the standard Linux scheduler, run as your user rather than as root). Any current
Debian, Ubuntu or Fedora has them.

## The terminal and SSH

The **terminal** is the text window where you type commands. Every step in these docs is a command you type there and
then press Enter. Lines in grey boxes are what you type; the text after them describes what you should see.

**SSH** lets you open a terminal on another machine over the network. If Anna lives on a VM, you'll usually sit at your
own computer and connect to it:

```bash
ssh you@my-server
```

Replace `you` with your username on that machine and `my-server` with its name or IP address. The first time, SSH asks
whether you trust the machine's key: type `yes`. Then it asks for your password (or uses your SSH key), and the prompt
changes to the other machine's name. Everything you type now runs there. `exit` brings you back.

**screen** keeps a terminal running after you disconnect. The brain lives inside a screen session called `anna`, so it
keeps working when you close your laptop. You'll use two keys: `screen -r anna` to look at it, and **Ctrl-A, then D**
to step away again without stopping it.

## Git, in one paragraph

**Git** keeps a history of a folder of files: every change is saved as a *commit* you can look back at or undo. Anna's
record is a git folder, so you can always see what she wrote and when. You'll use two commands:

- `git clone <address> <folder>` makes a copy of a repository (here: this scaffold) on your machine.
- `git pull` (run inside that folder) fetches the newest version.

You don't need a GitHub account to use Anna. You may want a private remote (GitHub, GitLab, a self-hosted Gitea) later,
so your record is backed up off the machine. See [The record](../guides/the-record.md).

## Claude Code and the account it needs

Claude Code is Anthropic's agent that runs in the terminal. Anna is built on it: the brain, the bot and the scheduled
runs are all Claude Code sessions. You need:

- **A Claude account that includes Claude Code**: a paid Claude subscription (Pro or Max) or an Anthropic API account.
  Anna's sessions run all day and every night, so expect real usage. <!-- TODO: verify which plans include Claude Code at publication time -->
- **Claude Code installed** on Anna's machine and logged in. Anthropic's install instructions are at
  [docs.claude.com](https://docs.claude.com/en/docs/claude-code/setup). After installing, run `claude` once and follow
  the login prompts.

For the scheduled runs at night, Claude Code can use a long-lived token instead of your interactive login. Setup
explains it ([Install](install.md#optional-a-token-for-the-night-runs)).

## A Telegram account (optional)

The bot is how Anna reaches you on your phone, and how you reach her. It's optional: without it, Anna still works in the
terminal, and alerts go to her log instead of your phone. If you want it, install Telegram on your phone and make an
account. You'll create the bot itself later ([Telegram](telegram.md)).

## Requirements, and how to check each one

Run each check on Anna's machine. If a command prints "command not found", install that piece.

| What | Why Anna needs it | Check | Where to get it |
|---|---|---|---|
| Linux with systemd | timers and services run as your user | `systemctl --user status` shows a tree, not an error | any current Debian, Ubuntu, Fedora |
| Python 3.11 or newer | most of Anna's scripts | `python3 --version` → `Python 3.11` or higher | your distribution (`sudo apt install python3`) |
| jq | reads and merges JSON settings | `jq --version` | `sudo apt install jq` |
| git | the record is a git repository | `git --version` | `sudo apt install git` |
| GNU screen | the brain lives in a screen session | `screen --version` | `sudo apt install screen` |
| uuidgen | names each brain session | `uuidgen` prints an ID | `sudo apt install uuid-runtime` (Debian/Ubuntu) |
| curl | sends Telegram alerts | `curl --version` | `sudo apt install curl` |
| Claude Code | the brain, the bot and every scheduled run | `claude --version` | [docs.claude.com](https://docs.claude.com/en/docs/claude-code/setup) |
| bun (only for the bot or relay) | runs the relay and the Telegram channel | `bun --version` | [bun.sh](https://bun.sh) (its one-line installer) |

`install.sh` checks for python3 (and its version), jq, git, screen and claude, and for bun when the bot or relay is on.
It stops with a message naming the missing piece, so you can also just run it and see.

!!! tip "New to this? What `sudo` means"
    `sudo` runs one command as the administrator. It asks for your password. Anna's setup never runs `sudo` for you;
    when something needs it (like the lingering command in [Install](install.md)), you type it yourself.

## Next

[Install](install.md): clone the scaffold and let `/anna-setup` interview you.
