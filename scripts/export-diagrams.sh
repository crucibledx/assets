#!/usr/bin/env bash
#
# Export .drawio files to SVG (default) or PNG.
# Handles multi-page files by exporting each page separately.
#
# Usage:
#   scripts/export-diagrams.sh                              # all diagrams, SVG
#   scripts/export-diagrams.sh forge                        # only forge/ category
#   scripts/export-diagrams.sh forge/diagrams/flow.drawio   # single file
#   scripts/export-diagrams.sh --format png                 # export as PNG
#   scripts/export-diagrams.sh --scale 2                    # PNG scale factor (default: 2)
#   scripts/export-diagrams.sh --changed                    # only changed since last commit
#
# Outputs land next to the source file (e.g., forge/diagrams/flow.svg).
# For multi-page files, each page exports as: <page-name>.svg
#
# Requires: draw.io desktop app (https://github.com/jgraph/drawio-desktop)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Locate draw.io CLI
find_drawio() {
  if command -v drawio &>/dev/null; then
    echo "drawio"
  elif [ -f "/Applications/draw.io.app/Contents/MacOS/draw.io" ]; then
    echo "/Applications/draw.io.app/Contents/MacOS/draw.io"
  elif [ -f "/mnt/c/Program Files/draw.io/draw.io.exe" ]; then
    echo "/mnt/c/Program Files/draw.io/draw.io.exe"
  else
    echo "Error: draw.io CLI not found. Install the draw.io desktop app." >&2
    exit 1
  fi
}

# Parse arguments
FORMAT="svg"
SCALE=2
FILTER=""
CHANGED_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)  FORMAT="$2"; shift 2 ;;
    --scale)   SCALE="$2"; shift 2 ;;
    --changed) CHANGED_ONLY=true; shift ;;
    *)         FILTER="$1"; shift ;;
  esac
done

DRAWIO_CMD=$(find_drawio)
echo "Using draw.io: $DRAWIO_CMD"
echo "Format: $FORMAT | Scale: ${SCALE}x"
echo ""

# Get page names from a .drawio file
get_pages() {
  local file="$1"
  grep -oE '<diagram[^>]* name="[^"]+"' "$file" \
    | sed -E 's/.*name="([^"]+)".*/\1/' \
    || echo ""
}

# Count pages
count_pages() {
  local file="$1"
  grep -c '<diagram ' "$file" 2>/dev/null || echo "1"
}

# Find .drawio files to process
find_diagrams() {
  if [[ -n "$FILTER" && -f "$REPO_ROOT/$FILTER" ]]; then
    # Single file
    echo "$REPO_ROOT/$FILTER"
    return
  fi

  local search_dir="$REPO_ROOT"
  if [[ -n "$FILTER" && -d "$REPO_ROOT/$FILTER" ]]; then
    search_dir="$REPO_ROOT/$FILTER"
  fi

  if [[ "$CHANGED_ONLY" == true ]]; then
    {
      git -C "$REPO_ROOT" diff --name-only HEAD -- '*.drawio' 2>/dev/null
      git -C "$REPO_ROOT" diff --name-only --cached -- '*.drawio' 2>/dev/null
      git -C "$REPO_ROOT" ls-files --others --exclude-standard -- '*.drawio' 2>/dev/null
    } | sort -u | while read -r rel; do
      local path="$REPO_ROOT/$rel"
      [[ -f "$path" ]] && echo "$path"
    done
    return
  fi

  find "$search_dir" -name '*.drawio' -not -path '*/\.*' | sort
}

# Export a single .drawio file
export_diagram() {
  local file="$1"
  local dir="$(dirname "$file")"
  local num_pages
  num_pages=$(count_pages "$file")

  if [[ "$num_pages" -le 1 ]]; then
    # Single page — output named after the file
    local name="$(basename "$file" .drawio)"
    local out="$dir/${name}.${FORMAT}"
    local rel="${out#$REPO_ROOT/}"
    echo "▸ Exporting $(basename "$file") → $rel"
    "$DRAWIO_CMD" -x -f "$FORMAT" -b 10 --scale "$SCALE" -o "$out" "$file" 2>/dev/null
    return 1
  fi

  # Multi-page — export each page separately
  local page_index=0
  local exported=0
  while IFS= read -r page_name; do
    [[ -z "$page_name" ]] && continue
    # Sanitize page name for filename (spaces → dashes, lowercase)
    local safe_name
    safe_name=$(echo "$page_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    local out="$dir/${safe_name}.${FORMAT}"
    local rel="${out#$REPO_ROOT/}"
    echo "▸ Exporting $(basename "$file") [page: $page_name] → $rel"
    "$DRAWIO_CMD" -x -f "$FORMAT" -p "$page_index" -b 10 --scale "$SCALE" -o "$out" "$file" 2>/dev/null
    ((page_index++))
    ((exported++))
  done <<< "$(get_pages "$file")"
  return "$exported"
}

# Main
diagrams=$(find_diagrams)

if [[ -z "$diagrams" ]]; then
  echo "No diagrams to process."
  exit 0
fi

count=0
while IFS= read -r file; do
  export_diagram "$file"
  count=$((count + $?))
done <<< "$diagrams"

echo ""
echo "Done — exported $count output(s)."
