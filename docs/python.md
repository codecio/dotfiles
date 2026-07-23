# Python

How Python is laid out on a managed Mac: Homebrew supplies interpreters and Python CLI apps, `uv` handles project venvs, and global `pip install` into brew Python is blocked.

## Roles

| Layer | Tool | Purpose |
|-------|------|---------|
| Interpreters | Homebrew `python@3.x` | System-wide Python versions — no user packages |
| Python CLIs | Homebrew formula (e.g. `gimme-aws-creds`) | Each formula gets its own isolated venv — no global pip conflicts |
| One-offs | `uvx <pkg>` | Run a tool once without installing |
| Project libs | `uv venv` / direnv | Per-repo dependencies |

## Python CLI apps (Homebrew)

Install with `brew install <formula>`. Homebrew wraps each Python CLI in a dedicated venv under the Cellar, so tools like `gimme-aws-creds` don't share or clash with global pip packages.

Add a recurring CLI to your Brewfile when you rework it (`Brewfile` or `Brewfile.cli` depending on tier).

## Global pip guard

`home/dot_config/pip/pip.conf` sets `require-virtualenv = true`. Bare `pip3 install` outside a venv is refused; `uvx`, brew-managed CLIs, and `pip install` inside an activated venv still work.

`~/.local/bin` stays on PATH via `dot_zprofile` (for user-installed binaries like age/sops).

## Do not

- `pip install` into brew's global Python — use a brew formula for CLIs or a project venv for libraries.
- `pip uninstall` packages that Homebrew owns (cross-check `pip3 list` vs `brew list --formula`).
- Install `pipx` — Homebrew-isolated CLIs and `uvx` cover the use cases.

## Leftover Intel `/usr/local` pip

Older global pip installs under `/usr/local/lib/python3.11/site-packages` are obsolete. Do not remove non-Python `/usr/local/bin` tools (Docker, Vagrant, Perforce, etc.).
