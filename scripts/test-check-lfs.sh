#!/usr/bin/env bash
# check-lfs.sh against real git fixtures: a clean repo passes; an ordinary binary blob, with or without the
# attribute, fails; a pointer without the lfs attribute fails. Blobs are committed through hash-object so a
# machine with git-lfs installed does not clean the fixtures into pointers.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP=$(mktemp -d /tmp/assets-check-lfs.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
POINTER='version https://git-lfs.github.com/spec/v1
oid sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
size 123'

mkrepo() {
  git init -q "$1"
  git -C "$1" config user.email t@t && git -C "$1" config user.name t
  mkdir -p "$1/scripts"
  cp "$SRC/check-lfs.sh" "$1/scripts/"
  printf '*.gif filter=lfs diff=lfs merge=lfs -text\n*.bin filter=lfs diff=lfs merge=lfs -text\n' >"$1/.gitattributes"
}
# Commit the given files as raw blobs, bypassing any clean filter.
commit_raw() {
  local repo=$1 f blob
  shift
  for f in "$@"; do
    blob=$(git -C "$repo" hash-object -w --no-filters "$repo/$f")
    git -C "$repo" update-index --add --cacheinfo "100644,$blob,$f"
  done
  git -C "$repo" add scripts/check-lfs.sh .gitattributes
  git -C "$repo" commit -qm x
}

# Clean: a pointer with the attribute, plus ordinary text.
mkrepo "$TMP/clean"
printf '%s\n' "$POINTER" >"$TMP/clean/a.gif"
echo text >"$TMP/clean/notes.md"
commit_raw "$TMP/clean" a.gif notes.md
bash "$TMP/clean/scripts/check-lfs.sh"

# An ordinary binary blob at a tracked extension fails and is named.
mkrepo "$TMP/blob"
printf '%s\n' "$POINTER" >"$TMP/blob/a.gif"
printf 'GIF89a\0\0binary' >"$TMP/blob/b.bin"
commit_raw "$TMP/blob" a.gif b.bin
if bash "$TMP/blob/scripts/check-lfs.sh" 2>"$TMP/blob.err"; then
  echo "an ordinary blob passed" >&2; exit 1
fi
grep -q "b.bin" "$TMP/blob.err"

# A binary at an extension the attributes do not track fails too (identified by content, not attribute).
mkrepo "$TMP/noext"
printf '%s\n' "$POINTER" >"$TMP/noext/a.gif"
printf 'PNG\0\0binary' >"$TMP/noext/c.raw"
commit_raw "$TMP/noext" a.gif c.raw
if bash "$TMP/noext/scripts/check-lfs.sh" 2>"$TMP/noext.err"; then
  echo "an untracked-extension blob passed" >&2; exit 1
fi
grep -q "c.raw" "$TMP/noext.err"

# A pointer whose extension lost the attribute fails.
mkrepo "$TMP/noattr"
printf '*.bin filter=lfs diff=lfs merge=lfs -text\n' >"$TMP/noattr/.gitattributes"
printf '%s\n' "$POINTER" >"$TMP/noattr/a.gif"
commit_raw "$TMP/noattr" a.gif
if bash "$TMP/noattr/scripts/check-lfs.sh" 2>"$TMP/noattr.err"; then
  echo "an attribute-less pointer passed" >&2; exit 1
fi
grep -q "a.gif" "$TMP/noattr.err"

echo "PASS: clean repos pass; ordinary blobs (tracked or not) and attribute-less pointers fail, named"
