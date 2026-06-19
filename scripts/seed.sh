#!/bin/bash
# proc — SessionStart hook. On the first run inside a project, scaffolds the mutable state
# dir ($CLAUDE_PROJECT_DIR/.proc) from the shipped template so the registry exists. Idempotent:
# if .proc/STATUS.md already exists, it does nothing (never clobbers real task state).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="$PROJECT_DIR/.proc"

[ -f "$STATE_DIR/STATUS.md" ] && exit 0  # already initialised

mkdir -p "$STATE_DIR/tasks"  # per-task detail lives in tasks/<id>/task.md
cp "$PLUGIN_ROOT/templates/STATUS.md" "$STATE_DIR/STATUS.md"
cat >"$STATE_DIR/state.env" <<'EOF'
# proc — machine state. The single source of truth for the hooks.
# Edited via the proc transition helper on FSM transitions. Values are single words, no spaces.
ACTIVE_TASK=
ACTIVE_PHASE=
EOF
exit 0
