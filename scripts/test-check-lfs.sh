#!/usr/bin/env bash
# check-lfs.sh passes a clean repo and fails one with an LFS-patterned file committed as an ordinary blob.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP=$(mktemp -d /tmp/assets-check-lfs.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

mkrepo() {
  git init -q "$1"
  mkdir -p "$1/scripts"
  cp "$SRC/check-lfs.sh" "$1/scripts/"
  printf '*.bin filter=lfs diff=lfs merge=lfs -text\n' >"$1/.gitattributes"
  git -C "$1" add . >/dev/null
}

# Clean: the pointer-looking blob is committed, and git lfs ls-files (stubbed) lists it.
mkdir -p "$TMP/clean" "$TMP/bin"
cat >"$TMP/bin/git" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "-C" ]; then shift 2; fi
case "$1 $2" in
  "lfs ls-files") echo "a.bin" ;;
  "ls-files ") echo "a.bin" ;;
  "check-attr --stdin") echo "a.bin: filter: lfs" ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$TMP/bin/git"
mkrepo "$TMP/clean"
PATH="$TMP/bin:$PATH" bash "$TMP/clean/scripts/check-lfs.sh"

# Dirty: the same attributes, but ls-files (the pointer list) is empty, so a.bin is an ordinary blob.
mkdir -p "$TMP/dirty"
sed 's/echo "a.bin" ;;/true ;;/' "$TMP/bin/git" >"$TMP/bin/git-dirty" 2>/dev/null || true
cat >"$TMP/bin/git" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "-C" ]; then shift 2; fi
case "$1 $2" in
  "lfs ls-files") true ;;
  "ls-files ") echo "a.bin" ;;
  "check-attr --stdin") echo "a.bin: filter: lfs" ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$TMP/bin/git"
mkrepo "$TMP/dirty"
if PATH="$TMP/bin:$PATH" bash "$TMP/dirty/scripts/check-lfs.sh" 2>"$TMP/dirty.err"; then
  echo "check-lfs.sh passed an ordinary blob; want a failure" >&2
  exit 1
fi
grep -q "a.bin" "$TMP/dirty.err"
echo "PASS: clean repos pass, ordinary blobs fail with the file named"
