# Brew

Four Brewfiles: core toolchain, daily CLI toolkit, GUI apps, and a historical archive.

> **See also:** [toolkit.md](toolkit.md) — per-tool descriptions, usage examples, and doc links for every entry in `Brewfile`, `Brewfile.cli`, and `Brewfile.apps`.

## Core (`Brewfile`)

<details>
<summary>Brewfile — dotfiles-required toolchain</summary>

```bash
make brew-bundle
# or: brew bundle --file=~/dotfiles/Brewfile
```

Installed by `make bootstrap`. Only tools the dotfile setup itself needs:

- **Chezmoi + terminal:** chezmoi, ghostty, font-jetbrains-mono-nerd-font
- **Shell:** starship, atuin, zoxide, direnv, fzf, fd, ripgrep, eza, bat, fastfetch, zsh-syntax-highlighting, tmux
- **Git:** git, gh
- **Pre-commit guard:** pre-commit, gitleaks, detect-secrets

`brew bundle` skips formulae already installed.

</details>

## Daily CLI toolkit (`Brewfile.cli`)

<details>
<summary>Brewfile.cli — daily-driver CLI formulae</summary>

```bash
make cli
# or: brew bundle --file=~/dotfiles/Brewfile.cli
```

**Not** installed by bootstrap. CLI tools you use across development work but that are not required for dotfiles to function — cloud CLIs, k8s tooling, language runtimes, network diagnostics, etc.

Grouped by category (Security, DevOps, Languages, Networking, Utilities). Tap-prefixed formulae (e.g. `hashicorp/tap/terraform`) need a matching `tap` line at the top of the file.

To add a new daily CLI tool: add a `brew "…"` line under the right section in `Brewfile.cli`, then run `make cli`.

</details>

## GUI apps (`Brewfile.apps`)

<details>
<summary>Brewfile.apps — daily-driver GUI casks</summary>

```bash
make apps
# or: brew bundle --file=~/dotfiles/Brewfile.apps
```

**Not** installed by bootstrap. User-facing apps grouped by category:

- **Productivity:** Rectangle, Typora, Microsoft 365 Copilot
- **Security:** Keeper Password Manager
- **Communication:** Slack, Windows App
- **Media:** Spotify, Kap, OBS
- **Dev tools:** Cursor, VS Code, Docker Desktop, Postman, DBeaver, Android platform tools, etc.
- **Utilities:** Brave Browser, SensibleSideButtons

To add a new GUI app: add a `cask "…"` line under the right section in `Brewfile.apps`, then run `make apps`.

</details>

## Archive (`Brewfile.archive`)

<details>
<summary>Brewfile.archive — full historical dump</summary>

Your previous complete `brew bundle dump` — CLI formulae, taps, VS Code extensions, Go modules, and casks not yet split out.

Gitignored — kept locally for reference only. Not installed by default. Use as a reference when cherry-picking:

```bash
brew bundle --file=~/dotfiles/Brewfile.archive
```

Or move lines into `Brewfile` (core), `Brewfile.cli` (daily CLI), or `Brewfile.apps` (GUI casks) as you review them.

</details>

## What goes where

| File | Contents | Install |
|------|----------|---------|
| `Brewfile` | CLI tools required for dotfiles | `make brew-bundle` / bootstrap |
| `Brewfile.cli` | Daily CLI toolkit (cloud, k8s, langs, etc.) | `make cli` |
| `Brewfile.apps` | GUI casks (apps, not fonts) | `make apps` |
| `Brewfile.archive` | Historical reference (gitignored, local only) | manual |

### Rules of thumb

- **`Brewfile`** — would a fresh `make bootstrap` break without it? Shell, git, chezmoi, pre-commit guard → here.
- **`Brewfile.cli`** — CLI tool you reach for daily but dotfiles don't depend on → here.
- **`Brewfile.apps`** — GUI cask (`.app` in `/Applications`) → here.
- **`Brewfile.archive`** — do not resurrect; gitignored local reference only.

### Tap-prefixed formulae

When a formula uses the `owner/tap/name` form (e.g. `fluxcd/tap/flux`, `hashicorp/tap/terraform`), add a `tap "owner/tap"` line at the top of `Brewfile.cli` before the `brew` lines:

```ruby
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"
```

### Adding new tools

| Want to install… | Edit | Run |
|------------------|------|-----|
| Dotfile-required CLI | `Brewfile` | `make brew-bundle` |
| Daily CLI tool | `Brewfile.cli` | `make cli` |
| GUI app | `Brewfile.apps` | `make apps` |
