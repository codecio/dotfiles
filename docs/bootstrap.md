# Bootstrap

`make bootstrap` is idempotent: each step detects what's already installed and logs `✓ already …` instead of redoing work.

After bootstrap, use `make <target>` from the repo root for daily ops (`make help` lists all targets).

## Fresh Mac

<details>
<summary>Typical order on a new machine</summary>

1. Install Xcode CLT: `xcode-select --install`
2. Clone repo to `~/dotfiles`
3. `cd ~/dotfiles && make bootstrap` — Homebrew, core Brewfile, chezmoi init/apply, fzf bindings, TPM, pre-commit hooks
4. `make lint`

</details>

## Existing machine

<details>
<summary>Already have brew, git, fzf, etc.</summary>

Many core Brewfile tools may already be installed. Individual targets skip when done:

| Target | Skip when |
|--------|-----------|
| `make xcode-clt` | `xcode-select -p` succeeds |
| `make brew` | `brew` in PATH |
| `make brew-bundle` | per-formula (Homebrew skips installed) |
| `make chezmoi-init` | `~/.config/chezmoi/chezmoi.toml` exists |
| `make fzf-install` | `~/.fzf.zsh` exists |
| `make tpm-install` | `~/.tmux/plugins/tpm` exists |

Run only what you need:

```bash
make brew-bundle      # re-sync Brewfile packages
make apply            # apply dotfile changes without full bootstrap
```

</details>

## Bootstrap targets

<details>
<summary>What `make bootstrap` runs (in order)</summary>

| Target | What it does |
|--------|----------------|
| `xcode-clt` | Verify Xcode CLT; prompt install if missing |
| `brew` | Install Homebrew if missing |
| `brew-bundle` | `brew bundle --file=~/dotfiles/Brewfile` |
| `chezmoi-init` | `chezmoi init --source=~/dotfiles/home` (prompts for machine profile) |
| `apply` | `chezmoi diff` + `chezmoi apply` |
| `fzf-install` | fzf key bindings → `~/.fzf.zsh` |
| `tpm-install` | Clone TPM to `~/.tmux/plugins/tpm` |
| `hooks-install` | `pre-commit install` |

</details>

## Reminders (not automated)

<details>
<summary>Manual steps after bootstrap</summary>

- `make lint` (hooks installed during bootstrap)
- `gh auth login`
- `atuin register`
- In tmux: `prefix + I` to install TPM plugins

</details>
