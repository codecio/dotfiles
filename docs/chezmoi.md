# Chezmoi

Source root: `home/` (set by `.chezmoiroot` at the repo root).

## Source layout

<details>
<summary>home/ tree, dot_ prefix, private_, .tmpl</summary>

Chezmoi maps files under `home/` to your home directory:

| Source pattern | Destination | Meaning |
|----------------|-------------|---------|
| `dot_zshrc` | `~/.zshrc` | `dot_` → `.` at the front of the basename |
| `dot_config/fzf/fzf.zsh` | `~/.config/fzf/fzf.zsh` | `dot_config/` → `.config/` |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | `private_` → private (mode 600) |
| `*.tmpl` | rendered on apply | Go templates; `.tmpl` suffix stripped |

Edit files in `~/dotfiles/home/` (or use `chezmoi edit ~/.zshrc` to open the source path).

</details>

## Machine profiles

<details>
<summary>home, work</summary>

On first `chezmoi init`, `home/.chezmoi.toml.tmpl` prompts once for:

| Field | Prompt |
|-------|--------|
| `machine` | Profile ID — one of `home`, `work` |

The generated `~/.config/chezmoi/chezmoi.toml` also sets:

```toml
sourceDir = "~/dotfiles"
[git]
    autoCommit = false
    autoPush = false
```

Because `sourceDir` is baked in, plain `chezmoi apply` works after init — no need to pass `--source` every time.

Git identity is **not** prompted here; see [Git identity](#git-identity) below.

</details>

## Git identity

<details>
<summary>Path-based includeIf — not chezmoi prompts</summary>

`home/dot_gitconfig.tmpl` sets a **default personal identity** at the top, then uses `includeIf "gitdir:…"` rules to override by working directory:

| Path prefix | Included file | `user.name` / `user.email` |
|-------------|---------------|----------------------------|
| `~/development/` | `~/.gitconfig.work` (`dot_gitconfig.work`) | `<work-name>` / `<work-email>` |
| `~/home/` | `~/.gitconfig.personal` (`dot_gitconfig.personal`) | codecio / matt@colecio.com |
| `~/dotfiles/` | `~/.gitconfig.personal` | codecio / matt@colecio.com |
| everywhere else | default in `dot_gitconfig.tmpl` | codecio / matt@colecio.com |

Trailing slashes on `gitdir:` paths matter — they mean “this directory and everything under it.”

Edit the hardcoded values in `dot_gitconfig.tmpl`, `dot_gitconfig.personal`, and `dot_gitconfig.work` directly; no chezmoi template variables for name or email. Use placeholders like `<work-name>` / `<work-email>` in docs; real values live only in the gitconfig source files.

</details>

## Common commands

<details>
<summary>apply, diff, edit, cd, source-path</summary>

Or from the repo root: `make apply`, `make diff`, `make edit FILE=~/.zshrc`, etc. (`make help`).

```bash
# First time (bootstrap does this)
chezmoi init --source=~/dotfiles/home

# After editing repo — sourceDir is already configured
chezmoi apply

# See what would change
chezmoi diff

# Edit source file in repo (opens $EDITOR on the chezmoi source path)
chezmoi edit ~/.zshrc

# Jump to chezmoi source root
chezmoi cd

# Print path to a managed file's source
chezmoi source-path ~/.zshrc

# Add a new file from home into the repo
chezmoi add ~/.some-config
```

</details>

## Templates

<details>
<summary>dot_gitconfig.tmpl, private_dot_ssh/config.tmpl</summary>

| Source | Notes |
|--------|-------|
| `home/dot_gitconfig.tmpl` | Default git config + `includeIf` rules; includes `.personal` / `.work` fragments |
| `home/private_dot_ssh/config.tmpl` | Static sanitized `Host *` defaults |

</details>
