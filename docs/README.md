# Docs

How this repo is laid out, and where each topic lives. `make help` is the command list.

## Repo map

```
dotfiles/                  git clone target; chezmoi sourceDir after init
├── home/                  chezmoi source (.chezmoiroot = home)
│   ├── dot_*              → ~/.foo
│   ├── dot_config/        → ~/.config/
│   ├── private_dot_ssh/   → ~/.ssh/ (mode 600)
│   └── .chezmoi.toml.tmpl → ~/.config/chezmoi/chezmoi.toml on init
├── Brewfile*              Homebrew splits — see brew.md
├── Extfile*               editor extensions — see editors.md
├── Makefile               bootstrap + daily ops
├── scripts/               helpers invoked by Make
└── docs/                  this folder
```

Edit `home/`, then `make apply`. Do not edit live `~/.zshrc` / `~/.gitconfig`.

## Index

| Doc | Topic |
|-----|-------|
| [bootstrap.md](bootstrap.md) | `make bootstrap`, fresh vs existing Mac |
| [chezmoi.md](chezmoi.md) | source tree, init, git identity, apply |
| [shell.md](shell.md) | zsh, Starship, fzf, tmux, Ghostty, local overrides |
| [brew.md](brew.md) | Core vs cli vs apps vs archive |
| [editors.md](editors.md) | VS Code + Cursor Extfile sync |
| [python.md](python.md) | Interpreters, uv, pip guard |
| [toolkit.md](toolkit.md) | Per-tool purpose, usage, links |
| [cursor-plugins.md](cursor-plugins.md) | Cursor plugins + chezmoi-managed skills |

`docs/research/` is gitignored local notes. Durable conclusions belong in the pages above.
