#!/usr/bin/env bash
# Run pinned SVGO without losing meaningful HTML whitespace in foreignObject.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVGO_VERSION="4.1.0"
CONFIG="$1"
WHITESPACE="$REPO_ROOT/scripts/foreign-object-whitespace.mjs"

bun "$WHITESPACE" protect |
  bunx "svgo@$SVGO_VERSION" --config "$CONFIG" - -o - --quiet |
  bun "$WHITESPACE" restore
