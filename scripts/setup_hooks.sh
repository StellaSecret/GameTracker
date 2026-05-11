#!/usr/bin/env bash
# scripts/setup_hooks.sh
#
# Run once after cloning the repo:
#   bash scripts/setup_hooks.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK_SRC="$REPO_ROOT/.githooks/pre-commit"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

echo "Installing pre-commit hook..."

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"

echo "✓ Done. The hook will run on every 'git commit'."
echo "  To skip it in an emergency: git commit --no-verify"
