#!/usr/bin/env zsh

set -uo pipefail

ZSHRC="${0:A:h:h}/home/dot_zshrc"
T=${$(mktemp -d):A}
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/home" "$T/bin"
print -l '#!/bin/sh' 'printf "%s\n" "$*" >> "$SUDO_LOG"' > "$T/bin/sudo"
chmod +x "$T/bin/sudo"

pass=0 fail=0
ok()  { print "  ok   $1"; (( pass++ )); }
bad() { print "  FAIL $1"; (( fail++ )); }
check() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi }
lacks() { ! grep -qF -- "$2" "$1"; }

run() {
  rm -f "$T/sudo.log"
  HOME="$T/home" SUDO_LOG="$T/sudo.log" PATH="$T/bin:/usr/bin:/bin" \
    zsh -f -c "source ${(q)ZSHRC} >/dev/null 2>&1; $1" > "$T/out" 2>&1
}

run_login() {
  rm -f "$T/sudo.log"
  # path_helper in /etc/zprofile moves $T/bin behind /usr/bin, so stub sudo as a function
  print -r -- "sudo() { print -r -- \"\$*\" >> \"\$SUDO_LOG\" }; source ${(q)ZSHRC}" > "$T/home/.zshrc"
  HOME="$T/home" SUDO_LOG="$T/sudo.log" PATH="$T/bin:/usr/bin:/bin" \
    zsh -l -i -c "$1" > "$T/out" 2>/dev/null
}

print "logout"
run 'logout'
check "no argument never calls sudo" test ! -e "$T/sudo.log"
run_login 'print started; logout; print still-running'
check "a login shell runs commands before logout" grep -qx started "$T/out"
check "no argument ends a login shell" lacks "$T/out" still-running
check "no argument in a login shell never calls sudo" test ! -e "$T/sudo.log"
run 'logout nosuchuser-zshrc-test'
check "unknown user never calls sudo" test ! -e "$T/sudo.log"
run "logout ${(q)USER}"
check "known user boots out that user's session" grep -qx "launchctl bootout user/$(id -u)" "$T/sudo.log"

print "\n$pass passed, $fail failed"
(( fail == 0 ))
