# Shell

Config paths in the chezmoi `home/` tree and live destinations after `chezmoi apply`.

## zsh

<details>
<summary>~/.zshrc, ~/.zprofile, ~/.zshenv</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_zshrc` | `~/.zshrc` |
| `home/dot_zprofile` | `~/.zprofile` |
| `home/dot_zshenv` | `~/.zshenv` |

**Prompt:** Starship (`eval "$(starship init zsh)"`) — powerlevel10k removed.

**Hooks:** atuin, zoxide, direnv (always). fastfetch is **not** auto-run — invoke manually with `fastfetch`.

**Paths:** syntax-highlighting and terraform completion use `$(brew --prefix)`.

**SSH:** no wrapper needed. Ghostty is configured with `term = xterm-256color` so the universal terminfo entry is used everywhere (local + remote). See `home/dot_config/ghostty/config` for the rationale (heterogeneous remote SSH targets where `xterm-ghostty` terminfo isn't available).

</details>

## Starship

<details>
<summary>~/.config/starship.toml</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_config/starship.toml` | `~/.config/starship.toml` |

Minimal config with character prompt symbols. Extend as needed.

</details>

## fzf

<details>
<summary>~/.config/fzf/fzf.zsh + FZF_* opts in zshrc</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_config/fzf/fzf.zsh` | `~/.config/fzf/fzf.zsh` |

`dot_zshrc` sources **only** `~/.config/fzf/fzf.zsh` (not `~/.fzf.zsh`). That file adds fzf to `PATH`, loads completion, and installs key bindings from the Homebrew fzf package.

Bootstrap may still run `fzf/install` if `~/.fzf.zsh` is missing from a prior install — the chezmoi-managed config does not depend on it.

**Appearance** (`FZF_DEFAULT_OPTS` in `dot_zshrc`): Tokyo Night palette, `--border=rounded`.

**Previews** (gated on installed tools):

| Binding | Preview | Requires |
|---------|---------|----------|
| Ctrl+T | `bat` on selected file | `bat` |
| Alt+C | `eza --tree` on selected directory | `eza` |
| Ctrl+/ | toggle preview pane | either binding above |

</details>

## fastfetch

<details>
<summary>~/.config/fastfetch/config.jsonc</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_config/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |

Run on demand: `fastfetch`. Not invoked from `.zshrc`.

**Remote systems:** run it over SSH against the *remote's* OS info with:

```bash
ssh user@host fastfetch --logo none --pipe
```

This requires `fastfetch` to be installed on the remote host. `--pipe` strips ANSI colors for cleaner output in non-TTY contexts; drop it for colorized output. To see *your local* machine's info from inside an SSH session, just type `fastfetch` after connecting (assuming your dotfiles are synced there too).

</details>

## tmux

<details>
<summary>~/.tmux.conf + TPM</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_tmux.conf` | `~/.tmux.conf` |

Plugins: tpm, sensible, resurrect, continuum.

After apply: `prefix + I` in tmux to install plugins (bootstrap clones TPM if missing).

</details>

## Ghostty

<details>
<summary>~/.config/ghostty/config</summary>

| Repo source | Destination |
|-------------|-------------|
| `home/dot_config/ghostty/config` | `~/.config/ghostty/config` |

</details>

## Tool cheat-sheet

<details>
<summary>Common commands</summary>

| Tool | Reminder |
|------|----------|
| atuin | `atuin register` after install |
| zoxide | `z <dir>` to jump |
| direnv | `.envrc` in project dirs |
| eza | `alias ll` still uses `ls` — switch to `eza` later |
| bat | `bat file` instead of `cat` |

</details>
