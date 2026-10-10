#!/usr/bin/env zsh

set -uo pipefail

SKILLS="${0:A:h}/skills.sh"
T=${$(mktemp -d):A}
trap 'rm -rf "$T"' EXIT

export HOME="$T/home" SKILLS_CACHE="$T/cache" NO_COLOR=1
mkdir -p "$HOME/.cursor/skills" "$HOME/.cursor/rules"

pass=0 fail=0
ok()  { print "  ok   $1"; (( pass++ )); }
bad() { print "  FAIL $1"; (( fail++ )); }
check() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi }
nok()   { local d=$1; shift; if "$@" >/dev/null 2>&1; then bad "$d"; else ok "$d"; fi }
has()   { grep -qF -- "$2" "$1"; }
lacks() { ! grep -qF -- "$2" "$1"; }

g() { git -C "$T/up-git" -c user.name=t -c user.email=t@t "$@" >/dev/null; }
sk() { "$SKILLS" -f "$T/pub/Skillfile" -f "$T/priv/Skillfile" "$@"; }

mkdir -p "$T/up-git/skills/alpha" "$T/up-git/skills/beta"
print -l -- "---" "name: alpha" "---" "line upstream A" "" "" "" "" "line local-target" > "$T/up-git/skills/alpha/SKILL.md"
print "extra v1" > "$T/up-git/skills/alpha/extra.md"
print "beta v1" > "$T/up-git/skills/beta/SKILL.md"
git -C "$T/up-git" init -q -b main && g add -A && g commit -qm c1
C1=$(git -C "$T/up-git" rev-parse HEAD)

mkdir -p "$T/up-dir/rules"
print "r1 v1" > "$T/up-dir/rules/r1.mdc"
print "r2 v1" > "$T/up-dir/rules/r2.mdc"

mkdir -p "$T/pub/home/dot_cursor/skills/alpha" "$T/pub/home/dot_cursor/skills/beta-fork" "$T/pub/home/dot_cursor/rules"
cat > "$T/pub/Skillfile" <<EOF
upstream up file://$T/up-git
deploy chezmoi
merge skills/alpha      up:skills/alpha
track skills/beta-fork  up:skills/beta
merge skills/gone       up:skills/nonexistent
local rules/mine.mdc
EOF
sed 's/line local-target/line local-target MODIFIED LOCALLY/' "$T/up-git/skills/alpha/SKILL.md" > "$T/pub/home/dot_cursor/skills/alpha/SKILL.md"
cp "$T/up-git/skills/alpha/extra.md" "$T/pub/home/dot_cursor/skills/alpha/extra.md"
print "my fork of beta" > "$T/pub/home/dot_cursor/skills/beta-fork/SKILL.md"
print "mine" > "$T/pub/home/dot_cursor/rules/mine.mdc"

mkdir -p "$T/priv/skills/p-skill" "$T/priv/rules"
cat > "$T/priv/Skillfile" <<EOF
upstream co $T/up-dir
deploy symlink
track skills/p-skill     co:rules/r1.mdc co:rules/r2.mdc
track rules/p-rule.mdc   co:rules/r1.mdc
watch co-tree            co:rules
EOF
print "port of r1+r2" > "$T/priv/skills/p-skill/SKILL.md"
print "port of r1" > "$T/priv/rules/p-rule.mdc"

A="$T/pub/home/dot_cursor/skills/alpha"
out="$T/out"

print "adopt"
check "adopt alpha at c1" sk adopt alpha "$C1"
check "vendor holds pristine c1" cmp "$T/pub/vendor/alpha/alpha/SKILL.md" "$T/up-git/skills/alpha/SKILL.md"
check "adopt leaves local mod intact" has "$A/SKILL.md" "MODIFIED LOCALLY"
check "lock records c1" has "$T/pub/Skillfile.lock" "$C1"
check "adopt beta-fork" sk adopt beta-fork
check "adopt p-skill" sk adopt p-skill
check "adopt p-rule" sk adopt p-rule
check "adopt co-tree" sk adopt co-tree
nok "adopt of missing upstream path fails" sk adopt gone

print "status before upstream moves"
sk status > "$out" 2>&1
check "alpha upstream current, local modified" grep -Eq '^alpha +merge +modified +current' "$out"
check "gone reported missing" grep -Eq '^gone +merge .* missing' "$out"
check "mine reported local" grep -Eq '^mine +local ' "$out"

print "upstream moves (non-overlapping)"
sed -i '' 's/line upstream A/line upstream A CHANGED UPSTREAM/' "$T/up-git/skills/alpha/SKILL.md"
print "new file" > "$T/up-git/skills/alpha/new.md"
print "beta v2" > "$T/up-git/skills/beta/SKILL.md"
g add -A && g commit -qm c2
C2=$(git -C "$T/up-git" rev-parse HEAD)
sk status > "$out" 2>&1
check "alpha upstream changed" grep -Eq '^alpha +merge +modified +changed' "$out"
check "beta-fork upstream changed" grep -Eq '^beta-fork +track +derived +changed' "$out"

check "pull alpha" sk pull alpha
check "merged keeps local mod" has "$A/SKILL.md" "MODIFIED LOCALLY"
check "merged gains upstream change" has "$A/SKILL.md" "CHANGED UPSTREAM"
check "new upstream file added" cmp "$A/new.md" "$T/up-git/skills/alpha/new.md"
check "vendor now c2" cmp "$T/pub/vendor/alpha/alpha/SKILL.md" "$T/up-git/skills/alpha/SKILL.md"
check "lock records c2" has "$T/pub/Skillfile.lock" "$C2"
before=$(shasum -a 256 "$A"/* | shasum)
check "second pull succeeds" sk pull alpha
check "second pull is a no-op" test "$before" = "$(shasum -a 256 "$A"/* | shasum)"

check "pull beta-fork (track)" sk pull beta-fork
check "track pull leaves local alone" has "$T/pub/home/dot_cursor/skills/beta-fork/SKILL.md" "my fork of beta"
check "track pull refreshes vendor" has "$T/pub/vendor/beta-fork/beta/SKILL.md" "beta v2"

print "upstream deletes an unmodified file"
g rm -q skills/alpha/extra.md && g commit -qm c3
check "pull alpha after delete" sk pull alpha
check "unmodified local file removed" test ! -e "$A/extra.md"

print "conflict"
sed -i '' 's/line local-target/line local-target UPSTREAM EDIT/' "$T/up-git/skills/alpha/SKILL.md"
g add -A && g commit -qm c4
nok "conflicting pull exits non-zero" sk pull alpha
check "conflict markers written" has "$A/SKILL.md" "<<<<<<< local"
sk status > "$out" 2>&1
check "status shows conflict" grep -Eq '^alpha +merge +conflict' "$out"
sk pull alpha > "$out" 2>&1 && rc=0 || rc=$?
check "second pull refuses while markers remain" test $rc -eq 1
check "second pull names the unresolved file" grep -q 'still has <<<<<<< markers' "$out"

print "per-entry independence"
print "r1 v2" > "$T/up-dir/rules/r1.mdc"
check "pull p-rule" sk pull p-rule
sk status > "$out" 2>&1
check "p-rule current after its pull" grep -Eq '^p-rule +track +derived +current' "$out"
check "p-skill still changed" grep -Eq '^p-skill +track +derived +changed' "$out"
check "co-tree still changed" grep -Eq '^co-tree +watch .* changed' "$out"

print "install (symlink deploy)"
check "install" sk install
check "skill symlinked" test "$(readlink "$HOME/.cursor/skills/p-skill")" = "$T/priv/skills/p-skill"
check "rule symlinked" test "$(readlink "$HOME/.cursor/rules/p-rule.mdc")" = "$T/priv/rules/p-rule.mdc"
check "watch entry not deployed" test ! -e "$HOME/.cursor/skills/co-tree"
check "install is idempotent" sk install
rm "$HOME/.cursor/skills/p-skill" && mkdir "$HOME/.cursor/skills/p-skill" && print "different" > "$HOME/.cursor/skills/p-skill/SKILL.md"
nok "install refuses to clobber a differing real dir" sk install
check "differing real dir untouched" has "$HOME/.cursor/skills/p-skill/SKILL.md" "different"
rm -rf "$HOME/.cursor/skills/p-skill" && cp -R "$T/priv/skills/p-skill" "$HOME/.cursor/skills/p-skill"
check "install replaces an identical real dir" sk install
check "identical dir became symlink" test -L "$HOME/.cursor/skills/p-skill"

print "inventory"
mkdir -p "$HOME/.cursor/skills/stray" && print -l -- "---" "name: stray" "---" > "$HOME/.cursor/skills/stray/SKILL.md"
mkdir -p "$HOME/.cursor/plugins/cache/mkt/plug/abc123/.cursor-plugin" "$HOME/.cursor/plugins/cache/mkt/plug/abc123/skills/alpha"
print '{"name": "plug", "version": "1.2.3"}' > "$HOME/.cursor/plugins/cache/mkt/plug/abc123/.cursor-plugin/plugin.json"
touch "$HOME/.cursor/plugins/cache/mkt/plug/abc123/skills/alpha/SKILL.md"
mkdir -p "$HOME/.claude/skills/claude-only" && touch "$HOME/.claude/skills/claude-only/SKILL.md"
mkdir -p "$HOME/.cursor/plugins/cache/mkt/clplug/def456/.claude-plugin"
print '{"name": "clplug", "version": "0.9.0"}' > "$HOME/.cursor/plugins/cache/mkt/clplug/def456/.claude-plugin/plugin.json"
mkdir -p "$HOME/.cursor/skills-cursor/loop" "$HOME/.cursor/skills-cursor/shell" "$HOME/.cursor/skills/loop"
touch "$HOME/.cursor/skills-cursor/loop/SKILL.md" "$HOME/.cursor/skills-cursor/shell/SKILL.md" "$HOME/.cursor/skills/loop/SKILL.md"
sk status > "$out" 2>&1
check "claude-format plugin manifest listed" grep -Eq 'clplug +0\.9\.0' "$out"
check "built-in skills counted" grep -Eq '2 Cursor built-in skills' "$out"
check "name clash with built-in flagged" grep -Eq 'loop also provided by Cursor built-in' "$out"
check "unmanaged skill listed" grep -Eq 'unmanaged .*stray' "$out"
check "skill in ~/.claude/skills listed" grep -Eq 'claude-only' "$out"
check "plugin listed with version" grep -Eq 'plug +1\.2\.3' "$out"
check "name clash with plugin skill flagged" grep -Eq 'alpha .*also provided by plugin plug' "$out"

print "lock write failure"
print "beta v3" > "$T/up-git/skills/beta/SKILL.md"
g add -A && g commit -qm c5
C5=$(git -C "$T/up-git" rev-parse HEAD)
beta_row() { grep "^beta-fork"$'\t' "$T/pub/Skillfile.lock"; }
chmod a-w "$T/pub/Skillfile.lock"
nok "pull fails when the lock is read-only" sk pull beta-fork
check "failed pull leaves the lock at c2" test "$(beta_row)" = "beta-fork"$'\t'"up:skills/beta"$'\t'"$C2"
check "failed pull leaves vendor at c2" has "$T/pub/vendor/beta-fork/beta/SKILL.md" "beta v2"
nok "adopt fails when the lock is read-only" sk adopt beta-fork "$C5"
check "failed adopt leaves the lock at c2" test "$(beta_row)" = "beta-fork"$'\t'"up:skills/beta"$'\t'"$C2"
check "failed adopt leaves vendor at c2" has "$T/pub/vendor/beta-fork/beta/SKILL.md" "beta v2"
chmod u+w "$T/pub/Skillfile.lock"
check "pull succeeds once the lock is writable" sk pull beta-fork
check "retried pull moves the lock to c5" test "$(beta_row)" = "beta-fork"$'\t'"up:skills/beta"$'\t'"$C5"
check "retried pull moves vendor to c5" has "$T/pub/vendor/beta-fork/beta/SKILL.md" "beta v3"

print "manifest validation"
print "merge skills/alpha up:skills/alpha" >> "$T/priv/Skillfile"
print "upstream up $T/up-git" >> "$T/priv/Skillfile"
nok "duplicate name across Skillfiles rejected" sk status
print -l -- "upstream up $T/up-git" "watch clash up:skills/alpha/SKILL.md up:skills/beta/SKILL.md" > "$T/clash.Skillfile"
"$SKILLS" -f "$T/clash.Skillfile" status > "$out" 2>&1 && rc=0 || rc=$?
check "two sources with one file name rejected" test $rc -eq 2
check "rejection names the clashing file" grep -q "two sources named 'SKILL.md'" "$out"

print "\n$pass passed, $fail failed"
(( fail == 0 ))
