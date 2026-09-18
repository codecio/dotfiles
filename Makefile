# ============================================================
# Dotfiles Makefile — single entry point for setup + daily ops
# ============================================================
# Quick start:
#   make help           # see all targets grouped by section
#   make bootstrap      # full first-time setup on a fresh Mac
#   make apply          # daily: push pending dotfile changes to live
#   make sync           # full re-sync after editing templates
#
# Learning Make:
#   .PHONY targets always run (not file-based)
#   $(VAR) expands a variable
#   $@ is the current target name, $< is the first prereq
#   @ prefix silences command echo
#   - prefix ignores errors
# ============================================================

SHELL    := /bin/zsh
.DEFAULT_GOAL := help

# Teaching note: SHELL := /bin/zsh ensures recipes run under macOS's universal
# zsh (ARM-native on Apple Silicon). /bin/bash on macOS is a legacy x86 binary
# that triggers Rosetta and breaks `brew` operations under /opt/homebrew.

REPO     := $(HOME)/dotfiles
SOURCE   := $(REPO)/home

CYAN  := \033[36m
GREEN := \033[32m
YELLOW:= \033[33m
RESET := \033[0m

# Teaching note: := is immediate assignment (evaluated once at parse time).
# Use = for deferred assignment. For paths and constants, := is the usual choice.

.PHONY: help \
        apply diff edit status sync lint \
        bootstrap upgrade reinit reset-baseline clean whoami apps cli \
        ext ext-diff ext-dump ext-prune \
        xcode-clt brew brew-bundle chezmoi-init fzf-install tpm-install hooks-install

##@ Daily ops

# Teaching note: $(REPO) is a make variable. Variables are expanded with $(NAME).
# Recipe lines must start with a real TAB, not spaces.

apply: ## Push pending dotfile changes to live files
	@chezmoi diff
	@chezmoi apply
	@printf "$(GREEN)✓ Applied.$(RESET) Run '$(CYAN)reload$(RESET)' to refresh your shell.\n"

diff: ## Preview pending changes (no writes)
	@out=$$(chezmoi diff); \
	if [ -z "$$out" ]; then \
		printf "  $(GREEN)✓ no drift$(RESET)\n"; \
	else \
		printf "%s\n" "$$out"; \
	fi

edit: ## Edit a source file by destination path (make edit FILE=~/.zshrc)
	$(if $(FILE),,$(error FILE is required, e.g. make edit FILE=~/.zshrc))
	@chezmoi edit $(FILE)

status: ## Show drift between repo and live
	@out=$$(chezmoi status); \
	if [ -z "$$out" ]; then \
		printf "  $(GREEN)✓ no drift$(RESET)\n"; \
	else \
		printf "%s\n" "$$out"; \
	fi

sync: reinit reset-baseline apply lint ## Full re-sync: regen chezmoi config, reset baseline, apply, lint
	@printf "$(GREEN)✓ Sync complete!$(RESET) Run '$(CYAN)reload$(RESET)' in your shell.\n"

lint: ## Run pre-commit on all files
	@pre-commit run --all-files

##@ Setup & maintenance

# Teaching note: prerequisites run before this target's recipe, in listed order.
# bootstrap chains every setup step; each step is also runnable on its own
# (e.g. `make brew-bundle` to re-bundle without re-installing brew).

bootstrap: xcode-clt brew brew-bundle chezmoi-init apply tpm-install hooks-install ## Full first-time setup on a fresh Mac
	@printf "$(GREEN)✓ Bootstrap complete!$(RESET) Open a new terminal tab to pick up shell changes.\n"

upgrade: ## Upgrade brew packages + refresh pre-commit hooks (slow)
	@brew update
	@brew upgrade
	@brew cleanup
	@pre-commit autoupdate

reinit: ## Regenerate ~/.config/chezmoi/chezmoi.toml from updated template
	@printf "$(YELLOW)→ Removing stale chezmoi config...$(RESET)\n"
	@rm -f "$(HOME)/.config/chezmoi/chezmoi.toml"
	@chezmoi init --source="$(SOURCE)"
	@printf "$(GREEN)✓ chezmoi.toml regenerated$(RESET)\n"

reset-baseline: ## Regenerate .secrets.baseline using pre-commit's detect-secrets
	@printf "$(YELLOW)→ Regenerating .secrets.baseline...$(RESET)\n"
	@DS=$$(find $(HOME)/.cache/pre-commit -path '*detect-secrets*/py_env-*/bin/detect-secrets' 2>/dev/null | head -1); \
	if [ -z "$$DS" ]; then \
		printf "$(YELLOW)→ Installing pre-commit detect-secrets venv...$(RESET)\n"; \
		pre-commit install-hooks >/dev/null 2>&1 || true; \
		DS=$$(find $(HOME)/.cache/pre-commit -path '*detect-secrets*/py_env-*/bin/detect-secrets' 2>/dev/null | head -1); \
	fi; \
	if [ -z "$$DS" ]; then DS=detect-secrets; fi; \
	rm -f .secrets.baseline; \
	$$DS scan > .secrets.baseline
	@printf "$(GREEN)✓ .secrets.baseline regenerated$(RESET)\n"

clean: ## Remove stale shell caches (zcompdump, etc.)
	@rm -f ~/.zcompdump* 2>/dev/null || true
	@printf "$(GREEN)✓ Caches cleaned$(RESET)\n"

whoami: ## Show chezmoi OS/arch (this tree is macOS)
	@chezmoi execute-template '{{ .chezmoi.os }}/{{ .chezmoi.arch }}'; echo

apps: ## Install GUI apps from Brewfile.apps (Rectangle, Slack, Spotify, etc.)
	@printf "$(YELLOW)→ Running brew bundle (apps)...$(RESET)\n"
	brew bundle --file=$(REPO)/Brewfile.apps

cli: ## Install daily CLI toolkit from Brewfile.cli
	@printf "$(YELLOW)→ Running brew bundle (cli)...$(RESET)\n"
	brew bundle --file=$(REPO)/Brewfile.cli

##@ Editor extensions

# Teaching note: VS Code Settings Sync only reaches other VS Code installs —
# Microsoft restricts it to official builds, so Cursor can never join. The
# Extfile set is the source of truth for both editors instead, following the
# same shape as the Brewfile split: a shared baseline plus per-editor extras.

ext: ## Install editor extensions into VS Code + Cursor from the Extfile set
	@$(REPO)/scripts/ext.sh install

ext-diff: ## Show extension drift between the Extfile set and both editors
	@$(REPO)/scripts/ext.sh diff

ext-dump: ## Append extensions installed by hand into the Extfile set
	@$(REPO)/scripts/ext.sh dump

# Teaching note: dry-run by default, like `brew bundle cleanup`. $(if …) expands
# to 1 only when FORCE is non-empty, so `make ext-prune` previews and
# `make ext-prune FORCE=1` actually uninstalls.
ext-prune: ## Uninstall extensions missing from the Extfile set (dry-run; FORCE=1 applies)
	@EXT_PRUNE_FORCE=$(if $(FORCE),1,0) $(REPO)/scripts/ext.sh prune

##@ Bootstrap sub-steps (rarely needed individually)

# Each of these is also a prerequisite of `make bootstrap`. Run them
# individually only when re-running a specific step (e.g. after adding
# a package to Brewfile, run `make brew-bundle` to install just the new one).

xcode-clt: ## Verify/install Xcode Command Line Tools (rare — only on fresh Mac)
	@if xcode-select -p &>/dev/null; then \
		printf "$(GREEN)✓ Xcode CLT already installed$(RESET)\n"; \
	else \
		printf "$(YELLOW)→ Installing Xcode CLT...$(RESET)\n"; \
		xcode-select --install; \
		echo "Re-run 'make bootstrap' after the CLT installer finishes."; \
		exit 1; \
	fi

brew: xcode-clt ## Install Homebrew (rare — only on fresh Mac)
	@if command -v brew &>/dev/null; then \
		printf "$(GREEN)✓ Homebrew already installed$(RESET)\n"; \
	else \
		printf "$(YELLOW)→ Installing Homebrew...$(RESET)\n"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

brew-bundle: brew ## Install Brewfile packages (after adding a new brew/cask)
	@printf "$(YELLOW)→ Running brew bundle...$(RESET)\n"
	brew bundle --file=$(REPO)/Brewfile

chezmoi-init: brew-bundle ## Initial chezmoi setup (one-time; use `reinit` after first run)
	@if [[ -f "$(HOME)/.config/chezmoi/chezmoi.toml" ]]; then \
		printf "$(GREEN)✓ chezmoi already initialized$(RESET)\n"; \
	else \
		printf "$(YELLOW)→ Initializing chezmoi...$(RESET)\n"; \
		chezmoi init --source="$(SOURCE)"; \
	fi

fzf-install: ## No-op: fzf bindings are chezmoi-managed (~/.config/fzf/fzf.zsh)
	@printf "$(GREEN)✓ fzf is applied from home/dot_config/fzf/fzf.zsh$(RESET)\n"
	@if [[ -f "$(HOME)/.fzf.zsh" ]]; then \
		printf "$(YELLOW)→ leftover ~/.fzf.zsh from old fzf/install — not sourced; delete if unused$(RESET)\n"; \
	fi

tpm-install: ## Install tmux plugin manager (rare — only on fresh Mac)
	@if [[ -d "$(HOME)/.tmux/plugins/tpm" ]]; then \
		printf "$(GREEN)✓ tmux TPM already installed$(RESET)\n"; \
	else \
		printf "$(YELLOW)→ Installing tmux TPM...$(RESET)\n"; \
		git clone https://github.com/tmux-plugins/tpm "$(HOME)/.tmux/plugins/tpm"; \
	fi

hooks-install: apply ## Install pre-commit git hooks (rare — only on fresh Mac)
	@printf "$(YELLOW)→ Installing pre-commit hooks...$(RESET)\n"
	@pre-commit install
	@printf "$(GREEN)✓ pre-commit hooks installed$(RESET)\n"

# Teaching note: the awk one-liner below parses ##@ section headers and
# `target: ## description` lines from this file — no manual help list to
# maintain. Add a `## description` to any new target to make it appear.

help: ## Display grouped help (default target)
	@awk 'BEGIN { \
		FS = ":.*##"; \
		printf "\nUsage:\n  make $(CYAN)<target>$(RESET)\n"; \
	} \
	/^##@/ { \
		printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5); \
	} \
	/^[a-zA-Z_-]+:.*?##/ { \
		printf "  $(CYAN)%-16s$(RESET) %s\n", $$1, $$2; \
	}' $(MAKEFILE_LIST)
