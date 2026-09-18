# dotfiles

Personal chezmoi-managed dotfiles — Ghostty, zsh, Starship, tmux, git, and pre-commit secret scanning.

## Makefile

Task runner at the repo root — no extra install (`make` ships with Xcode CLT). Run `make help` for the full list.

```bash
make bootstrap          # fresh machine — full first-time setup
make diff               # preview pending dotfile changes
make apply              # apply dotfile changes
make lint               # pre-commit on all files
make upgrade            # brew upgrade + pre-commit autoupdate
```

Parameterized targets: `make edit FILE=~/.zshrc`.

## Quick start

```bash
git clone https://github.com/codecio/dotfiles ~/dotfiles
cd ~/dotfiles
make bootstrap
```

On an **existing machine** with tools already installed, bootstrap detects and skips what's present. See [docs/bootstrap.md](docs/bootstrap.md).

```bash
make brew-bundle        # re-sync core Brewfile without full bootstrap
make apps               # install GUI apps from Brewfile.apps
make cli                # install daily CLI toolkit from Brewfile.cli
make ext                # sync VS Code + Cursor extensions from the Extfile set
make apply              # apply dotfile changes only
```

VS Code Settings Sync only reaches other VS Code installs — Microsoft restricts it to official builds, so Cursor can never join it. `make ext` keeps both editors in step instead. See [docs/editors.md](docs/editors.md).

## What's in this repo

| File | Contents | Install |
|------|----------|---------|
| `Brewfile` | Dotfile setup | `make brew-bundle` (part of `make bootstrap`) |
| `Brewfile.apps` | GUI casks | `make apps` |
| `Brewfile.cli` | Daily CLI toolkit | `make cli` |
| `Extfile` | Editor extensions for VS Code **and** Cursor | `make ext` |
| `Extfile.vscode` | VS Code-only extensions | `make ext` |
| `Extfile.cursor` | Cursor-only extensions | `make ext` |

| Path | Purpose |
|------|---------|
| `Brewfile.archive` | Historical brew dump (local reference, gitignored) |
| `Extfile.ignore` | Extensions installed locally but unreproducible — never installed |
| `home/` | Chezmoi source tree |
| `Makefile` | Task runner (`make help`) — bootstrap + daily ops |
| `scripts/` | Helpers invoked by the Makefile |
| `docs/` | Cheat-sheets and workflows |

## Machine vs git identity vs Windows

This repo applies to **macOS** via chezmoi `home/`. There is no home/work prompt at `chezmoi init`. `sourceDir` is `~/dotfiles`.

**Git still has two identities**, by directory, not by laptop:

| Path | Identity |
|------|----------|
| `~/development/` | work (`~/.gitconfig.work`) |
| `~/home/` and `~/dotfiles/` | personal (`~/.gitconfig.personal`) |
| everywhere else | personal default in `~/.gitconfig` |

Windows 11 is a later apply path (separate tree or repo). The same dual git idea can map to Windows clones of those folders. See [docs/chezmoi.md](docs/chezmoi.md).

## Docs

- [docs/README.md](docs/README.md) — index
- [docs/bootstrap.md](docs/bootstrap.md) — fresh Mac vs existing machine
- [docs/shell.md](docs/shell.md) — shell tool config paths
- [docs/chezmoi.md](docs/chezmoi.md) — profiles, apply, add files
- [docs/brew.md](docs/brew.md) — Brewfile split (core, cli, apps, archive)
- [docs/editors.md](docs/editors.md) — VS Code + Cursor extension sync
- [docs/toolkit.md](docs/toolkit.md) — per-tool reference (purpose, usage, links)

## After scaffold (manual)

```bash
pre-commit install && pre-commit run --all-files
gh auth login
atuin register
```
