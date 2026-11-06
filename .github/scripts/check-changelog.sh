#!/usr/bin/env bash
# Exercise the real compiler in isolated repositories, without touching fragments.
set -euo pipefail
compiler="$(cd "$(dirname "$0")" && pwd)/compile-changelog.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"; [ ! -e "$tmp" ] && echo "PASS: fixture cleanup"' EXIT
git init -q "$tmp"
mkdir "$tmp/changelog.d"
cd "$tmp"

check() {
  local name=$1 expected=$2
  if bash "$compiler" > "$tmp/out" 2> "$tmp/err"; then
    actual=0
  else
    actual=$?
  fi
  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL: $name: expected exit $expected, got $actual"
    cat "$tmp/out" "$tmp/err"
    exit 1
  fi
  if [ "$expected" -ne 0 ]; then
    grep -Fq 'changelog.d/' "$tmp/err"
    grep -Fq 'changelog.d/README.md' "$tmp/err"
    [ ! -s "$tmp/out" ]
  fi
  echo "PASS: $name"
}

check 'no fragments' 0
[ ! -s "$tmp/out" ]
printf '%s\n' '# Instructions, not a fragment' > changelog.d/README.md
printf '%s\n' '- **Title.** Description.' '  _[@author](https://github.com/author) - PR #123._' > changelog.d/example.added.md
check 'wrapped bullet' 0
{ printf '### Added\n'; cat changelog.d/example.added.md; printf '\n'; } > "$tmp/expected"
diff -u "$tmp/expected" "$tmp/out"
printf '%s\r\n' '- **Title.** Description. PR #123.' > changelog.d/example.added.md
check 'CRLF bullet' 0
printf '%s' '- **Title.** Description. PR #123.' > changelog.d/example.added.md
check 'no final newline' 0
: > changelog.d/example.added.md
check 'empty file' 1

for content in \
  '' \
  'Description. PR #123.' \
  '- Title. Description. PR #123.' \
  '- **Title.** Description. Issue #123.' \
  '- **Title.** Description. PR #N.'
do
  printf '%s\n' "$content" > changelog.d/example.added.md
  check "invalid content: $content" 1
done
printf '\n%s\n' '- **Title.** Description. PR #123.' > changelog.d/example.added.md
check 'leading blank line' 1
printf '%s\n' '- **Title.** Description. PR #123.' > changelog.d/example.added.md
mv changelog.d/example.added.md changelog.d/example.wrong.md
check 'invalid filename' 1
rm changelog.d/example.wrong.md
for kind in added changed fixed; do
  printf '%s\n' "- **$kind.** Description. PR #123." > "changelog.d/example.$kind.md"
done
check 'all sections' 0
printf '### Added\n- **added.** Description. PR #123.\n\n### Changed\n- **changed.** Description. PR #123.\n\n### Fixed\n- **fixed.** Description. PR #123.\n\n' > "$tmp/expected"
diff -u "$tmp/expected" "$tmp/out"
