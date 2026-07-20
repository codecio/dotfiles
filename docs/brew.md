# Brew

Three Brewfiles: core toolchain, GUI apps, and a historical archive.

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

## GUI apps (`Brewfile.apps`)

<details>
<summary>Brewfile.apps — daily-driver GUI casks</summary>

```bash
make apps
# or: brew bundle --file=~/dotfiles/Brewfile.apps
```

**Not** installed by bootstrap. User-facing apps grouped by category:

- **Productivity:** Rectangle, Typora, Microsoft 365 Copilot
- **Communication:** Slack, Microsoft Remote Desktop, Parsec
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

Or move lines into `Brewfile` (core CLI tools) or `Brewfile.apps` (GUI casks) as you review them.

</details>

## What goes where

| File | Contents | Install |
|------|----------|---------|
| `Brewfile` | CLI tools required for dotfiles | `make brew-bundle` / bootstrap |
| `Brewfile.apps` | GUI casks (apps, not fonts) | `make apps` |
| `Brewfile.archive` | Historical reference (gitignored, local only) | manual |

CLI formulae from the archive (k8s, Python, ansible, etc.) stay in the archive until you deliberately add them to `Brewfile` or a future work-specific file.
