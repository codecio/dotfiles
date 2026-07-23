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
make apply              # apply dotfile changes only
```

## What's in this repo

| File | Contents | Install |
|------|----------|---------|
| `Brewfile` | Dotfile setup | `make brew-bundle` (part of `make bootstrap`) |
| `Brewfile.apps` | GUI casks | `make apps` |
| `Brewfile.cli` | Daily CLI toolkit | `make cli` |

| Path | Purpose |
|------|---------|
| `Brewfile.archive` | Historical brew dump (local reference, gitignored) |
| `home/` | Chezmoi source tree |
| `Makefile` | Task runner (`make help`) — bootstrap + daily ops |
| `docs/` | Cheat-sheets and workflows |

## Machine profiles

Chezmoi prompts for one of two profiles on first init (`home/.chezmoi.toml.tmpl`):

| ID | Machine | OS |
|----|---------|-----|
| `home` | Personal Mac | darwin |
| `work` | Work Mac | darwin |

Windows is handled separately by a future `dotfiles-windows` repo — this tree is Mac/Linux/WSL-focused.

Init also sets `sourceDir = ~/dotfiles`, so `chezmoi apply` works without `--source` after bootstrap.

Git identity is path-based (`includeIf` in `dot_gitconfig.tmpl`) — not prompted by chezmoi. See [docs/chezmoi.md](docs/chezmoi.md).

## Docs

- [docs/README.md](docs/README.md) — index
- [docs/bootstrap.md](docs/bootstrap.md) — fresh Mac vs existing machine
- [docs/shell.md](docs/shell.md) — shell tool config paths
- [docs/chezmoi.md](docs/chezmoi.md) — profiles, apply, add files
- [docs/brew.md](docs/brew.md) — Brewfile split (core, cli, apps, archive)
- [docs/toolkit.md](docs/toolkit.md) — per-tool reference (purpose, usage, links)

## After scaffold (manual)

```bash
pre-commit install && pre-commit run --all-files
gh auth login
atuin register
```
