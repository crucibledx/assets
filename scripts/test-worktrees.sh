#!/usr/bin/env bash
# Exercise script discovery from a checkout below a hidden parent directory.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP=$(mktemp -d /tmp/assets-worktree-scripts.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/.worktrees/x"
CALLS="$TMP/calls"
export CALLS
mkdir -p "$FIXTURE/scripts" "$TMP/bin" "$CALLS"
cp "$SRC"/*.sh "$SRC"/*.mjs "$FIXTURE/scripts/"
chmod +x "$FIXTURE/scripts"/*.sh

# Keep the test independent of SVGO, draw.io, and VHS installations.
cat > "$TMP/bin/bunx" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$CALLS/bunx"
input=
output=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output=$2; shift 2 ;;
    -) input=-; shift ;;
    *.svg) input=$1; shift ;;
    *) shift ;;
  esac
done
if [ "$output" = "-" ]; then
  if [ "$input" = "-" ]; then
    cat
  else
    cat "$input"
  fi
elif [ "$input" != "$output" ]; then
  cp "$input" "$output"
fi
STUB
cat > "$TMP/bin/drawio" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$CALLS/drawio"
output=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output=$2; shift 2 ;;
    *) shift ;;
  esac
done
mkdir -p "$(dirname "$output")"
printf '<svg xmlns="http://www.w3.org/2000/svg"></svg>\n' > "$output"
STUB
cat > "$TMP/bin/vhs" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$CALLS/vhs"
output=$(awk -F'"' '/^Output / { print $2; exit }' "$1")
mkdir -p "$(dirname "$output")"
printf 'GIF89a' > "$output"
STUB
chmod +x "$TMP/bin"/*
PATH="$TMP/bin:$PATH"
export PATH

cd "$FIXTURE"
git init -q
git config user.email t@t && git config user.name t
mkdir -p platform/diagrams/light platform/demos .github/light platform/.cache/light
cat > platform/diagrams/flow.drawio <<'SVG'
<mxfile><diagram name="Flow">flow</diagram></mxfile>
SVG
cat > platform/diagrams/multi.drawio <<'SVG'
<mxfile>
<diagram name="First Page">one</diagram>
<diagram name="Second Page">two</diagram>
</mxfile>
SVG
cat > platform/diagrams/light/flow.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg"><rect fill="#fff" style="color-scheme:light"/></svg>
SVG
cat > platform/demos/demo.tape <<'TAPE'
Output "platform/demos/light/demo.gif"
Type "demo"
TAPE
cp platform/diagrams/flow.drawio .github/hidden.drawio
cp platform/diagrams/light/flow.svg .github/light/hidden.svg
cp platform/demos/demo.tape .github/hidden.tape
cp platform/diagrams/flow.drawio platform/.cache/ignored.drawio
cp platform/diagrams/light/flow.svg platform/.cache/light/ignored.svg
cp platform/demos/demo.tape platform/.cache/ignored.tape
git add .
git commit -qm fixture

scripts/optimize-svgs.sh > "$TMP/optimize-all.out"
scripts/generate-dark-svgs.sh > "$TMP/dark-all.out"
scripts/export-diagrams.sh > "$TMP/export-all.out"
scripts/generate-demos.sh > "$TMP/demos-all.out"

grep -F 'optimized 1 SVG(s).' "$TMP/optimize-all.out"
grep -F 'generated 1 dark variant(s).' "$TMP/dark-all.out"
grep -F 'exported 3 output(s).' "$TMP/export-all.out"
grep -F 'generated 2 GIF(s).' "$TMP/demos-all.out"
test -f platform/diagrams/light/first-page.svg
test -f platform/diagrams/light/second-page.svg
test -f platform/diagrams/dark/flow.svg
test -f platform/demos/light/demo.gif
test -f platform/demos/dark/demo.gif
test ! -e .github/dark/hidden.svg
test ! -e .github/hidden.gif
test ! -e platform/.cache/dark/ignored.svg
! grep -E '/[.](github|cache)/' "$CALLS/bunx"
! grep -E '/[.](github|cache)/' "$CALLS/drawio"
! grep -E '/[.](github|cache)/' "$CALLS/vhs"

# Commit all outputs so each --changed run has exactly one matching input.
git add .
git commit -qm generated-baseline
: > "$CALLS/bunx"
: > "$CALLS/drawio"
: > "$CALLS/vhs"
printf '\n<!-- changed -->\n' >> platform/diagrams/light/flow.svg
printf '\n<!-- changed -->\n' >> platform/diagrams/flow.drawio
printf '\nSleep 1s\n' >> platform/demos/demo.tape
printf '\n<!-- hidden change -->\n' >> .github/light/hidden.svg
printf '\n<!-- hidden change -->\n' >> .github/hidden.drawio
printf '\nSleep 1s\n' >> .github/hidden.tape
printf '\n<!-- hidden change -->\n' >> platform/.cache/light/ignored.svg
printf '\n<!-- hidden change -->\n' >> platform/.cache/ignored.drawio
printf '\nSleep 1s\n' >> platform/.cache/ignored.tape

scripts/optimize-svgs.sh --changed > "$TMP/optimize-changed.out"
grep -F 'optimized 1 SVG(s).' "$TMP/optimize-changed.out"
test "$(wc -l < "$CALLS/bunx" | tr -d ' ')" = 1
grep -F '<!-- changed -->' platform/diagrams/light/flow.svg
! grep -E '/[.](github|cache)/' "$CALLS/bunx"

scripts/export-diagrams.sh --changed > "$TMP/export-changed.out"
grep -F 'exported 1 output(s).' "$TMP/export-changed.out"
test "$(wc -l < "$CALLS/drawio" | tr -d ' ')" = 1
grep -F 'platform/diagrams/flow.drawio' "$CALLS/drawio"
! grep -E '/[.](github|cache)/' "$CALLS/drawio"

scripts/generate-demos.sh --changed > "$TMP/demos-changed.out"
grep -F 'generated 2 GIF(s).' "$TMP/demos-changed.out"
test "$(wc -l < "$CALLS/vhs" | tr -d ' ')" = 2
! grep -E '/[.](github|cache)/' "$CALLS/vhs"

printf 'PASS: hidden-parent discovery, internal pruning, and changed-file acceptance\n'
