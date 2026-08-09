# @crucibledx/assets

Centralized visual assets for all Crucible products. Single source of truth — edit here, reference everywhere.

## Structure

```
<category>/
  <asset-type>/
    source-file.drawio          ← editable source
    source-file.tape            ← editable source
    fixtures/                   ← test data (for demos)
    light/
      output-file.svg           ← light-theme output (primary)
      output-file.gif           ← light-theme output
    dark/
      output-file.svg           ← dark-theme output (generated)
      output-file.gif           ← dark-theme output
```

### Categories

| Category    | Description                                                   |
|-------------|---------------------------------------------------------------|
| `forge/`    | Forge CLI — AI dev environment tool                           |
| `platform/` | AI resource lifecycle platform (skills, specimens, resources) |
| `ember/`    | Ember — AI observability and analytics                        |
| `crucible/` | Crucible-wide assets (ecosystem, product phases, etc.)        |
| `branding/` | Logos, wordmarks, icons, color references                     |

### Asset Types

| Type        | Sources   | Outputs        | Description                                                         |
|-------------|-----------|----------------|---------------------------------------------------------------------|
| `diagrams/` | `.drawio` | `.svg`, `.png` | Architecture, flow, and system diagrams                             |
| `demos/`    | `.tape`   | `.gif`         | Terminal recordings via [VHS](https://github.com/charmbracelet/vhs) |

### Theme Folders

All diagram and demo outputs live in `light/` and `dark/` subfolders. Light variants are the primary source — dark SVGs are **generated** from them (see below).

## Referencing Assets

From other repos, use raw GitHub URLs:

```markdown
![diagram](https://github.com/crucibledx/assets/raw/main/platform/diagrams/light/platform-flow.svg)
```

For dark/light theme switching in GitHub READMEs, use `<picture>`:

```html

<picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/crucibledx/assets/raw/main/platform/diagrams/dark/platform-flow.svg">
    <img alt="Platform Flow" src="https://github.com/crucibledx/assets/raw/main/platform/diagrams/light/platform-flow.svg">
</picture>
```

For sites with built-in CSS inversion (like the Crucible website), reference `light/` only — the site handles dark mode via CSS `filter: invert(1) hue-rotate(180deg)`.

For immutable references, use a tag:

```markdown
![diagram](https://github.com/crucibledx/assets/raw/v3/platform/diagrams/light/platform-flow.svg)
```

## Versioning

Simple incrementing tags (`v1`, `v2`, `v3`, ...) — no semver, no changelog. Git log is the changelog.

```bash
git tag v1
git push origin main --tags
```

Tags exist primarily for **immutable reference URLs** in other repos.

## Exporting Assets

### Demos (terminal recordings)

Use the generation script — it handles `{{THEME}}`/`{{VARIANT}}` placeholders and places GIFs into theme subfolders automatically:

```bash
scripts/generate-demos.sh                                      # all tapes, both themes
scripts/generate-demos.sh forge                                 # forge category only
scripts/generate-demos.sh --dark forge/demos/01-set-and-forget.tape  # single tape, dark only
scripts/generate-demos.sh --changed                             # only changed .tape files
```

### Diagrams

**Step 1 — Export light SVGs from draw.io:**

Use the script for batch export:

```bash
scripts/export-diagrams.sh                                      # all diagrams
scripts/export-diagrams.sh platform                             # platform category only
scripts/export-diagrams.sh platform/diagrams/flow.drawio        # single file
scripts/export-diagrams.sh --format png --scale 2               # PNG at 2x
```

Or export manually through draw.io desktop:

1. Open the `.drawio` file in draw.io desktop
2. **File → Export As → SVG**
3. Settings:
    - **Zoom**: 300% (for sharper output)
    - **Appearance**: `Light` — **always export light only**
    - **Include a copy of my diagram**: ❌ uncheck (keeps the file clean)
    - **Embed Images**: ❌ uncheck
    - **Embed Fonts**: ❌ uncheck (smaller output size)
4. Save to the `light/` folder (e.g., `platform/diagrams/light/flow.svg`)

**Step 2 — Generate dark variants:**

Dark SVGs are generated programmatically from light SVGs by injecting `filter: invert(1) hue-rotate(180deg)` — the same transform used by the Crucible website CSS. Never export dark theme from draw.io (it looks ugly).

```bash
scripts/generate-dark-svgs.sh                                   # all light SVGs → dark/
scripts/generate-dark-svgs.sh platform                          # platform category only
scripts/generate-dark-svgs.sh platform/diagrams/light/flow.svg  # single file
```

### SVG Optimization

After exporting, **always optimize SVGs** — SVGO typically reduces size 5-10x:

```bash
scripts/optimize-svgs.sh                                        # all SVGs
scripts/optimize-svgs.sh forge                                  # forge category only
scripts/optimize-svgs.sh forge/diagrams/dark/flow.svg           # single file
scripts/optimize-svgs.sh --dry-run                              # preview savings
scripts/optimize-svgs.sh --changed                              # only changed .svg files
```

## Adding Assets

**Convention over configuration** — just drop your source file in the right place:

1. Pick the category (`forge/`, `platform/`, `ember/`, `crucible/`, `branding/`)
2. Pick the asset type (`diagrams/`, `demos/`)
3. Drop the source file (`.drawio`, `.tape`)
4. Export/generate outputs (script or manual, see above)
5. Optimize SVGs: `scripts/optimize-svgs.sh --changed`
6. Commit both source and outputs

## Git LFS

Heavy binary outputs (`.gif`, `.png`, `.jpg`, `.mp4`) are tracked via Git LFS. This is configured in `.gitattributes` and works transparently — just commit as usual.

## Prerequisites

- [draw.io desktop](https://github.com/jgraph/drawio-desktop/releases) — for diagram exports
- [VHS](https://github.com/charmbracelet/vhs) — for demo GIF generation (`brew install charmbracelet/tap/vhs`)
- [SVGO](https://github.com/svg/svgo) — for SVG optimization (`npm i -g svgo` or use via `bunx svgo`)
- [Git LFS](https://git-lfs.github.com/) — for large file storage (`brew install git-lfs`)

## License

[MIT](LICENSE)
