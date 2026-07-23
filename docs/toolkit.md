# Toolkit

Reference for every tool tracked in this repo — what it does, why it's here, and how to use it. Install commands and file layout live in [brew.md](brew.md); shell integration paths are in [shell.md](shell.md).

## Table of contents

- [Core (Brewfile)](#core-brewfile) — [Chezmoi + terminal](#chezmoi--terminal) · [Shell](#shell) · [Git](#git) · [Pre-commit guard](#pre-commit-guard)
- [Daily CLI (Brewfile.cli)](#daily-cli-brewfilecli) — [Security](#security--secrets) · [DevOps](#devops--infra) · [Languages](#languages--toolchains) · [Networking](#networking--diagnostics) · [Utilities](#utilities)
- [GUI apps (Brewfile.apps)](#gui-apps-brewfileapps) — [Productivity](#productivity) · [Security](#security-1) · [Communication](#communication) · [Media](#media) · [Dev tools](#dev-tools) · [Utilities](#utilities-1)
- [Related docs](#related-docs)

## Core (Brewfile)

These install with `make bootstrap` (or `make brew-bundle`). Required for the dotfiles setup — shell, git, chezmoi, and pre-commit secret scanning.

### Chezmoi + terminal

#### `chezmoi`
Dotfile manager. Tracks files under `home/` and applies them to `~/.foo`.
```bash
chezmoi diff && chezmoi apply    # preview then apply (or: make apply)
chezmoi add ~/.ssh/config        # track a new file
```

Docs: https://chezmoi.io/user-guide/command-overview/

#### Ghostty
GPU-accelerated terminal emulator. Configured in `home/dot_config/ghostty/config` with JetBrains Mono Nerd Font.

Docs: https://ghostty.org/docs

#### `font-jetbrains-mono-nerd-font`
Nerd Font variant of JetBrains Mono — icons and ligatures for Starship, eza, and terminal UIs.

Docs: https://github.com/ryanoasis/nerd-fonts

### Shell

#### `starship`
Cross-shell prompt. Initialized in `~/.zshrc`; config at `~/.config/starship.toml`.
```bash
starship config           # open config in $EDITOR
starship explain          # decode current prompt segments
```

Docs: https://starship.rs/config/

#### `atuin`
Shell history sync and search — fuzzy, context-aware replacement for Ctrl+R.
```bash
atuin search kubectl      # fuzzy-search past commands
atuin sync                # sync history across machines
```

Docs: https://docs.atuin.sh/

#### `zoxide`
Smart directory jumper — learns frequently used paths.
```bash
z dotfiles                # jump to closest match
zi                        # interactive pick with fzf
```

Docs: https://github.com/ajeetdsouza/zoxide

#### `direnv`
Per-directory environment variables via `.envrc` files.
```bash
echo 'export AWS_PROFILE=dev' > .envrc && direnv allow
```

Docs: https://direnv.net/

#### `fzf`
Fuzzy finder. Bound to `Ctrl+T` (files) and `Alt+C` (directories) in zsh; previews use bat/eza.
```bash
vim $(fzf)                # interactive file picker
ls | fzf                  # filter any list
```

Docs: https://github.com/junegunn/fzf

#### `fd`
Fast `find` alternative. Respects `.gitignore` by default.
```bash
fd '\.toml$'              # find TOML files recursively
fd -e md docs             # markdown under docs/
```

Docs: https://github.com/sharkdp/fd

#### `ripgrep`
Fast recursive grep; respects `.gitignore`. Powers fzf and editor search.
```bash
rg 'TODO' --type rust
rg -l 'chezmoi' docs/
```

Docs: https://github.com/BurntSushi/ripgrep

#### `eza`
Modern `ls` with icons, git status, and tree view.
```bash
eza -la --git
eza --tree --level=2
```

Docs: https://github.com/eza-community/eza

#### `bat`
Syntax-highlighting `cat`. Used as fzf file preview.
```bash
bat README.md
bat --diff file1 file2
```

Docs: https://github.com/sharkdp/bat

#### `fastfetch`
System info display. Not auto-run on shell start — invoke manually.
```bash
fastfetch
ssh user@host fastfetch --logo none --pipe
```

Docs: https://github.com/fastfetch-cli/fastfetch

#### `zsh-syntax-highlighting`
Real-time command syntax highlighting in zsh. Sourced from `$(brew --prefix)` in `.zshrc`.

Docs: https://github.com/zsh-users/zsh-syntax-highlighting

#### `tmux`
Terminal multiplexer — persistent sessions and splits.
```bash
tmux new -s work
tmux attach -t work
```

Docs: https://github.com/tmux/tmux/wiki

### Git

#### `git`
Version control. Homebrew provides current releases beyond macOS's bundled git.
```bash
git status && git log --oneline -10
git diff --staged
```

Docs: https://git-scm.com/doc

#### `gh`
GitHub CLI — PRs, issues, repos, and auth from the terminal.
```bash
gh pr create --fill
gh auth login
```

Docs: https://cli.github.com/manual/

### Pre-commit guard

#### `pre-commit`
Git hook framework. Runs secret scanners and linters before commits.
```bash
pre-commit install && pre-commit run --all-files
make lint                 # run all hooks repo-wide
```

Docs: https://pre-commit.com/

#### `gitleaks`
Scans git history and files for hardcoded secrets.
```bash
gitleaks detect --source . --verbose
```

Docs: https://github.com/gitleaks/gitleaks

#### `detect-secrets`
Baseline-based secret scanner — flags new secrets vs. an approved baseline.
```bash
detect-secrets scan --baseline .secrets.baseline
detect-secrets audit .secrets.baseline
```

Docs: https://github.com/Yelp/detect-secrets

## Daily CLI (Brewfile.cli)

These install with `make cli`. Daily-driver tools for development — not required for dotfiles to function.

### Security / secrets

#### `age`
Modern file encryption. Used with SOPS and standalone workflows.
```bash
age-keygen -o key.txt
age -r $(cat key.txt.pub) -o secret.age plaintext.txt
```

Docs: https://github.com/FiloSottile/age

#### `bitwarden-cli`
Bitwarden vault CLI (`bw`) for scriptable password access.
```bash
bw login && bw list items --search github
bw get password <item-id>
```

Docs: https://bitwarden.com/help/cli/

#### `gnupg`
GPG for signing commits, encrypting files, and key management.
```bash
gpg --full-generate-key
gpg --sign file.txt
```

Docs: https://gnupg.org/documentation/

#### `keeper-commander`
Keeper vault CLI — companion to the Keeper desktop app.
```bash
keeper login && keeper list
keeper get password <record>
```

Docs: https://docs.keeper.io/en/keeperpam/commander-cli

#### `keyring`
Python keyring CLI — shared OS credential store for scripts.
```bash
keyring set myservice myuser
keyring get myservice myuser
```

Docs: https://pypi.org/project/keyring/

#### `mkcert`
Locally-trusted TLS certificates for development.
```bash
mkcert -install
mkcert localhost 127.0.0.1 ::1
```

Docs: https://github.com/FiloSottile/mkcert

#### `sops`
Mozilla SOPS — encrypt YAML/JSON/env files with age or PGP keys.
```bash
sops -e secrets.yaml > secrets.enc.yaml
sops secrets.enc.yaml     # decrypt in place for editing
```

Docs: https://github.com/getsops/sops

### DevOps / Infra

#### `ansible`
Configuration management and ad-hoc remote execution.
```bash
ansible all -m ping -i inventory.ini
ansible-playbook site.yml --check --diff
```

Docs: https://docs.ansible.com/

#### `ansible-lint`
Best-practice linter for Ansible playbooks and roles.
```bash
ansible-lint playbook.yml
ansible-lint --fix
```

Docs: https://ansible.readthedocs.io/projects/lint/

#### `awscli`
AWS command-line interface (v2).
```bash
aws sts get-caller-identity
aws eks update-kubeconfig --name my-cluster
```

Docs: https://docs.aws.amazon.com/cli/

#### `flux`
Flux CD CLI for GitOps on Kubernetes.
```bash
flux check --pre
flux reconcile source git flux-system
```

Docs: https://fluxcd.io/flux/cmd/

#### `terraform`
Infrastructure-as-code — plan and apply cloud resources.
```bash
terraform init && terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

Docs: https://developer.hashicorp.com/terraform/docs

#### `helm`
Kubernetes package manager.
```bash
helm install my-nginx bitnami/nginx
helm list -A
```

Docs: https://helm.sh/docs/

#### `kubectx`
Fast Kubernetes context/namespace switching (`kubectx` / `kubens`).
```bash
kubectx prod-cluster
kubens monitoring
```

Docs: https://github.com/ahmetb/kubectx

#### `kustomize`
Kubernetes native config management — overlays without templating.
```bash
kubectl apply -k overlays/prod
kustomize build . | kubectl diff -f -
```

Docs: https://kubectl.docs.kubernetes.io/references/kustomize/

#### `minikube`
Local Kubernetes cluster for development.
```bash
minikube start --driver=docker
minikube kubectl -- get pods -A
```

Docs: https://minikube.sigs.k8s.io/docs/

#### `stern`
Multi-pod log tailing for Kubernetes.
```bash
stern app=nginx -n default
stern --since 5m 'api-.*'
```

Docs: https://github.com/stern/stern

#### `terraform-docs`
Auto-generate Markdown docs from Terraform module inputs/outputs.
```bash
terraform-docs markdown table ./modules/vpc > README.md
```

Docs: https://terraform-docs.io/

#### `tflint`
Terraform linter — errors, deprecated syntax, provider rules.
```bash
tflint --init && tflint
tflint --recursive
```

Docs: https://github.com/terraform-linters/tflint

#### `yamllint`
YAML file linter.
```bash
yamllint .pre-commit-config.yaml
yamllint --format parsable .
```

Docs: https://yamllint.readthedocs.io/

### Languages / Toolchains

#### `deno`
Modern JS/TS runtime with built-in fmt, lint, and test.
```bash
deno run --allow-net server.ts
deno fmt && deno lint
```

Docs: https://docs.deno.com/

#### `go`
Go language toolchain.
```bash
go test ./...
go build -o bin/myapp ./cmd/myapp
```

Docs: https://go.dev/doc/

#### `go-task`
Task runner for Go projects (Taskfile.yml).
```bash
task --list && task build
```

Docs: https://taskfile.dev/

#### `ruby`
Ruby runtime and gem ecosystem.
```bash
gem install bundler && bundle install
```

Docs: https://www.ruby-lang.org/en/documentation/

#### `uv`
Fast Python package installer — drop-in pip replacement.
```bash
uv venv && source .venv/bin/activate
uv pip install requests
```

Docs: https://docs.astral.sh/uv/

### Networking / Diagnostics

#### `sshpass`
Non-interactive SSH with password auth — legacy automation only; prefer keys.
```bash
sshpass -p 'password' ssh user@host 'hostname'
```

Docs: https://sourceforge.net/projects/sshpass/

#### `inetutils`
GNU network utilities (telnet, ftp, etc.) that macOS omits or ships differently.
```bash
telnet example.com 80
```

Docs: https://www.gnu.org/software/inetutils/

#### `ipcalc`
Subnet math — CIDR, netmask, broadcast from an IP/prefix.
```bash
ipcalc 10.0.0.0/24
```

Docs: http://jodies.de/ipcalc

#### `iperf3`
Network throughput measurement between two hosts.
```bash
iperf3 -s                  # server
iperf3 -c server.example.com -t 30
```

Docs: https://github.com/esnet/iperf

#### `mtr`
Interactive traceroute + ping — packet loss per hop.
```bash
mtr google.com
mtr -r -c 10 api.example.com
```

Docs: https://www.bitwizard.nl/mtr/

#### `netcat`
TCP/UDP swiss-army knife — port probes and listeners.
```bash
nc -zv host.example.com 443
nc -l 8080
```

Docs: https://nmap.org/ncat/

#### `nmap`
Network scanner — port discovery and service detection.
```bash
nmap -sV localhost
nmap -p 1-1024 192.168.1.0/24
```

Docs: https://nmap.org/book/man.html

#### `tcptraceroute`
TCP-based traceroute — useful when ICMP is blocked.
```bash
tcptraceroute google.com 443
```

Docs: https://github.com/matt-kimball/traceroute

#### `trippy`
Modern mtr replacement with TUI — ICMP/TCP/UDP tracing.
```bash
trip google.com
trip --protocol tcp api.example.com:443
```

Docs: https://github.com/fujiapple/trippy

#### `wget`
Non-interactive HTTP/HTTPS downloader.
```bash
wget -c https://example.com/large.iso
wget -r -l 1 -np https://docs.example.com/
```

Docs: https://www.gnu.org/software/wget/manual/

### Utilities

#### `commitlint`
Conventional commit message linter.
```bash
echo "feat: add login" | commitlint
commitlint --from HEAD~5 --to HEAD
```

Docs: https://commitlint.js.org/

#### `coreutils`
GNU coreutils with `g` prefix (`gls`, `gdate`, etc.).
```bash
gls --color=auto -la
gdate -d 'yesterday' +%Y-%m-%d
```

Docs: https://www.gnu.org/software/coreutils/

#### `d2`
Diagram-as-code — modern graphviz replacement.
```bash
d2 architecture.d2 architecture.svg
```

Docs: https://d2lang.com/

#### `docutils`
reStructuredText tools (`rst2html`, `rst2man`, etc.).
```bash
rst2html README.rst > README.html
```

Docs: https://docutils.sourceforge.io/

#### `graphviz`
Graph visualization from DOT language.
```bash
dot -Tpng graph.dot -o graph.png
```

Docs: https://graphviz.org/documentation/

#### `gnuplot`
Command-line plotting for data files.
```bash
gnuplot -e "plot 'data.csv' using 1:2 with lines"
```

Docs: http://www.gnuplot.info/documentation.html

#### `htop`
Interactive process viewer.
```bash
htop
htop -u $USER
```

Docs: https://htop.dev/

#### `hugo`
Fast static site generator.
```bash
hugo server -D
hugo --minify
```

Docs: https://gohugo.io/documentation/

#### `jq`
JSON processor and query language.
```bash
curl -s https://api.github.com/users/codecio | jq '.name'
kubectl get pods -o json | jq '.items[].metadata.name'
```

Docs: https://jqlang.org/manual/

#### `pandoc`
Universal document converter — Markdown, PDF, DOCX, HTML.
```bash
pandoc README.md -o README.pdf
pandoc report.docx -t markdown -o report.md
```

Docs: https://pandoc.org/MANUAL.html

#### `prettier`
Opinionated formatter for JS, TS, CSS, Markdown, JSON.
```bash
prettier --write 'src/**/*.{js,ts,md}'
prettier --check .
```

Docs: https://prettier.io/docs/en/

#### `shellcheck`
Static analyzer for shell scripts.
```bash
shellcheck scripts/deploy.sh
```

Docs: https://www.shellcheck.net/

#### `shfmt`
Shell script formatter.
```bash
shfmt -w -i 2 scripts/*.sh
```

Docs: https://github.com/mvdan/sh

#### `watch`
Re-run a command and show fresh output.
```bash
watch -n 2 'kubectl get pods'
```

Docs: https://gitlab.com/procps-ng/procps

#### `yq`
YAML processor — like `jq` for YAML.
```bash
yq '.spec.replicas' deployment.yaml
yq -i '.metadata.labels.env = "prod"' config.yaml
```

Docs: https://mikefarah.gitbook.io/yq/

## GUI apps (Brewfile.apps)

These install with `make apps`. User-facing applications — not required for dotfiles.

### Productivity

| App | Purpose | Link |
|-----|---------|------|
| Rectangle | Keyboard-driven window snapping and resizing | https://rectangleapp.com |
| Typora | Minimal WYSIWYG Markdown editor | https://typora.io |
| Microsoft 365 Copilot | AI productivity assistant for Microsoft 365 | https://www.microsoft.com/en-us/microsoft-365-copilot |

### Security

| App | Purpose | Link |
|-----|---------|------|
| Keeper Password Manager | Password manager; pairs with `keeper-commander` CLI | https://www.keepersecurity.com |

### Communication

| App | Purpose | Link |
|-----|---------|------|
| Slack | Team messaging and collaboration | https://slack.com |
| Windows App | Microsoft Remote Desktop client | https://learn.microsoft.com/en-us/windows-app/ |

### Media

| App | Purpose | Link |
|-----|---------|------|
| Spotify | Music streaming | https://www.spotify.com |
| Kap | Open-source screen recorder (GIF/MP4) | https://getkap.co |

### Dev tools

| App | Purpose | Link |
|-----|---------|------|
| Cursor | AI-first code editor (`no-binaries` avoids Gatekeeper prompt) | https://cursor.com |
| Visual Studio Code | Open-source code editor | https://code.visualstudio.com |
| Docker Desktop | Local containers and Kubernetes | https://www.docker.com/products/docker-desktop/ |
| Postman | API development and testing | https://www.postman.com |
| DBeaver Community | Universal database / SQL client | https://dbeaver.io |
| Apache Directory Studio | LDAP browser and directory client | https://directory.apache.org/studio/ |
| Copilot CLI | GitHub Copilot in the terminal | https://docs.github.com/en/copilot/github-copilot-cli |
| KeyStore Explorer | GUI for Java keystores (`keytool` / `jarsigner`) | https://keystore-explorer.org |

### Utilities

| App | Purpose | Link |
|-----|---------|------|
| Brave Browser | Privacy-focused Chromium browser | https://brave.com |
| SensibleSideButtons | Mouse side-button forward/back on macOS | https://sensible-side-buttons.app |

## Related docs

- [brew.md](brew.md) — Brewfile architecture (core vs cli vs apps vs archive)
- [bootstrap.md](bootstrap.md) — fresh Mac setup and `make bootstrap`
- [shell.md](shell.md) — zsh, Starship, fzf, tmux config paths
- [chezmoi.md](chezmoi.md) — profiles, apply, add files
