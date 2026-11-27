#!/usr/bin/env bash
# Fail when a file whose .gitattributes filter is lfs is committed as an ordinary blob instead of an LFS pointer,
# which is what committing without git-lfs installed (or a missing .gitattributes pattern) produces.
set -euo pipefail
cd "$(dirname "$0")/.."
missing=$(comm -23 \
  <(git ls-files | git check-attr --stdin filter | grep ': filter: lfs$' | sed 's/: filter: lfs$//' | sort) \
  <(git lfs ls-files -n | sort))
if [ -n "$missing" ]; then
  echo "Committed as ordinary blobs, not Git LFS pointers:" >&2
  echo "$missing" >&2
  exit 1
fi
