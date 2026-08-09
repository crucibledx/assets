# GIF 2: "Easy Updates" — drift detection + interactive config
#
# Story: A dev checks status, sees drift (locally modified files).
# They add a second source from the monorepo example branch,
# sync both, then verify — all in sync. No YAML editing, no guessing.
# Accent: status shows problems, wizard fixes them, status confirms.
#
# Prerequisites:
#   - An existing .crucible/forge.config.yaml with one source, already synced
#   - A locally modified file (to show drift)
#   - VHS installed: brew install charmbracelet/tap/vhs
#
# Run: scripts/generate-demos.sh forge/demos/02-easy-updates.tape

Output forge/demos/{{VARIANT}}/02-easy-updates.gif

Set Shell zsh
Set Theme "{{THEME}}"
Set FontFamily "Menlo"
Set FontSize 18
Set Width 1200
Set Height 650
Set Padding 20
Set TypingSpeed 60ms
Set CursorBlink false

# --- Setup: isolated temp project with existing config + drift (hidden) ---

Hide
Type@0ms "setopt INTERACTIVE_COMMENTS && export PROJECT_ROOT=$(pwd) && export DEMO=$(mktemp -d) && cd $DEMO && mkdir -p .claude/skills .cursor/rules .crucible"
Enter
Sleep 300ms
Type@0ms "cp $PROJECT_ROOT/docs/gifs/fixtures/simple-config.yaml .crucible/forge.config.yaml"
Enter
Sleep 300ms
# Run initial sync, then modify a synced file to create drift
Type@0ms "forge sync && echo '# Modified locally' >> .claude/skills/detect-stack/README.md && clear"
Enter
Sleep 5000ms
Show

# --- Scene 1: Check status — drift detected ---

Type "forge status"
Sleep 500ms
Enter
Sleep 1500ms

# Shows:
#   Forge — Sync Status
#   
#   .claude/skills/deploy.md   locally modified
#   .cursor/rules/deploy.mdc   in sync
#
#   1 file(s) modified locally, 0 deleted

Sleep 1500ms

# --- Scene 2: Config show — see what's configured (v0.6.12) ---

Type "forge config show"
Sleep 400ms
Enter
Sleep 2000ms

# Shows:
#   ┌─────────────────────────┐
#   │  Current Configuration  │
#   └─────────────────────────┘
#   Assistants
#     ✓ Claude Code
#     ✓ Cursor
#   Sources
#     default [git]
#       url: https://github.com/crucibledx/forge-skills-starter.git
#   Sync Settings
#     source conflict: last-wins (default)
#     ...
#   Schedule
#     cron: 0 9 * * 1-5
#     description: At 09:00 on every day-of-week from Monday through Friday

Sleep 1500ms

# --- Scene 3: Run forge config to add a second source ---

Type "forge config"
Sleep 500ms
Enter
Sleep 1200ms

# Shows:
# ┌  Forge — Edit Configuration
# │
# ◆  What would you like to change?
# │  ● Assistants (2 enabled)
# │  ○ Scheduler
# │  ○ Sources
# │  ○ Sync settings
# │  ○ Telemetry
# └

# --- Scene 4: Select "Sources" ---

Down
Sleep 200ms
Down
Sleep 500ms
Enter
Sleep 600ms

# --- Scene 5: Add a new source ---

Sleep 200ms
Enter
Sleep 500ms

# --- Scene 6: Source name ---

Type "backend-team"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 7: Source type -> Git ---

Enter
Sleep 500ms

# --- Scene 8: Git URL (same repo, different branch) ---

Type "https://github.com/crucibledx/forge-skills-starter.git"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 9: Branch -> example/monorepo ---

Type "example/monorepo"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 10: Subdirectory -> backend ---

Type "backend"
Sleep 300ms
Enter
Sleep 2000ms

# Verification spinner -> verified

# --- Scene 11: Advanced options -> No ---

Sleep 200ms
Enter
Sleep 800ms

# "Source "backend-team" added." ✓

# Show after new source added:
# ◆  What would you like to do?
# │  ● Add a new source
# │  ○ Done
# │  ○ Edit an existing source
# │  ○ Remove a source
# └

# --- Scene 12: Back to source actions -> Done ---

Sleep 400ms
Down
Sleep 300ms
Enter
Sleep 600ms

# --- Scene 13: "Change something else?" -> No ---

Enter
Sleep 800ms

# "Configuration saved." ✓

# --- Scene 14: Sync to pull both sources ---

Sleep 500ms
Type "forge sync"
Sleep 400ms
Enter
Sleep 2500ms

# Shows both sources syncing:
#   ✓ Synced 8 files from "default"
#   ✓ Synced 5 files from "backend-team"
#     claude-code: 7 files, cursor: 6 files
# Also: locally modified file backed up (.bak) and overwritten

Sleep 1500ms

# --- Scene 15: Verify — everything in sync ---

Type "forge status"
Sleep 400ms
Enter
Sleep 1500ms

# Shows:
#   All files in sync.

Sleep 1500ms

# --- Scene 16: Config show confirms new source ---

Type "forge config show"
Sleep 400ms
Enter
Sleep 2000ms

# Shows:
#   Sources
#     default [git]
#       url: https://github.com/crucibledx/forge-skills-starter.git
#     backend-team [git]              <-- new!
#       url: https://github.com/crucibledx/forge-skills-starter.git
#       branch: example/monorepo
#       subdirectory: backend

Sleep 100ms

# --- Outro ---

Type "# Drift detected -> wizard fix -> all in sync. Zero YAML editing."
Sleep 2500ms

# --- Teardown: clean up temp project (hidden) ---

Hide
Type "rm -rf $DEMO"
Enter
Sleep 300ms
Show
