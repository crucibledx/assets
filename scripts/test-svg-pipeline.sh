#!/usr/bin/env bash
# Verify deterministic optimization and dark generation in either order.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d "$REPO_ROOT/platform/diagrams/svg-pipeline-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
REL="${TMP#$REPO_ROOT/}"
mkdir -p "$TMP/light" "$TMP/dark"
WHITE='(#fff(fff)?|rgb\(255,255,255\))'

cat > "$TMP/light/first-child-a.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" style="background:#ffffff;background-color:#ffffff;color-scheme:light"><rect width="100%" height="100%" fill="#ffffff" style="fill:#ffffff" data-kind="root"/><defs><style>.solid{fill:#fff}</style></defs><rect width="100%" height="100%" fill="#fff" data-kind="after-defs-decoy"/><g><rect width="100%" height="100%" fill="#ffffff" style="fill:#ffffff" data-kind="nested"/><rect width="100%" height="100%" fill="#ffffff" stroke-width="0" data-kind="nested-stroke"/><foreignObject width="100" height="100"><div xmlns="http://www.w3.org/1999/xhtml"><b>v0.10:</b> Codex uses the <b>store</b> strategy<br/><b>bold</b> <span>plain</span> <i>italic</i></div></foreignObject></g></svg>
SVG
cp "$TMP/light/first-child-a.svg" "$TMP/light/first-child-b.svg"

cat > "$TMP/light/after-defs-a.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" style="background:#ffffff;background-color:#ffffff;color-scheme:light"><defs><style>.solid{fill:#fff}</style></defs><rect width="100%" height="100%" fill="#000" style="fill:#fff" data-kind="root"/><g><rect width="100%" height="100%" fill="#fff" style="fill:#fff" data-kind="nested"/><rect width="100%" height="100%" fill="#fff" stroke-width="0" data-kind="nested-stroke"/></g></svg>
SVG
cp "$TMP/light/after-defs-a.svg" "$TMP/light/after-defs-b.svg"

cat > "$TMP/light/rgb-reordered-a.svg" <<'SVG'
<svg style="background:#fff;background-color:#fff;color-scheme:light" height="100" width="100" xmlns="http://www.w3.org/2000/svg"><rect style="fill:rgb(255,255,255)" data-extra="kept" height="100%" width="100%" data-kind="root"/><g><rect style="fill:rgb(255,255,255)" height="100%" fill="rgb(255,255,255)" width="100%" data-kind="nested"/><rect stroke-width="0" height="100%" fill="rgb(255,255,255)" width="100%" data-kind="nested-stroke"/></g></svg>
SVG
cp "$TMP/light/rgb-reordered-a.svg" "$TMP/light/rgb-reordered-b.svg"

run_orders() {
  local name="$1"

  # Recommended: optimize light, generate dark, then optimize dark.
  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/light/$name-a.svg" >/dev/null
  "$REPO_ROOT/scripts/generate-dark-svgs.sh" "$REL/light/$name-a.svg" >/dev/null
  cp "$TMP/dark/$name-a.svg" "$TMP/$name-dark-optimized-first.svg"

  # Also supported: generate dark before optimizing either variant.
  "$REPO_ROOT/scripts/generate-dark-svgs.sh" "$REL/light/$name-b.svg" >/dev/null
  cp "$TMP/dark/$name-b.svg" "$TMP/$name-dark-generated-first.svg"

  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/dark/$name-a.svg" >/dev/null
  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/light/$name-b.svg" >/dev/null
  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/dark/$name-b.svg" >/dev/null

  cmp "$TMP/light/$name-a.svg" "$TMP/light/$name-b.svg"
  cmp "$TMP/dark/$name-a.svg" "$TMP/dark/$name-b.svg"
  ! grep -q 'background:#fff' "$TMP/dark/$name-a.svg"
  grep -q 'color-scheme:dark;filter:invert(1) hue-rotate(180deg)' "$TMP/dark/$name-a.svg"

  cp "$TMP/light/$name-a.svg" "$TMP/$name-light-before.svg"
  cp "$TMP/dark/$name-a.svg" "$TMP/$name-dark-before.svg"
  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/light/$name-a.svg" >/dev/null
  "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/dark/$name-a.svg" >/dev/null
  cmp "$TMP/$name-light-before.svg" "$TMP/light/$name-a.svg"
  cmp "$TMP/$name-dark-before.svg" "$TMP/dark/$name-a.svg"

  if [[ "$name" == first-child ]]; then
    grep -Fq '<b>v0.10:</b> Codex uses the <b>store</b> strategy' "$TMP/light/$name-a.svg"
    grep -Fq '<b>v0.10:</b> Codex uses the <b>store</b> strategy' "$TMP/dark/$name-a.svg"
    grep -Fq '<b>bold</b> <span>plain</span> <i>italic</i>' "$TMP/light/$name-a.svg"
    grep -Fq '<b>bold</b> <span>plain</span> <i>italic</i>' "$TMP/dark/$name-a.svg"
  fi
}

assert_white_fill() {
  local file="$1"
  local kind="$2"
  grep -Eq "<rect[^>]*fill=\"${WHITE}\"[^>]*data-kind=\"${kind}\"[^>]*/>|<rect[^>]*data-kind=\"${kind}\"[^>]*fill=\"${WHITE}\"[^>]*/>" "$file"
}

run_orders first-child
run_orders after-defs
run_orders rgb-reordered

for variant in optimized-first generated-first; do
  for name in first-child after-defs rgb-reordered; do
    file="$TMP/$name-dark-$variant.svg"
    grep -Eq '<rect[^>]*fill="transparent"[^>]*data-kind="root"[^>]*/>|<rect[^>]*data-kind="root"[^>]*fill="transparent"[^>]*/>' "$file"
    grep -Eq '<rect[^>]*fill="transparent"[^>]*style="fill:transparent"[^>]*/>|<rect[^>]*style="fill:transparent"[^>]*fill="transparent"[^>]*/>' "$file"
    if [[ "$variant" == generated-first ]]; then
      assert_white_fill "$file" nested
      assert_white_fill "$file" nested-stroke
      if [[ "$name" == first-child ]]; then
        assert_white_fill "$file" after-defs-decoy
      fi
      grep -Eq '<rect[^>]*stroke-width="0"[^>]*data-kind="nested-stroke"[^>]*/>|<rect[^>]*data-kind="nested-stroke"[^>]*stroke-width="0"[^>]*/>' "$file"
    fi
    grep -Eq "style=\"fill:${WHITE}\"" "$file"
    ! grep -Eq '<rect[^>]*data-kind="nested"[^>]*fill="transparent"|<rect[^>]*data-kind="nested-stroke"[^>]*fill="transparent"|<rect[^>]*data-kind="after-defs-decoy"[^>]*fill="transparent"' "$file"
    if [[ "$name" == rgb-reordered ]]; then
      grep -Eq '<rect[^>]*data-extra="kept"[^>]*/>' "$file"
    fi
  done

  grep -Eq '^<svg[^>]*><rect width="100%" height="100%" fill="transparent"' "$TMP/first-child-dark-$variant.svg"
  grep -Eq '</defs><rect[^>]*fill="transparent"' "$TMP/after-defs-dark-$variant.svg"
done

printf '<svg><rect></svg>\n' > "$TMP/light/broken.svg"
printf 'previous dark\n' > "$TMP/dark/broken.svg"
cp "$TMP/dark/broken.svg" "$TMP/broken-dark-before.svg"
if "$REPO_ROOT/scripts/generate-dark-svgs.sh" "$REL/light/broken.svg" >/dev/null 2>"$TMP/broken-error.log"; then
  echo 'Malformed light SVG unexpectedly succeeded' >&2
  exit 1
fi
cmp "$TMP/broken-dark-before.svg" "$TMP/dark/broken.svg"
test -z "$(find "$TMP/dark" -name '.broken.svg.*' -print)"
grep -Eq 'Error|error' "$TMP/broken-error.log"

for collision in literal hex decimal; do
  case "$collision" in
    literal) value=$(printf '\363\260\200\200') ;;
    hex) value='&#xF0000;' ;;
    decimal) value='&#983040;' ;;
  esac
  printf '<svg xmlns="http://www.w3.org/2000/svg"><text>%s</text></svg>\n' "$value" > "$TMP/light/collision-$collision.svg"
  printf 'previous dark\n' > "$TMP/dark/collision-$collision.svg"
  cp "$TMP/light/collision-$collision.svg" "$TMP/collision-$collision-light-before.svg"
  cp "$TMP/dark/collision-$collision.svg" "$TMP/collision-$collision-dark-before.svg"

  if "$REPO_ROOT/scripts/optimize-svgs.sh" "$REL/light/collision-$collision.svg" >/dev/null 2>"$TMP/collision-$collision-error.log"; then
    echo "Placeholder collision unexpectedly optimized: $collision" >&2
    exit 1
  fi
  cmp "$TMP/collision-$collision-light-before.svg" "$TMP/light/collision-$collision.svg"

  if "$REPO_ROOT/scripts/generate-dark-svgs.sh" "$REL/light/collision-$collision.svg" >/dev/null 2>>"$TMP/collision-$collision-error.log"; then
    echo "Placeholder collision unexpectedly generated dark SVG: $collision" >&2
    exit 1
  fi
  cmp "$TMP/collision-$collision-dark-before.svg" "$TMP/dark/collision-$collision.svg"
  test -z "$(find "$TMP/light" -name ".collision-$collision.svg.*" -print)"
  test -z "$(find "$TMP/dark" -name ".collision-$collision.svg.*" -print)"
  grep -Fq 'whitespace placeholder' "$TMP/collision-$collision-error.log"
done

printf 'PASS: both orders match; nested artwork and inline whitespace survive; failures preserve existing outputs\n'
