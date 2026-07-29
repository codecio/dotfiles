#!/usr/bin/env zsh
# ============================================================
# Editor extension sync — VS Code + Cursor
# ============================================================
# VS Code Settings Sync only reaches other VS Code installs; Microsoft
# restricts the sync service (and its marketplace) to official builds, so
# Cursor can never join it. The Extfile set is the source of truth instead.
#
#   Extfile          installed into both editors
#   Extfile.vscode   VS Code only (Microsoft-proprietary)
#   Extfile.cursor   Cursor only (Anysphere OpenVSX forks)
#   Extfile.ignore   never installed — unreproducible leftovers, silenced in diff
#
# Usage: ext.sh <install|diff|dump|prune>   (invoked via the make ext* targets)
# ============================================================

set -euo pipefail

# ${0:A:h:h} — :A resolves to an absolute path, each :h strips one path
# component, so this lands on the repo root regardless of the caller's cwd.
REPO="${0:A:h:h}"
SHARED="$REPO/Extfile"
IGNORE="$REPO/Extfile.ignore"

EDITORS=(vscode cursor)
typeset -A CLI=(vscode code       cursor cursor)
typeset -A LABEL=(vscode "VS Code" cursor "Cursor")
typeset -A FILE=(vscode "$REPO/Extfile.vscode" cursor "$REPO/Extfile.cursor")

CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'

# Extension IDs are case-insensitive; the CLIs report them inconsistently,
# so everything is lowercased before any comparison.
# The trailing `|| true` keeps a comment-only file from tripping pipefail when
# grep matches nothing.
read_list() {
  [[ -f "$1" ]] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$' | tr 'A-Z' 'a-z' | sort -u || true
}

installed() { "${CLI[$1]}" --list-extensions 2>/dev/null | tr 'A-Z' 'a-z' | sort -u; }
wanted()    { cat <(read_list "$SHARED") <(read_list "${FILE[$1]}") | sort -u; }
have_cli()  { command -v "${CLI[$1]}" >/dev/null 2>&1; }

# Installed but unmanaged. Ignored entries are subtracted so extensions that no
# longer exist in either registry don't show up as drift on every run.
unmanaged() { comm -13 <(wanted "$1") <(installed "$1") | comm -23 - <(read_list "$IGNORE"); }

# Route a newly-found extension to the file it belongs in. Anysphere forks and
# the Microsoft remote stack are locked to one editor; everything else is
# assumed portable, and `make ext` surfaces it if the assumption is wrong.
classify() {
  case "$1" in
    anysphere.*)                          print "cursor" ;;
    ms-vscode-remote.*|ms-vscode.remote-*) print "vscode" ;;
    *)                                    print "shared" ;;
  esac
}

cmd_install() {
  local failed=() missing ext ed
  for ed in $EDITORS; do
    if ! have_cli "$ed"; then
      printf "%s→ %s CLI not found — skipping%s\n" "$YELLOW" "${LABEL[$ed]}" "$RESET"
      continue
    fi
    missing=$(comm -23 <(wanted "$ed") <(installed "$ed"))
    if [[ -z "$missing" ]]; then
      printf "%s✓ %s already up to date%s\n" "$GREEN" "${LABEL[$ed]}" "$RESET"
      continue
    fi
    printf "%s→ %s: installing %d extension(s)%s\n" \
      "$YELLOW" "${LABEL[$ed]}" "$(print -r -- "$missing" | wc -l | tr -d ' ')" "$RESET"
    for ext in ${(f)missing}; do
      if "${CLI[$ed]}" --install-extension "$ext" --force >/dev/null 2>&1; then
        printf "  %s✓%s %s\n" "$GREEN" "$RESET" "$ext"
      else
        printf "  %s✗%s %s\n" "$RED" "$RESET" "$ext"
        failed+=("${LABEL[$ed]}: $ext")
      fi
    done
  done

  if (( ${#failed} )); then
    printf "\n%sFailed installs:%s\n" "$RED" "$RESET"
    printf "  %s\n" $failed
    printf "\nAn extension missing from one registry is expected — move it out of\n"
    printf "%sExtfile%s into %sExtfile.vscode%s or %sExtfile.cursor%s and re-run.\n" \
      "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
    return 1
  fi
  printf "\n%s✓ Extensions in sync.%s\n" "$GREEN" "$RESET"
}

cmd_diff() {
  local drift=0 missing untracked ed
  for ed in $EDITORS; do
    printf "\n%s%s%s\n" "$CYAN" "${LABEL[$ed]}" "$RESET"
    if ! have_cli "$ed"; then
      printf "  %sCLI not found — skipping%s\n" "$YELLOW" "$RESET"
      continue
    fi
    missing=$(comm -23 <(wanted "$ed") <(installed "$ed"))
    untracked=$(unmanaged "$ed")
    if [[ -n "$missing" ]]; then
      printf "  %stracked but not installed (run 'make ext'):%s\n" "$YELLOW" "$RESET"
      printf "    %s\n" ${(f)missing}
      drift=1
    fi
    if [[ -n "$untracked" ]]; then
      printf "  %sinstalled but not tracked (run 'make ext-dump'):%s\n" "$YELLOW" "$RESET"
      printf "    %s\n" ${(f)untracked}
      drift=1
    fi
    [[ -n "$missing$untracked" ]] || printf "  %s✓ no drift%s\n" "$GREEN" "$RESET"
  done
  (( drift == 0 )) || printf "\n%sDrift detected.%s\n" "$YELLOW" "$RESET"
}

cmd_dump() {
  local -A add
  local -a batch
  local ext ed target stamp
  for ed in $EDITORS; do
    have_cli "$ed" || continue
    for ext in ${(f)"$(unmanaged "$ed")"}; do
      [[ -n "$ext" ]] && add[$ext]=$(classify "$ext")
    done
  done

  if (( ${#add} == 0 )); then
    printf "%s✓ Nothing new — all installed extensions are tracked.%s\n" "$GREEN" "$RESET"
    return 0
  fi

  stamp="# --- Added by 'make ext-dump' on $(date +%Y-%m-%d) ---"
  # Not named `path` — zsh ties that to $PATH and rejects the type change.
  typeset -A dest=(shared "$SHARED" vscode "${FILE[vscode]}" cursor "${FILE[cursor]}")
  for target in shared vscode cursor; do
    batch=()
    for ext in ${(ko)add}; do
      [[ ${add[$ext]} == "$target" ]] && batch+=("$ext")
    done
    (( ${#batch} )) || continue
    { print ""; print -r -- "$stamp"; printf "%s\n" $batch } >> "${dest[$target]}"
    printf "%s→ %s: added %d%s\n" "$YELLOW" "${dest[$target]:t}" "${#batch}" "$RESET"
    printf "  %s\n" $batch
  done

  printf "\n%s✓ Added. Review the descriptions, then run 'make ext' to backfill.%s\n" \
    "$GREEN" "$RESET"
}

# The inverse of dump: both act on the same "installed but unmanaged" set, one
# by adopting it into the files, the other by removing it from the editors.
# Follows `brew bundle cleanup` in refusing to delete anything until forced, so
# a bare run is always a preview. Extfile.ignore entries are never candidates.
cmd_prune() {
  local -a doomed
  local ext ed out total=0
  local force=${EXT_PRUNE_FORCE:-0}

  for ed in $EDITORS; do
    have_cli "$ed" || continue
    out=$(unmanaged "$ed")
    [[ -n "$out" ]] || continue
    doomed=(${(f)out})
    total=$(( total + ${#doomed} ))
    printf "\n%s%s%s\n" "$CYAN" "${LABEL[$ed]}" "$RESET"
    for ext in $doomed; do
      if (( force )); then
        if "${CLI[$ed]}" --uninstall-extension "$ext" >/dev/null 2>&1; then
          printf "  %s✓ removed%s  %s\n" "$GREEN" "$RESET" "$ext"
        else
          printf "  %s✗ failed%s   %s\n" "$RED" "$RESET" "$ext"
        fi
      else
        printf "  %swould remove%s %s\n" "$YELLOW" "$RESET" "$ext"
      fi
    done
  done

  if (( total == 0 )); then
    printf "%s✓ Nothing to prune — both editors match the Extfile set.%s\n" "$GREEN" "$RESET"
    return 0
  fi

  if (( force )); then
    printf "\n%s✓ Pruned %d extension(s).%s\n" "$GREEN" "$total" "$RESET"
  else
    printf "\n%sDry run — nothing was removed.%s\n" "$YELLOW" "$RESET"
    printf "Apply with %smake ext-prune FORCE=1%s.\n" "$CYAN" "$RESET"
    printf "To keep any of these instead, run %smake ext-dump%s to adopt them.\n" \
      "$CYAN" "$RESET"
  fi
}

case "${1:-}" in
  install) cmd_install ;;
  diff)    cmd_diff ;;
  dump)    cmd_dump ;;
  prune)   cmd_prune ;;
  *) print -u2 "usage: ${0:t} <install|diff|dump|prune>"; exit 2 ;;
esac
