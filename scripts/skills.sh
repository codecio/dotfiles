#!/usr/bin/env zsh
# ============================================================
# Skill sync — personal Cursor skills and rules vs their upstreams
# ============================================================
# Skillfile is the source of truth for every skill and rule a repo manages:
# where each one came from and how local edits relate to it.
#
#   upstream <alias> <git-url|dir>   git URLs are fetched; a bare dir is copied as-is
#   deploy chezmoi|symlink           chezmoi: copies live in home/dot_cursor/
#                                    symlink: copies live at the repo root and
#                                             `install` links them into ~/.cursor
#   merge <dest> <alias>:<path>      light local edits; pull 3-way merges upstream in
#   track <dest> <alias>:<path>...   fork or rewrite; pull only refreshes vendor/
#   local <dest>                     no upstream
#   watch <name> <alias>:<path>...   nothing deployed; report upstream changes
#
# Usage: skills.sh [-f Skillfile]... <status|adopt NAME [REF]|pull [NAME...]|diff NAME|install>
# With no -f, reads Skillfile and Skillfile.local (if present) from the repo root.
# ============================================================

set -euo pipefail
setopt extended_glob

REPO="${0:A:h:h}"
CACHE="${SKILLS_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/skills}"
CURSOR="$HOME/.cursor"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  CYAN= GREEN= YELLOW= RED= RESET=
else
  CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
fi

die()  { print -u2 -r -- "${RED}error:${RESET} $*"; exit 2; }
warn() { print -u2 -r -- "${YELLOW}warning:${RESET} $*"; }
say()  { printf "  %-8s %s\n" "$1" "$2"; }
tilde() { print -r -- "${1/#$HOME/~}"; }

typeset -a E_NAME E_MODE E_DEST E_SRCS E_ROOT E_DEPLOY E_FILE
typeset -A UPSTREAM BY_NAME FETCHED
typeset -a SNAP_REFS
WANT_REF=

load() {
  local file=${1:A} root=${1:A:h} deploy= line mode dest name s n key base
  local -a words srcs
  local -A bases
  [[ -f $file ]] || die "no Skillfile at $1"
  while IFS= read -r line || [[ -n $line ]]; do
    words=(${=${line%%\#*}})
    (( ${#words} )) || continue
    case ${words[1]} in
      upstream)
        (( ${#words} == 3 )) || die "$file: upstream needs <alias> <git-url|dir>"
        key="$root|${words[2]}"
        UPSTREAM[$key]=${words[3]/#\~/$HOME} ;;
      deploy)
        [[ ${words[2]:-} == (chezmoi|symlink) ]] || die "$file: deploy must be chezmoi or symlink"
        deploy=${words[2]} ;;
      merge|track|local|watch)
        mode=${words[1]} dest=${words[2]:-} srcs=(${words[3,-1]})
        if [[ $mode == watch ]]; then
          [[ $dest == [a-z0-9-]## ]] || die "$file: watch needs a name, got '$dest'"
          name=$dest
        else
          [[ -n $deploy ]] || die "$file: deploy must come before entries"
          [[ $dest == skills/[a-z0-9-]## || $dest == rules/[a-z0-9-]##.mdc ]] \
            || die "$file: destination must be skills/<name> or rules/<name>.mdc, got '$dest'"
          name=${${dest:t}%.mdc}
        fi
        case $mode in
          merge)       (( ${#srcs} == 1 )) || die "$file: merge $dest takes exactly one source" ;;
          track|watch) (( ${#srcs} >= 1 )) || die "$file: $mode $dest needs a source" ;;
          local)       (( ${#srcs} == 0 )) || die "$file: local $dest takes no source" ;;
        esac
        (( ${+BY_NAME[$name]} )) && die "$name is declared in both ${E_FILE[${BY_NAME[$name]}]} and $file"
        bases=()
        for s in $srcs; do
          [[ $s == ?##:?## ]] || die "$file: source '$s' is not <alias>:<path>"
          key="$root|${s%%:*}"
          (( ${+UPSTREAM[$key]} )) || die "$file: unknown upstream '${s%%:*}' (declare it before use)"
          base=${${s#*:}:t}
          (( ${+bases[$base]} )) && die "$file: $name has two sources named '$base'; vendor/$name/ keeps one file per name"
          bases[$base]=1
        done
        n=$(( ${#E_NAME} + 1 ))
        E_NAME[n]=$name; E_MODE[n]=$mode; E_DEST[n]=$dest; E_SRCS[n]="${srcs[*]}"
        E_ROOT[n]=$root; E_DEPLOY[n]=$deploy; E_FILE[n]=$file
        BY_NAME[$name]=$n ;;
      *) die "$file: unknown directive '${words[1]}'" ;;
    esac
  done < $file
}

slot() { (( ${+BY_NAME[${1:-}]} )) || die "no Skillfile entry named '${1:-}'"; REPLY=${BY_NAME[$1]}; }

local_path() {
  if [[ ${E_DEPLOY[$1]} == chezmoi ]]; then REPLY="${E_ROOT[$1]}/home/dot_cursor/${E_DEST[$1]}"
  else REPLY="${E_ROOT[$1]}/${E_DEST[$1]}"; fi
}
vendor_dir() { REPLY="${E_ROOT[$1]}/vendor/${E_NAME[$1]}"; }

is_git() { [[ $1 == (https|http|ssh|git|file)://* || $1 == [^/]##@[^/]##:* ]]; }
same_tree() { diff -rq "$1" "$2" >/dev/null 2>&1; }

git_cache() {
  local url=$1 dir="$CACHE/${1//[^A-Za-z0-9._-]/_}"
  if [[ ! -d $dir ]]; then
    mkdir -p "$CACHE"
    git clone --quiet --no-checkout -- "$url" "$dir" 2>/dev/null || return 4
  elif (( ! ${+FETCHED[$dir]} )); then
    git -C "$dir" fetch --quiet origin 2>/dev/null || warn "could not fetch $url; comparing against the cached copy"
  fi
  FETCHED[$dir]=1
  REPLY=$dir
}

snapshot() {
  local i=$1 out=$2 s alias rel src ref dir x key
  SNAP_REFS=()
  rm -rf "$out" && mkdir -p "$out"
  for s in ${=E_SRCS[i]}; do
    alias=${s%%:*} rel=${s#*:}
    key="${E_ROOT[i]}|$alias"; src=${UPSTREAM[$key]}
    if is_git "$src"; then
      git_cache "$src" || return 4
      dir=$REPLY
      ref=$(git -C "$dir" rev-parse --verify --quiet "${WANT_REF:-origin/HEAD}^{commit}") || return 3
      git -C "$dir" cat-file -e "$ref:$rel" 2>/dev/null || return 3
      x=$(mktemp -d "$TMP/x.XXXX")
      git -C "$dir" archive --format=tar "$ref" -- "$rel" | tar -x -C "$x"
      mv "$x/$rel" "$out/${rel:t}"
    else
      [[ -d $src ]] || return 4
      [[ -e $src/$rel ]] || return 3
      cp -Rp "$src/$rel" "$out/${rel:t}"
      ref="copied $(date -u +%Y-%m-%dT%H:%MZ)"
    fi
    SNAP_REFS+=("$s"$'\t'"$ref")
  done
  find "$out" \( -name .DS_Store -o -name .p4ignore.txt \) -delete
  return 0
}

write_lock() {
  local lock="${E_ROOT[$1]}/Skillfile.lock" name=${E_NAME[$1]} r
  local -a rows
  [[ -f $lock ]] && rows=(${(f)"$(awk -F'\t' -v n="$name" '$1 != n && !/^#/' "$lock")"})
  for r in $SNAP_REFS; do rows+=("$name"$'\t'"$r"); done
  { print "# Generated by scripts/skills.sh: upstream revision behind each vendor/ copy."
    print -rl -- ${(o)rows}; } > "$lock"
}

replace_vendor() {
  vendor_dir $1
  mkdir -p "${REPLY:h}"
  # vendor/ moves last: pull and status compare it to upstream to decide what is done.
  write_lock $1
  rm -rf "$REPLY.new" && mv "$2" "$REPLY.new" && rm -rf "$REPLY" && mv "$REPLY.new" "$REPLY"
}

has_conflict() { [[ -e $1 ]] && grep -rqs '^<<<<<<< local' "$1"; }

merge_file() {
  local ours=$1 base=$2 theirs=$3 rel=$4 hb=0 ho=0 ht=0 empty
  [[ -f $base ]] && hb=1
  [[ -f $ours ]] && ho=1
  [[ -f $theirs ]] && ht=1
  case $hb$ho$ht in
    001) mkdir -p "${ours:h}" && cp -p "$theirs" "$ours" && say added "$rel" ;;
    011) if ! cmp -s "$ours" "$theirs"; then
           empty=$(mktemp "$TMP/e.XXXX")
           git merge-file -L local -L base -L upstream "$ours" "$empty" "$theirs" || { say CONFLICT "$rel"; return 1; }
           say merged "$rel"
         fi ;;
    101) cmp -s "$base" "$theirs" || say kept "$rel (you deleted it; upstream changed it)" ;;
    110) if cmp -s "$ours" "$base"; then rm "$ours" && say removed "$rel"
         else say kept "$rel (upstream deleted it; you edited it)"; fi ;;
    111) if cmp -s "$base" "$theirs"; then :
         elif cmp -s "$ours" "$base"; then cp -p "$theirs" "$ours" && say updated "$rel"
         elif git merge-file -L local -L base -L upstream "$ours" "$base" "$theirs"; then say merged "$rel"
         else say CONFLICT "$rel"; return 1; fi ;;
  esac
  return 0
}

merge_entry() {
  local i=$1 snap=$2 b ours base theirs rel conflicts=0
  local -a rels
  b=${${E_SRCS[i]#*:}:t}
  local_path $i; ours=$REPLY
  vendor_dir $i; base="$REPLY/$b"
  theirs="$snap/$b"
  if [[ ! -e $ours ]]; then
    mkdir -p "${ours:h}" && cp -Rp "$theirs" "$ours" && say added "${E_DEST[i]}"
    return 0
  fi
  if [[ -d $theirs || -d $base ]]; then
    rels=(${(u)${(f)"$(for d in "$base" "$ours" "$theirs"; do [[ -d $d ]] && (cd "$d" && find . -type f); done | sed 's|^\./||' | sort)"}})
    for rel in $rels; do
      merge_file "$ours/$rel" "$base/$rel" "$theirs/$rel" "$rel" || conflicts=$(( conflicts + 1 ))
    done
  else
    merge_file "$ours" "$base" "$theirs" "${E_DEST[i]:t}" || conflicts=$(( conflicts + 1 ))
  fi
  (( conflicts == 0 ))
}

local_state() {
  local i=$1 p b
  local_path $i; p=$REPLY
  case ${E_MODE[i]} in
    watch) REPLY=- ;;
    local) [[ -e $p ]] && REPLY=present || REPLY=absent ;;
    track) [[ -e $p ]] && REPLY=derived || REPLY=absent ;;
    merge)
      vendor_dir $i; b="$REPLY/${${E_SRCS[i]#*:}:t}"
      if [[ ! -e $p ]]; then REPLY=absent
      elif has_conflict "$p"; then REPLY=conflict
      elif [[ ! -e $b ]]; then REPLY=-
      elif same_tree "$b" "$p"; then REPLY=clean
      else REPLY=modified; fi ;;
  esac
}

upstream_state() {
  local i=$1 rc
  [[ ${E_MODE[i]} == local ]] && { REPLY=n/a; return 0; }
  snapshot $i "$TMP/status/$i" && rc=0 || rc=$?
  vendor_dir $i
  case $rc in
    0) if [[ ! -d $REPLY ]]; then REPLY=unadopted
       elif same_tree "$REPLY" "$TMP/status/$i"; then REPLY=current
       else REPLY=changed; fi ;;
    3) REPLY=missing ;;
    *) REPLY=unreachable ;;
  esac
}

deploy_note() {
  local i=$1 dest="$CURSOR/${E_DEST[$1]}"
  REPLY=
  [[ ${E_DEPLOY[i]} == symlink && ${E_MODE[i]} != watch ]] || return 0
  local_path $i
  if [[ -L $dest ]]; then [[ $(readlink "$dest") == $REPLY ]] && REPLY= || REPLY="links elsewhere; run install"
  elif [[ -e $dest ]]; then REPLY="plain copy in ~/.cursor; run install"
  else REPLY="not installed; run install"; fi
}

cmd_status() {
  local i f=  ls us note drift=0
  for (( i = 1; i <= ${#E_NAME}; i++ )); do
    if [[ ${E_FILE[i]} != $f ]]; then
      f=${E_FILE[i]}
      printf "\n%s%s%s (%s)\n" "$CYAN" "$(tilde "$f")" "$RESET" "${E_DEPLOY[i]:-watch only}"
      printf "%-28s %-6s %-9s %-11s %s\n" NAME MODE LOCAL UPSTREAM NOTE
    fi
    local_state $i; ls=$REPLY
    upstream_state $i; us=$REPLY
    deploy_note $i; note=$REPLY
    case $us/$ls in
      */conflict)      note="resolve <<<<<<< markers, then re-check" ;;
      changed/*)       [[ ${E_MODE[i]} == merge ]] && note="pull ${E_NAME[i]}" || note="diff ${E_NAME[i]}, re-port, then pull ${E_NAME[i]}" ;;
      unadopted/*)     note="adopt ${E_NAME[i]} [REF]" ;;
      missing/*)       note="upstream path is gone; repoint or switch to local" ;;
    esac
    [[ -n $note ]] && drift=1
    printf "%-28s %-6s %-9s %-11s %s\n" "${E_NAME[i]}" "${E_MODE[i]}" "$ls" "$us" "$note"
  done
  inventory
  (( drift )) && printf "\n%sAction needed on the entries with a NOTE.%s\n" "$YELLOW" "$RESET"
  return 0
}

inventory() {
  local i p n d pname ver
  local -A claimed provider
  local -a loose personal builtins
  for (( i = 1; i <= ${#E_NAME}; i++ )); do
    [[ ${E_MODE[i]} == watch ]] && continue
    claimed[$CURSOR/${E_DEST[i]}]=1
    [[ ${E_DEST[i]} == skills/* ]] && personal+=(${E_NAME[i]})
  done
  for p in $CURSOR/skills/*(N) $CURSOR/rules/*.mdc(N); do
    (( ${+claimed[$p]} )) && continue
    loose+=($p)
    [[ $p == $CURSOR/skills/* ]] && personal+=(${p:t})
  done
  loose+=($HOME/.agents/skills/*(N) $HOME/.claude/skills/*(N) $HOME/.codex/skills/*(N))

  printf "\n%sUnmanaged%s (loaded by Cursor, in no Skillfile)\n" "$CYAN" "$RESET"
  (( ${#loose} )) || print "  none"
  for p in $loose; do
    if [[ -L $p ]]; then printf "  unmanaged  %s -> %s\n" "$(tilde "$p")" "$(tilde "$(readlink "$p")")"
    else printf "  unmanaged  %s\n" "$(tilde "$p")"; fi
  done

  printf "\n%sPlugins%s (cached by Cursor; enable, disable, and update in Customize > Plugins)\n" "$CYAN" "$RESET"
  for d in $CURSOR/plugins/cache/*/*/*(N/); do
    pname=${d:h:t} ver=
    for p in ${d}/(.cursor-plugin|.claude-plugin)/plugin.json(N) ${d}/(plugin|package).json(N); do
      ver=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$p" | head -1)
      [[ -n $ver ]] && break
    done
    printf "  %-20s %s\n" "$pname" "${ver:-?}"
    for p in $d/skills/*/SKILL.md(N); do provider[${p:h:t}]="plugin $pname"; done
  done
  builtins=($CURSOR/skills-cursor/*/SKILL.md(N))
  for p in $builtins; do provider[${p:h:t}]="Cursor built-in"; done
  printf "  %d Cursor built-in skills in %s\n" "${#builtins}" "$(tilde "$CURSOR/skills-cursor")"

  local -a clashes
  for n in ${(u)personal}; do (( ${+provider[$n]} )) && clashes+=("$n also provided by ${provider[$n]}"); done
  if (( ${#clashes} )); then
    printf "\n%sName clashes%s (the same /name resolves to two skills)\n" "$YELLOW" "$RESET"
    printf "  %s\n" $clashes
  fi
  return 0
}

cmd_adopt() {
  local i rc p
  slot "${1:-}"; i=$REPLY
  [[ ${E_MODE[i]} != local ]] || die "${E_NAME[i]} is local; it has no upstream"
  WANT_REF=${2:-}
  snapshot $i "$TMP/adopt" && rc=0 || rc=$?
  WANT_REF=
  (( rc != 3 )) || die "${E_NAME[i]}: upstream path or ref not found"
  (( rc == 0 )) || die "${E_NAME[i]}: upstream unreachable"
  replace_vendor $i "$TMP/adopt"
  printf "%s✓ %s: vendor/ set to %s%s\n" "$GREEN" "${E_NAME[i]}" "${${SNAP_REFS[1]}#*$'\t'}" "$RESET"
  local_path $i; p=$REPLY
  if [[ ${E_MODE[i]} == merge && ! -e $p ]]; then
    vendor_dir $i
    mkdir -p "${p:h}" && cp -Rp "$REPLY/${${E_SRCS[i]#*:}:t}" "$p"
    say added "$(tilde "$p")"
  fi
  return 0
}

cmd_pull() {
  local i rc n failed=0
  local -a slots
  if (( $# )); then for n in "$@"; do slot "$n"; slots+=($REPLY); done
  else for (( i = 1; i <= ${#E_NAME}; i++ )); do slots+=($i); done; fi

  for i in $slots; do
    n=${E_NAME[i]}
    [[ ${E_MODE[i]} == local ]] && continue
    vendor_dir $i
    if [[ ! -d $REPLY ]]; then warn "$n: not adopted yet; run adopt $n [REF]"; continue; fi
    local_path $i
    if [[ ${E_MODE[i]} == merge ]] && has_conflict "$REPLY"; then
      printf "%s→ %s%s\n" "$YELLOW" "$n" "$RESET"
      say CONFLICT "$(tilde "$REPLY") still has <<<<<<< markers from the last pull; resolve them first"
      failed=1; continue
    fi
    snapshot $i "$TMP/pull/$i" && rc=0 || rc=$?
    case $rc in
      3) warn "$n: upstream path is gone; left as is"; continue ;;
      4) warn "$n: upstream unreachable; left as is"; continue ;;
    esac
    vendor_dir $i
    if same_tree "$REPLY" "$TMP/pull/$i"; then printf "%s✓ %s current%s\n" "$GREEN" "$n" "$RESET"; continue; fi

    printf "%s→ %s%s\n" "$YELLOW" "$n" "$RESET"
    if [[ ${E_MODE[i]} == merge ]]; then
      merge_entry $i "$TMP/pull/$i" || failed=1
    else
      say review "git -C $(tilde "${E_ROOT[i]}") diff -- vendor/$n   (then re-port by hand)"
    fi
    replace_vendor $i "$TMP/pull/$i"
  done
  (( failed == 0 )) || { printf "\n%sConflicts left <<<<<<< markers. Resolve them, then review with git diff.%s\n" "$RED" "$RESET"; return 1; }
  return 0
}

cmd_diff() {
  local i rc b
  slot "${1:-}"; i=$REPLY
  [[ ${E_MODE[i]} != local ]] || die "${E_NAME[i]} is local; it has no upstream"
  vendor_dir $i
  if [[ ${E_MODE[i]} == merge ]]; then
    b="$REPLY/${${E_SRCS[i]#*:}:t}"; local_path $i
    printf "%s== your edits vs the upstream base ==%s\n" "$CYAN" "$RESET"
    diff -ru "$b" "$REPLY" || true
  fi
  snapshot $i "$TMP/diff" && rc=0 || rc=$?
  (( rc == 0 )) || die "${E_NAME[i]}: upstream missing or unreachable"
  vendor_dir $i
  printf "%s== upstream changes not yet pulled ==%s\n" "$CYAN" "$RESET"
  if same_tree "$REPLY" "$TMP/diff"; then print "  none"; else diff -ru "$REPLY" "$TMP/diff" || true; fi
}

cmd_install() {
  local i dest target failed=0
  for (( i = 1; i <= ${#E_NAME}; i++ )); do
    [[ ${E_DEPLOY[i]} == symlink && ${E_MODE[i]} != watch ]] || continue
    local_path $i; target=$REPLY
    dest="$CURSOR/${E_DEST[i]}"
    if [[ ! -e $target ]]; then warn "${E_NAME[i]}: $(tilde "$target") is missing"; failed=1; continue; fi
    if [[ -L $dest ]]; then
      [[ $(readlink "$dest") == $target ]] && continue
      ln -sfn "$target" "$dest" && say relinked "$(tilde "$dest")"
    elif [[ -e $dest ]]; then
      if same_tree "$dest" "$target"; then
        rm -rf -- "$dest" && ln -s "$target" "$dest" && say linked "$(tilde "$dest") (replaced identical copy)"
      else
        printf "  %s✗%s %s differs from %s; merge it into the repo or move it aside\n" \
          "$RED" "$RESET" "$(tilde "$dest")" "$(tilde "$target")"
        failed=1
      fi
    else
      mkdir -p "${dest:h}" && ln -s "$target" "$dest" && say linked "$(tilde "$dest")"
    fi
  done
  (( failed == 0 ))
}

typeset -a files
while [[ ${1:-} == -f ]]; do files+=("${2:?-f needs a path}"); shift 2; done
if (( ! ${#files} )); then
  files=("$REPO/Skillfile")
  [[ -e $REPO/Skillfile.local ]] && files+=("$REPO/Skillfile.local")
fi
for f in $files; do load "$f"; done

cmd=${1:-status}
(( $# )) && shift
case $cmd in
  status)  cmd_status ;;
  adopt)   cmd_adopt "$@" ;;
  pull)    cmd_pull "$@" ;;
  diff)    cmd_diff "$@" ;;
  install) cmd_install ;;
  *) print -u2 "usage: ${0:t} [-f Skillfile]... <status|adopt NAME [REF]|pull [NAME...]|diff NAME|install>"; exit 2 ;;
esac
