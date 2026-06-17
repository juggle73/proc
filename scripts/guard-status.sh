#!/bin/bash
# proc — Stop hook. Guards the invariant "status is always valid": it won't let the
# turn end if state.env holds a phase without a regulation file. The model chooses the
# transition; the hook only validates the result. An empty phase is legitimate (= dispatch).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
REG_DIR="$PLUGIN_ROOT/regulations"
STATE="$PROJECT_DIR/.proc/state.env"

INPUT=$(cat)
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0  # avoid loops

ACTIVE_PHASE=""; [ -f "$STATE" ] && . "$STATE"
# empty phase = dispatch (legitimate); otherwise a regulation file must exist
if [ -n "${ACTIVE_PHASE:-}" ] && [ ! -f "$REG_DIR/${ACTIVE_PHASE}.md" ]; then
  jq -n --arg p "$ACTIVE_PHASE" '{decision:"block",reason:("state.env: ACTIVE_PHASE=\($p) is invalid — no regulations/\($p).md. Set a valid phase (intake/plan/implement/review/fix/test/done) or clear it for dispatch, then finish.")}'
fi
exit 0
