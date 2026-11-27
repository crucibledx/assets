#!/usr/bin/env bash
# The contract: every binary is tracked by Git LFS. Fails when a file that should be a pointer is committed as
# ordinary content, or when a pointer at a binary extension has no lfs filter attribute. Runs on a clean checkout
# (CI); the index is HEAD.
set -euo pipefail
cd "$(dirname "$0")/.."
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
rc=0

allfiles=$(git ls-tree -r --name-only HEAD)
withattr=$(printf '%s\n' "$allfiles" | git check-attr --stdin filter | sed -n 's/: filter: lfs$//p')
pointers=$(git grep -l 'version https://git-lfs.github.com/spec' HEAD -- . | sed 's/^HEAD://' || true)

# Should be pointers but are not: lfs-attribute files (committed without git-lfs; a small text blob slips past
# the binary check) plus any committed binary blob, attribute or not (git's own binary heuristic; pointers are
# text, so a binary blob is never a pointer).
blobs=$(git diff-tree -r --no-commit-id --numstat "$EMPTY_TREE" HEAD | awk -F'\t' '$1 == "-" && $2 == "-" {print $3}')
violators=$({ printf '%s\n' "$withattr"; printf '%s\n' "$blobs"; } | sed '/^$/d' | sort -u \
  | comm -23 - <(printf '%s\n' "$pointers" | sed '/^$/d' | sort -u))
if [ -n "$violators" ]; then
  echo "Committed as ordinary content, not Git LFS pointers:" >&2
  echo "$violators" >&2
  rc=1
fi

# The reverse: a pointer at a binary extension whose path lost the lfs filter attribute (it checks out as the
# pointer text). Scripts and docs that quote the pointer format are not binary extensions, so they are ignored.
ptr_ext=$(printf '%s\n' "$pointers" | grep -iE '\.(gif|png|jpe?g|webp|mp4)$' || true)
noattr=$(comm -23 <(printf '%s\n' "$ptr_ext" | sed '/^$/d' | sort -u) \
  <(printf '%s\n' "$withattr" | sed '/^$/d' | sort -u))
if [ -n "$noattr" ]; then
  echo "Git LFS pointers without the lfs filter attribute:" >&2
  echo "$noattr" >&2
  rc=1
fi
exit $rc
