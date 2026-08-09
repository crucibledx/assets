# GIF 3: "Power User" — advanced source options + merge strategies
#
# Story: A dev adds the monorepo example branch as a source with
# fine-grained control (subdirectory, layout, include/exclude), configures
# merge strategies for multi-source setups, previews conflicts with
# dry-run, and verifies with health.
# Accent: simple by default, powerful when you need it.
#
# Features showcased (from e2e test coverage + v0.6.9–0.6.13 DX):
#   - Source layouts: auto, canonical, pre-structured (v0.6.9)
#   - Include/exclude glob filters (v0.6.8)
#   - forge source list with advanced options (v0.6.13)
#   - Sync settings wizard: conflict strategies, backup, keep-local (v0.6.10)
#   - forge config show dashboard (v0.6.12)
#   - forge status with sync strategy context (v0.6.13)
#   - Dry-run preview with conflict info
#   - Backup (.bak) on overwrite + stale file cleanup
#
# Prerequisites:
#   - An existing .crucible/forge.config.yaml with one source
#   - VHS installed: brew install charmbracelet/tap/vhs
#
# Run: docs/gifs/generate.sh 03-power-user

Output docs/gifs/03-power-user-{{VARIANT}}.gif

Set Shell zsh
Set Theme "{{THEME}}"
Set FontFamily "Menlo"
Set FontSize 18
Set Width 1200
Set Height 650
Set Padding 20
Set TypingSpeed 60ms
Set CursorBlink false

# --- Setup: isolated temp project with existing config (hidden) ---

Hide
Type@0ms "setopt INTERACTIVE_COMMENTS && export PROJECT_ROOT=$(pwd) && export DEMO=$(mktemp -d) && cd $DEMO && mkdir -p .claude/skills .cursor/rules .crucible"
Enter
Sleep 300ms
Type@0ms "cp $PROJECT_ROOT/docs/gifs/fixtures/simple-config.yaml .crucible/forge.config.yaml"
Enter
Sleep 300ms
# Run initial sync
Type@0ms "forge sync && clear"
Enter
Sleep 5000ms
Show

# =============================================
# Part 1: Add source with advanced options
# =============================================

# --- Scene 1: Add source with advanced options ---

Type "forge source add"
Sleep 500ms
Enter
Sleep 1000ms

# --- Scene 2: Source name ---

Type "frontend-team"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 3: Source type -> Git ---

# "Git repository" is the first option, already highlighted
Enter
Sleep 500ms

# --- Scene 4: Git URL ---

Type "https://github.com/crucibledx/forge-skills-starter.git"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 4b: Branch -> example/monorepo ---

Type "example/monorepo"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 4c: Subdirectory -> frontend ---

Type "frontend"
Sleep 300ms
Enter
Sleep 1200ms

# Verification spinner -> verified

# --- Scene 5: "Configure advanced source options?" -> Yes ---

Sleep 300ms
Left
Sleep 200ms
Enter
Sleep 600ms

# --- Scene 6: Source layout selection ---

# Shows:
#   ◆  Source layout:
#   │  ● Auto (detect from source — handles both canonical and pre-structured)
#   │  ○ Canonical only (skills/, rules/, workflows/)
#   │  ○ Pre-structured only (.claude/, .cursor/, etc.)

Sleep 400ms
Down
Sleep 400ms
Enter
Sleep 500ms

# --- Scene 7: Include patterns ---

Sleep 200ms
Type "skills/**, rules/react-*.md"
Sleep 500ms
Enter
Sleep 500ms

# --- Scene 8: Exclude patterns ---

Sleep 200ms
Type "**/draft-*, **/WIP-*"
Sleep 500ms
Enter
Sleep 500ms

# --- Scene 9: Map prefix -> skip ---

Sleep 200ms
Enter
Sleep 800ms

# "Source "frontend-team" added." ✓

Sleep 500ms

# --- Scene 10: Show sources with advanced options (v0.6.13) ---

Type "forge source list"
Sleep 400ms
Enter
Sleep 2000ms

# Shows:
#   default [git]
#     url: https://github.com/crucibledx/forge-skills-starter.git
#     branch: main
#     0 synced files
#   frontend-team [git]
#     url: https://github.com/crucibledx/forge-skills-starter.git
#     branch: example/monorepo
#     subdirectory: frontend
#     layout: canonical
#     include: skills/**, rules/react-*.md
#     exclude: **/draft-*, **/WIP-*
#     0 synced files

Sleep 2000ms

# =============================================
# Part 2: Configure merge strategies via wizard
# =============================================

# --- Scene 11: Open forge config to change sync settings ---

Type "forge config"
Sleep 400ms
Enter
Sleep 1200ms

# Shows:
#   ◆  What would you like to change?
#   │  ○ Assistants
#   │  ○ Scheduler
#   │  ○ Sources
#   │  ● Sync settings        <-- navigate here

Sleep 200ms
Down
Sleep 100ms
Down
Sleep 100ms
Down
Sleep 300ms
Enter
Sleep 600ms

# --- Scene 12: Source conflict strategy ---
# v0.6.10: full sync settings wizard

# Shows:
#   ◆  Source conflict strategy:
#   │  ● Last wins (latest source overrides earlier ones) (current)
#   │  ○ First wins (first source takes priority)
#   │  ○ Error (abort on conflict between sources)

# Select "First wins" — want the original source to take priority
Sleep 300ms
Down
Sleep 500ms
Enter
Sleep 600ms

# --- Scene 13: Local conflict strategy ---

# Shows:
#   ◆  Local conflict strategy:
#   │  ● Remote wins (source always overwrites local edits) (current)
#   │  ○ Local wins (keep local edits, skip remote)
#   │  ○ Error (abort on conflict with local changes)

# Keep "Remote wins" (default, already selected)
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 14: Backup -> Yes (default) ---

Sleep 300ms
Enter
Sleep 500ms

# --- Scene 15: Keep local -> No (change from default) ---
# "Keep locally-created files that are not in any source?"

# Default is Yes, arrow to No
Sleep 200ms
Right
Sleep 300ms
Enter
Sleep 800ms

# --- Scene 16: "Change something else?" -> No ---

Sleep 200ms
Enter
Sleep 800ms

# "Configuration saved." ✓
Sleep 500ms

# --- Scene 17: Show config dashboard (v0.6.12) ---

Type "forge config show"
Sleep 400ms
Enter
Sleep 2500ms

# Shows:
#   ┌─────────────────────────┐
#   │  Current Configuration  │
#   └─────────────────────────┘
#
#   Sources
#     default [git]
#       url: https://github.com/crucibledx/forge-skills-starter.git
#     frontend-team [git]
#       url: https://github.com/crucibledx/forge-skills-starter.git
#       branch: example/monorepo
#       subdirectory: frontend
#       layout: canonical
#       include: skills/**, rules/react-*.md
#       exclude: **/draft-*, **/WIP-*
#
#   Sync Settings
#     source conflict: first-wins            <-- changed!
#     local conflict: remote-wins (default)
#     backup: on (default)
#     keep local: off                        <-- changed!

Sleep 3000ms

# =============================================
# Part 3: Dry-run preview with conflict info
# =============================================

# --- Scene 18: Dry-run to preview ---

Type "forge sync --dry-run"
Sleep 400ms
Enter
Sleep 2500ms

# Shows preview:
#   DRY RUN — no files will be written
#
#   Source "default":
#     + .claude/skills/deploy.md
#     + .claude/skills/testing.md
#     = .claude/skills/review.md           (no change)
#     + .cursor/rules/deploy.mdc
#
#   Source "frontend-team" (canonical, include+exclude):
#     + .claude/skills/review-frontend/SKILL.md
#     + .cursor/rules/review-frontend/SKILL.mdc
#     ! .claude/skills/deploy.md           (conflict: kept from "default" — first-wins)
#
#   7 files would be synced, 1 conflict resolved (first-wins)
#   1 stale file would be removed (keep_local: false)

Sleep 3000ms

# --- Scene 19: Actual sync ---

Type "forge sync"
Sleep 400ms
Enter
Sleep 2500ms

# Shows:
#   ✓ Synced 6 files
#   ⚠ 1 source conflict resolved (first-wins: "default" kept)
#   📄 1 backup created (.bak)
#   🗑  1 stale file removed

Sleep 1500ms

# --- Scene 20: Status with sync strategy context (v0.6.13) ---

Type "forge status"
Sleep 400ms
Enter
Sleep 2000ms

# Shows (v0.6.13 — now includes strategy settings):
#   Last sync: just now
#   Source conflict: first-wins | Local conflict: remote-wins | Backup: on
#
#   Claude Code:
#   ✓ .claude/skills/deploy.md                (in sync)
#   ✓ .claude/skills/review-frontend/SKILL.md     (in sync)
#   Cursor:
#   ✓ .cursor/rules/deploy.mdc                    (in sync)
#   ✓ .cursor/rules/review-frontend/SKILL.mdc     (in sync)
#
#   All files in sync.

Sleep 100ms

# --- Outro ---

Type "# Subdirs, filters, merge strategies, backups, cleanup —"
Sleep 50ms
Enter
Type "# all configurable. Simple by default, powerful when you need it."
Sleep 2500ms

# --- Teardown: clean up temp project (hidden) ---

Hide
Type "rm -rf $DEMO"
Enter
Sleep 300ms
Show
