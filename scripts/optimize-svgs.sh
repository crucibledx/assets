#!/usr/bin/env bash
#
# Optimize SVG files using SVGO. Typically reduces size 5-10x.
#
# Usage:
#   scripts/optimize-svgs.sh                              # all SVGs in the repo
#   scripts/optimize-svgs.sh forge                        # only forge/ category
#   scripts/optimize-svgs.sh forge/diagrams/dark/flow.svg # single file
#   scripts/optimize-svgs.sh --dry-run                    # show savings without writing
#   scripts/optimize-svgs.sh --changed                    # only changed since last commit
#
# Requires: svgo (available via bunx/npx, or install globally: npm i -g svgo)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Parse arguments
FILTER=""
DRY_RUN=false
CHANGED_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --changed)  CHANGED_ONLY=true; shift ;;
    *)          FILTER="$1"; shift ;;
  esac
done

# Find SVG files to optimize
find_svgs() {
  if [[ -n "$FILTER" && -f "$REPO_ROOT/$FILTER" ]]; then
    echo "$REPO_ROOT/$FILTER"
    return
  fi

  local search_dir="$REPO_ROOT"
  if [[ -n "$FILTER" && -d "$REPO_ROOT/$FILTER" ]]; then
    search_dir="$REPO_ROOT/$FILTER"
  fi

  if [[ "$CHANGED_ONLY" == true ]]; then
    {
      git -C "$REPO_ROOT" diff --name-only HEAD -- '*.svg' 2>/dev/null
      git -C "$REPO_ROOT" diff --name-only --cached -- '*.svg' 2>/dev/null
      git -C "$REPO_ROOT" ls-files --others --exclude-standard -- '*.svg' 2>/dev/null
    } | sort -u | while read -r rel; do
      local path="$REPO_ROOT/$rel"
      [[ -f "$path" ]] && echo "$path"
    done
    return
  fi

  find "$search_dir" -name '*.svg' -not -path '*/\.*' | sort
}

# Format bytes to human-readable
human_size() {
  local bytes=$1
  if [[ $bytes -ge 1048576 ]]; then
    echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
  elif [[ $bytes -ge 1024 ]]; then
    echo "$(echo "scale=1; $bytes / 1024" | bc)KB"
  else
    echo "${bytes}B"
  fi
}

# Main
svgs=$(find_svgs)

if [[ -z "$svgs" ]]; then
  echo "No SVGs to optimize."
  exit 0
fi

total_before=0
total_after=0
count=0

while IFS= read -r file; do
  rel="${file#$REPO_ROOT/}"
  before=$(wc -c < "$file" | tr -d ' ')

  if [[ "$DRY_RUN" == true ]]; then
    # Run svgo to stdout, measure size without writing
    after=$(bunx svgo "$file" -o - 2>/dev/null | wc -c | tr -d ' ')
    ratio=$(echo "scale=0; (1 - $after / $before) * 100" | bc 2>/dev/null || echo "?")
    echo "▸ $rel: $(human_size "$before") → $(human_size "$after") (-${ratio}%) [dry-run]"
  else
    bunx svgo "$file" -o "$file" --quiet 2>/dev/null
    after=$(wc -c < "$file" | tr -d ' ')
    ratio=$(echo "scale=0; (1 - $after / $before) * 100" | bc 2>/dev/null || echo "?")
    echo "▸ $rel: $(human_size "$before") → $(human_size "$after") (-${ratio}%)"
  fi

  total_before=$((total_before + before))
  total_after=$((total_after + after))
  ((count++))
done <<< "$svgs"

echo ""
echo "Done — optimized $count SVG(s)."
echo "Total: $(human_size "$total_before") → $(human_size "$total_after")"
