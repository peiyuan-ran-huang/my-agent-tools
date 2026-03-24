#!/usr/bin/env bash
# sync-skills.sh — Pull updates from GitHub and sync to ~/.claude/skills/
# Usage: bash ~/my-agent-skills/sync.sh
# Run this on any device to get the latest skills.

set -e
shopt -s nullglob

REPO_DIR="$HOME/my-agent-skills"
SKILLS_DIR="$HOME/.claude/skills"

echo "Pulling latest from GitHub..."
cd "$REPO_DIR" && git pull

echo "Syncing skills to $SKILLS_DIR ..."
for skill_dir in "$REPO_DIR/skills/"/*/; do
  skill_name=$(basename "$skill_dir")
  dest="$SKILLS_DIR/$skill_name"

  # No-clobber list: these user-extensible files are preserved during sync.
  # pitfalls.md, examples.md, and verification-issue-ledger.md are protected.
  # All other files (SKILL.md, references/*, etc.) are overwritten by the
  # repo version. If you customise other files locally, back them up
  # before running sync.sh.
  pitfalls_backup=""
  examples_backup=""
  ledger_backup=""
  if [[ -f "$dest/pitfalls.md" ]]; then
    pitfalls_backup=$(mktemp)
    cp "$dest/pitfalls.md" "$pitfalls_backup"
  fi
  if [[ -f "$dest/examples.md" ]]; then
    examples_backup=$(mktemp)
    cp "$dest/examples.md" "$examples_backup"
  fi
  if [[ -f "$dest/verification-issue-ledger.md" ]]; then
    ledger_backup=$(mktemp)
    cp "$dest/verification-issue-ledger.md" "$ledger_backup"
  fi

  # Trap lifecycle: defined per-iteration so $dest and *_backup variables
  # still hold their current-iteration values when the trap fires. Cleared
  # at the end of each iteration (trap - EXIT INT TERM) so the previous
  # skill's cleanup function does not fire when the next skill is processed.
  cleanup() {
    [[ -n "$pitfalls_backup" && -f "$pitfalls_backup" ]] && mv "$pitfalls_backup" "$dest/pitfalls.md" 2>/dev/null || true
    [[ -n "$examples_backup" && -f "$examples_backup" ]] && mv "$examples_backup" "$dest/examples.md" 2>/dev/null || true
    [[ -n "$ledger_backup" && -f "$ledger_backup" ]] && mv "$ledger_backup" "$dest/verification-issue-ledger.md" 2>/dev/null || true
  }
  trap cleanup EXIT INT TERM

  # Full recursive copy (handles flat and nested skill layouts)
  mkdir -p "$dest"
  cp -r "$skill_dir/." "$dest/"

  # Restore user-maintained files (overrides repo templates just copied)
  if [[ -n "$pitfalls_backup" ]]; then
    mv "$pitfalls_backup" "$dest/pitfalls.md"
    echo "  ⏭ $skill_name/pitfalls.md (user file preserved)"
  fi
  if [[ -n "$examples_backup" ]]; then
    mv "$examples_backup" "$dest/examples.md"
    echo "  ⏭ $skill_name/examples.md (user file preserved)"
  fi
  if [[ -n "$ledger_backup" ]]; then
    mv "$ledger_backup" "$dest/verification-issue-ledger.md"
    echo "  ⏭ $skill_name/verification-issue-ledger.md (user file preserved)"
  fi

  trap - EXIT INT TERM  # Clear trap after successful restore

  echo "  ✓ $skill_name"
done

echo "Done."
