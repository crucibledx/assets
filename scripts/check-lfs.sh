#!/usr/bin/env bash
# The contract: every binary is tracked by Git LFS. Fails when a file that should be a pointer is committed as
# ordinary content, or when a pointer at a binary extension has no lfs filter attribute. Runs on a clean checkout
# (CI); the index is HEAD. All path enumeration is NUL-delimited (-z), so quoted or non-ASCII names survive.
# Kept free of bash-4 features (associative arrays, mapfile) so it runs on macOS's bash 3.2 too.
set -euo pipefail
cd "$(dirname "$0")/.."
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
rc=0

in_list() { local needle=$1 x; shift; for x in "$@"; do [ "$x" = "$needle" ] && return 0; done; return 1; }

allfiles=()
while IFS= read -r -d '' f; do allfiles+=("$f"); done < <(git ls-tree -r -z --name-only HEAD)

# Paths whose filter attribute is lfs. check-attr -z answers path NUL attr NUL value NUL per query.
withattr=()
if ((${#allfiles[@]})); then
  while IFS= read -r -d '' path && IFS= read -r -d '' attr && IFS= read -r -d '' value; do
    if [ "$attr" = filter ] && [ "$value" = lfs ]; then withattr+=("$path"); fi
  done < <(printf '%s\0' "${allfiles[@]}" | git check-attr -z --stdin filter)
fi

# A committed pointer, validated by git-lfs's own parser: the whole blob must parse.
is_pointer() {
  git cat-file blob "$(git rev-parse --verify "HEAD:$1" 2>/dev/null)" 2>/dev/null \
    | git lfs pointer --check --stdin >/dev/null 2>&1
}

candidates=()
while IFS= read -r -d '' f; do candidates+=("${f#HEAD:}"); done \
  < <(git grep -l -z 'git-lfs.github.com/spec' HEAD -- . || true)
pointers=()
for f in ${candidates[@]+"${candidates[@]}"}; do
  if is_pointer "$f"; then pointers+=("$f"); fi
done

# Committed binary blobs (git's own binary heuristic; a pointer is text, so a binary blob is never a pointer).
# numstat -z prints "<added>\t<deleted>\t<path>" NUL per entry; a binary has "-" for both counts.
marker=$'-\t-\t'
blobs=()
while IFS= read -r -d '' rec; do
  case $rec in
    "$marker"*) blobs+=("${rec#$marker}") ;;
  esac
done < <(git diff-tree -r -z --no-commit-id --numstat "$EMPTY_TREE" HEAD)

# Should be pointers but are not: lfs-attribute files (committed without git-lfs; a small text blob slips past
# the binary check) plus any committed binary blob, attribute or not.
violators=()
for f in ${withattr[@]+"${withattr[@]}"} ${blobs[@]+"${blobs[@]}"}; do
  if ! in_list "$f" ${pointers[@]+"${pointers[@]}"} && ! in_list "$f" ${violators[@]+"${violators[@]}"}; then
    violators+=("$f")
  fi
done
if ((${#violators[@]})); then
  echo "Committed as ordinary content, not Git LFS pointers:" >&2
  printf '%q\n' "${violators[@]}" >&2
  rc=1
fi

# The reverse: a pointer at a binary extension whose path lost the lfs filter attribute (it checks out as the
# pointer text). Scripts and docs that quote the pointer format are not binary extensions, so they are ignored.
noattr=()
shopt -s nocasematch
for f in ${pointers[@]+"${pointers[@]}"}; do
  case $f in
    *.gif|*.png|*.jpg|*.jpeg|*.webp|*.mp4)
      if ! in_list "$f" ${withattr[@]+"${withattr[@]}"}; then noattr+=("$f"); fi ;;
  esac
done
shopt -u nocasematch
if ((${#noattr[@]})); then
  echo "Git LFS pointers without the lfs filter attribute:" >&2
  printf '%q\n' "${noattr[@]}" >&2
  rc=1
fi
exit $rc
