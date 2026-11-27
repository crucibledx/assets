# Loop contract

Read by the Crucible loop agents (`implement-spec`, `verifier`, `spec-writer`). Keep it accurate.

- **Install:** `git lfs install` (GIF, PNG, JPG, WebP, and MP4 files are stored in Git LFS).
- **Layout:** one folder per product (`forge/`, `ember/`, `crucible/`, `factory-loop/`, `platform/`,
  `branding/`). Light variants are the source; dark variants are generated.
- **Checks** (before a PR is ready). Every tool check here runs **locally only**: the hosted review runner has
  none of `svgo`, draw.io, `vhs` or assetkit, so the reviewer states that the relevant check is local-only
  instead of guessing or flagging it as missing:
  - after changing a light SVG, run `scripts/generate-dark-svgs.sh` and commit the dark result;
  - after changing a `.drawio`, run `scripts/export-diagrams.sh` (needs draw.io) and commit the exports;
  - after changing a `.tape`, run `scripts/generate-demos.sh` (needs `vhs`) and commit both light and dark GIFs;
  - `scripts/optimize-svgs.sh` (needs `svgo`) leaves no diff;
  - assetkit render and visual checks run locally too: assetkit is an internal tool and is not available in CI;
  - every new binary is tracked by LFS (`git lfs ls-files` lists it).
- **Commit style:** `diagrams: ...`, `docs: ...`, `feat: ...`, matching `git log`.
- **Consumers:** web and project READMEs link raw GitHub URLs; renaming or moving a file breaks them. Search the org
  (`gh search code --owner crucibledx <filename>`) before moving anything.
- **Release:** `v1`, `v2` tags, manual.
