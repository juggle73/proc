#!/bin/bash
# proc — create a new task in one step: append its registry row to STATUS.md, scaffold
# tasks/<id>/task.md from a skeleton, then make it ACTIVE (phase intake) via transition.sh.
# This replaces the error-prone "hand-edit the row, then transition" dance and always
# satisfies transition.sh's row-exists guard.
#
# Usage: new-task.sh <id> "<title>"
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${PROC_STATE_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}/.proc}"
STATUS="$STATE_DIR/STATUS.md"

ID="${1:?usage: new-task.sh <id> \"<title>\"}"
TITLE="${2:?usage: new-task.sh <id> \"<title>\"}"

[ -f "$STATUS" ] || { echo "new-task.sh: no registry at $STATUS (start a session so the SessionStart hook seeds it)." >&2; exit 1; }

# Refuse a duplicate id (same trimming as the row update in transition.sh).
if awk -v id="$ID" 'BEGIN{FS="|"} /^\|/{x=$2; gsub(/^[ \t]+|[ \t]+$/,"",x); if(x==id){f=1; exit}} END{exit !f}' "$STATUS"; then
	echo "new-task.sh: row '$ID' already exists in $STATUS." >&2; exit 1
fi

# Append the row right after the last existing table row (last line starting with '|').
awk -v row="| $ID | $TITLE | intake | active | — |  |" '
	{ lines[NR]=$0; if ($0 ~ /^\|/) last=NR }
	END { for (i=1;i<=NR;i++){ print lines[i]; if (i==last) print row } }
' "$STATUS" > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"

# Scaffold the per-task detail file (the bootstrap points the model here on demand).
mkdir -p "$STATE_DIR/tasks/$ID"
TF="$STATE_DIR/tasks/$ID/task.md"
if [ ! -f "$TF" ]; then
	cat >"$TF" <<EOF
# $ID — $TITLE

## What
(goal, context — fill in during intake)

## Definition of done
(what proves this task complete)

## Notes / log
- intake: created
EOF
fi

# Flip ACTIVE + state.env + the row's phase/state via the single source of truth.
PROC_STATE_DIR="$STATE_DIR" "$SCRIPT_DIR/transition.sh" "$ID" intake active >/dev/null

echo "created $ID (phase intake, active) — detail: $TF"
