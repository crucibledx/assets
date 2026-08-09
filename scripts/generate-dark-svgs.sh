#!/usr/bin/env bash
#
# Generate dark-mode SVG variants from light SVGs.
#
# Applies the same visual transform as the web CSS:
#   filter: invert(1) hue-rotate(180deg)
#
# The filter is injected into the root <svg> style attribute, and the
# background is swapped from white to transparent so the inverted
# background doesn't produce a black rectangle.
#
# Usage:
#   scripts/generate-dark-svgs.sh                    # all diagram SVGs
#   scripts/generate-dark-svgs.sh platform            # only platform/
#   scripts/generate-dark-svgs.sh platform/diagrams/light/platform-flow.svg  # single file
#
# Light SVGs live in light/ directories, dark variants go to dark/:
#   platform/diagrams/light/platform-flow.svg  →  platform/diagrams/dark/platform-flow.svg
#
# No dependencies beyond sed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FILTER=""
[[ $# -gt 0 ]] && FILTER="$1"

# Find light SVGs to process
find_svgs() {
  local search_dir="$REPO_ROOT"

  if [[ -n "$FILTER" && -f "$REPO_ROOT/$FILTER" ]]; then
    echo "$REPO_ROOT/$FILTER"
    return
  fi

  if [[ -n "$FILTER" && -d "$REPO_ROOT/$FILTER" ]]; then
    search_dir="$REPO_ROOT/$FILTER"
  fi

  find "$search_dir" -path '*/light/*.svg' -not -path '*/branding/*' | sort
}

# Generate dark variant of a single SVG
generate_dark() {
  local src="$1"
  local name="$(basename "$src")"
  # light/ → dark/ sibling directory
  local dark_dir="$(dirname "$src" | sed 's|/light$|/dark|')"
  local out="$dark_dir/$name"

  mkdir -p "$dark_dir"

  # 1. Replace background colors with transparent
  # 2. Inject the invert filter into the root <svg> style
  # 3. Swap color-scheme from light to dark
  sed \
    -e 's/background:#fff;background-color:#fff/background:transparent;background-color:transparent/g' \
    -e 's/color-scheme:light/color-scheme:dark;filter:invert(1) hue-rotate(180deg)/g' \
    -e 's/fill="#fff" stroke-width="0"/fill="transparent" stroke-width="0"/g' \
    "$src" > "$out"

  local rel="${out#$REPO_ROOT/}"
  echo "▸ $rel"
}

# Main
svgs=$(find_svgs)

if [[ -z "$svgs" ]]; then
  echo "No SVGs to process."
  exit 0
fi

count=0
while IFS= read -r file; do
  generate_dark "$file"
  ((count++))
done <<< "$svgs"

echo ""
echo "Done — generated $count dark variant(s)."
