#!/usr/bin/env bash
# sync-skills.sh — Pull updates from GitHub and sync to ~/.claude/skills/
# Usage: bash ~/personal-agentic-skills/sync.sh
# Run this on any device to get the latest skills.

set -e

REPO_DIR="$HOME/personal-agentic-skills"
SKILLS_DIR="$HOME/.claude/skills"

echo "Pulling latest from GitHub..."
cd "$REPO_DIR" && git pull

echo "Syncing skills to $SKILLS_DIR ..."
for skill_dir in "$REPO_DIR/skills/"/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$SKILLS_DIR/$skill_name"
  cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
  echo "  ✓ $skill_name"
done

echo "Done."
