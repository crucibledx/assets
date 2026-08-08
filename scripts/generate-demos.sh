#!/usr/bin/env bash
#
# Generate dark + light GIF variants from .tape templates.
#
# Usage:
#   scripts/generate-demos.sh                                    # all tapes, both themes
#   scripts/generate-demos.sh forge                              # only forge/ category
#   scripts/generate-demos.sh forge/demos/01-set-and-forget.tape # single tape
#   scripts/generate-demos.sh --dark                             # all tapes, dark only
#   scripts/generate-demos.sh --light forge                      # forge category, light only
#   scripts/generate-demos.sh --changed                          # only changed since last commit
#
# Tapes use {{THEME}} and {{VARIANT}} placeholders.
# Output goes to <category>/demos/<variant>/<basename>.gif
#
# Requires: VHS (brew install charmbracelet/tap/vhs)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

# Theme definitions — add new themes here
theme_for() {
  case "$1" in
    dark)  echo "Catppuccin Mocha" ;;
    light) echo "Catppuccin Latte" ;;
  esac
}

# Parse arguments
VARIANTS=("dark" "light")
FILTER=""
CHANGED_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dark)    VARIANTS=("dark"); shift ;;
    --light)   VARIANTS=("light"); shift ;;
    --changed) CHANGED_ONLY=true; shift ;;
    *)         FILTER="$1"; shift ;;
  esac
done

# Find .tape files to process
find_tapes() {
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
      git -C "$REPO_ROOT" diff --name-only HEAD -- '*.tape' 2>/dev/null
      git -C "$REPO_ROOT" diff --name-only --cached -- '*.tape' 2>/dev/null
      git -C "$REPO_ROOT" ls-files --others --exclude-standard -- '*.tape' 2>/dev/null
    } | sort -u | while read -r rel; do
      local path="$REPO_ROOT/$rel"
      [[ "$(basename "$path")" == test-* ]] && continue
      [[ -f "$path" ]] && echo "$path"
    done
    return
  fi

  find "$search_dir" -name '*.tape' -not -name 'test-*' -not -path '*/\.*' | sort
}

# Generate a single GIF from a tape + variant
generate() {
  local tape="$1"
  local variant="$2"
  local theme
  theme=$(theme_for "$variant")

  local tape_dir="$(dirname "$tape")"
  local basename="$(basename "$tape" .tape)"
  local out_dir="$tape_dir/$variant"
  local out_file="$out_dir/${basename}.gif"
  local rel="${out_file#$REPO_ROOT/}"

  mkdir -p "$out_dir"

  # Create temp tape with replaced placeholders + overridden Output path
  local tmp_tape="$TMP_DIR/${basename}-${variant}.tape"
  sed \
    -e "s|{{THEME}}|$theme|g" \
    -e "s|{{VARIANT}}|$variant|g" \
    -e "s|^Output .*|Output $out_file|" \
    "$tape" > "$tmp_tape"

  echo "▸ Generating $rel ..."
  (cd "$REPO_ROOT" && vhs "$tmp_tape")
  echo "  ✓ $rel"
}

# Main
tapes=$(find_tapes)

if [[ -z "$tapes" ]]; then
  echo "No tapes to process."
  exit 0
fi

count=0
while IFS= read -r tape; do
  for variant in "${VARIANTS[@]}"; do
    generate "$tape" "$variant"
    ((count++))
  done
done <<< "$tapes"

echo ""
echo "Done — generated $count GIF(s)."
