# GIF 1: "Set & Forget" — forge init with scheduler
#
# Story: A dev runs forge init for the first time.
# The wizard detects their AI tools, they add a git source,
# enable automatic scheduling, and never think about forge again.
# The accent is: run once, forget forever.
#
# Prerequisites:
#   - A test project directory with .claude/ and .cursor/ folders (detected)
#   - No existing .crucible/forge.config.yaml
#   - VHS installed: brew install charmbracelet/tap/vhs
#
# Run: docs/gifs/generate.sh 01-set-and-forget

Output docs/gifs/01-set-and-forget-{{VARIANT}}.gif

Set Shell zsh
Set Theme "{{THEME}}"
Set FontFamily "Menlo"
Set FontSize 18
Set Width 1200
Set Height 600
Set Padding 20
Set TypingSpeed 60ms
Set CursorBlink false

# --- Setup: isolated temp project (hidden from recording) ---

Hide
Type@0ms "setopt INTERACTIVE_COMMENTS && export DEMO=$(mktemp -d) && cd $DEMO && mkdir -p .claude .cursor/rules && touch .claude/settings.json .cursor/rules/ignore-rule.md && clear"
Enter
Sleep 500ms
Show

# --- Scene 1: Run forge init ---

Type "forge init"
Sleep 500ms
Enter
Sleep 1500ms

# Scanning spinner appears, then detection results render.
# @clack/prompts shows:
#   ◇  Scan complete
#   ℹ  Detected:
#     claude-code ✓   cursor ✓   windsurf ✗   copilot ✗   cline ✗
#
#   ◆  Select assistants to enable:
#   │  ◼ Claude Code (detected)
#   │  ◼ Cursor (detected)
#   │  ◻ Windsurf
#   │  ◻ GitHub Copilot
#   │  ◻ Cline

# --- Scene 2: Confirm detected assistants (pre-selected) ---

Sleep 500ms
# Claude Code and Cursor are pre-selected, just press Enter to confirm
Enter
Sleep 800ms

# --- Scene 3: "Add a shared skills source?" → Yes ---

# Confirm defaults to Yes
Sleep 200ms
Enter
Sleep 600ms

# --- Scene 4: Source name → accept default "default" ---

Sleep 200ms
Enter
Sleep 500ms

# --- Scene 5: Source type → select Git ---

# "Git repository" is the first option, already highlighted
Sleep 200ms
Enter
Sleep 500ms

# --- Scene 6: Enter git URL ---

Type "https://github.com/crucibledx/forge-skills-starter.git"
Sleep 300ms
Enter
Sleep 500ms

# --- Scene 7: Branch → accept default "main" ---

Sleep 300ms
Enter
Sleep 500ms

# --- Scene 8: Subdirectory → skip (empty) ---

Sleep 200ms
Enter
Sleep 1000ms

# Verification spinner: "Verifying source is reachable..."
# → "Source verified" ✓

# --- Scene 9: "Configure advanced source options?" → No ---

Sleep 500ms
# Default is No
Enter
Sleep 600ms

# --- Scene 10: "Add another source?" → No ---

# Default is No
Sleep 200ms
Enter
Sleep 600ms

# --- Scene 11: "Set up automatic sync schedule?" → Yes ---

Sleep 300ms
# Default is No, so arrow to Yes
Left
Sleep 200ms
Enter
Sleep 500ms

# --- Scene 12: Enter cron expression ---

Sleep 200ms
Type "0 9 * * 1-5"
Sleep 300ms
Enter
Sleep 500ms

# Shows: "→ At 09:00 on every day-of-week from Monday through Friday"

# --- Scene 13: "Use this schedule?" → Yes ---

Sleep 200ms
Enter
Sleep 800ms

# --- Scene 14: "Configure sync settings?" → No (defaults are fine) ---
# v0.6.10: sync settings wizard gate appears here

Sleep 200ms
Enter
Sleep 600ms

# --- Scene 14b: "Enable anonymous telemetry?" → No ---

Sleep 200ms
Enter
Sleep 600ms

# Config written:
#   ✓ Config written to .crucible/forge.config.yaml

# --- Scene 15: "Install the scheduler now?" → Yes ---

Sleep 300ms
Enter
Sleep 1000ms

# "Scheduler installed." ✓

# --- Scene 16: "Run forge sync now?" → Yes ---

Sleep 300ms
Enter
Sleep 1000ms

# Sync runs, shows files being placed:
#   ✓ Synced 8 files from "default"
#     claude-code: 4 files
#     cursor: 4 files (.md → .mdc)

Sleep 1000ms

# --- Scene 17: Show the config dashboard (v0.6.12) ---
# The punchline: everything visible in one glance.

Sleep 500ms
Type "forge config show"
Sleep 200ms
Enter
Sleep 1000ms

# Shows:
#   ┌─────────────────────────┐
#   │  Current Configuration  │
#   └─────────────────────────┘
#
#   Project
#     name: my-project
#
#   Assistants
#     ✓ Claude Code
#     ✓ Cursor
#
#   Sources
#     default [git]
#       url: https://github.com/crucibledx/forge-skills-starter.git
#       branch: main
#
#   Sync Settings
#     source conflict: last-wins (default)
#     local conflict: remote-wins (default)
#     backup: on (default)
#     keep local: on (default)
#
#   Schedule
#     cron: 0 9 * * 1-5
#     description: At 09:00 on every day-of-week from Monday through Friday

Sleep 100ms

# --- Outro ---

Type "# That's it. Forge syncs every weekday at 9am."
Sleep 50ms
Enter
Type "# Edit skills in git -> they appear everywhere."
Sleep 50ms
Enter
Type "# Set & forget."
Sleep 1000ms

# --- Teardown: clean up temp project (hidden) ---

Hide
Type "rm -rf $DEMO"
Enter
Sleep 300ms
Show
