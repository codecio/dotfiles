#!/usr/bin/env zsh

set -uo pipefail

REPO="${0:A:h:h}"

pass=0 fail=0
ok()  { print "  ok   $1"; (( pass++ )); }
bad() { print "  FAIL $1"; (( fail++ )); }

expect_force() {
  local want=$1 label=$2 out; shift 2
  out=$(env -u FORCE make -s -n -C "$REPO" ext-prune REPO="$REPO" "$@" 2>&1)
  if [[ $out == "EXT_PRUNE_FORCE=$want "* ]]; then ok "$label -> $want"; else bad "$label -> want $want, got: $out"; fi
}

print "ext-prune: only FORCE=1 uninstalls"
expect_force 1 "FORCE=1" FORCE=1
for v in 0 false yes ''; do expect_force 0 "FORCE='$v'" FORCE="$v"; done
expect_force 0 "FORCE unset"

print "\n$pass passed, $fail failed"
(( fail == 0 ))
