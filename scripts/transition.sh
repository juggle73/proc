#!/bin/bash
# proc — deterministic FSM transition helper.
# Rewrites .proc/state.env and the .proc/STATUS.md task row (phase, optional state) + the
# ACTIVE field in one step, so the two sources never drift. The model invokes this via
# Bash on every phase/state change instead of hand-editing both files.
#
# State dir resolution (the model's shell usually has neither plugin env var, so the
# bootstrap hook injects a fully-resolved command with PROC_STATE_DIR set):
#   $PROC_STATE_DIR  →  $CLAUDE_PROJECT_DIR/.proc  →  $PWD/.proc
#
# Usage:
#   transition.sh <task-id> <phase> [state]   # set a task's phase (+ optional state), make it ACTIVE
#   transition.sh --clear                     # clear ACTIVE (e.g. after done → back to dispatch)
set -euo pipefail

STATE_DIR="${PROC_STATE_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}/.proc}"
mkdir -p "$STATE_DIR"
STATE="$STATE_DIR/state.env"
STATUS="$STATE_DIR/STATUS.md"

write_state() { # $1=task $2=phase
	cat >"$STATE" <<EOF
# proc — machine state. The single source of truth for the hooks.
# Edited via the proc transition helper on FSM transitions. Values are single words, no spaces.
ACTIVE_TASK=$1
ACTIVE_PHASE=$2
EOF
}

# A transition targets an EXISTING task row (new rows, with their human-authored columns,
# are added by hand first — see dispatch.md). Uses the same id-trimming as the row update
# below so the check never diverges from it. Exit 0 = found.
row_exists() { # $1=task ; reads $STATUS
	awk -v task="$1" '
		BEGIN { FS="|" }
		/^\|/ { id=$2; gsub(/^[ \t]+|[ \t]+$/, "", id); if (id == task) { found=1; exit } }
		END { exit !found }
	' "$STATUS"
}

if [ "${1:-}" = "--clear" ]; then
	write_state "" ""
	[ -f "$STATUS" ] && awk '/^ACTIVE:/ { print "ACTIVE: (none)"; next } { print }' "$STATUS" >"$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
	echo "cleared ACTIVE"
	exit 0
fi

TASK="${1:?usage: transition.sh <task-id> <phase> [state] | --clear}"
PHASE="${2:?usage: transition.sh <task-id> <phase> [state] | --clear}"
STATE_COL="${3:-}"

# Atomic refuse: if the row is missing, change nothing (not state.env, not ACTIVE) and fail,
# rather than silently no-op the row update while flipping the active task.
if [ ! -f "$STATUS" ] || ! row_exists "$TASK"; then
	echo "transition.sh: no row for '$TASK' in $STATUS — add it to the registry first (dispatch.md: new rows are added by hand), then retry." >&2
	exit 1
fi

write_state "$TASK" "$PHASE"

# Update the matching table row by its id (field 2) and the ACTIVE header line.
if [ -f "$STATUS" ]; then
	awk -v task="$TASK" -v phase="$PHASE" -v st="$STATE_COL" '
		BEGIN { FS="|"; OFS="|" }
		/^ACTIVE:/ { print "ACTIVE: " task; next }
		/^\|/ {
			id=$2; gsub(/^[ \t]+|[ \t]+$/, "", id)
			if (id == task) {
				$4 = " " phase " "
				if (st != "") $5 = " " st " "
				print; next
			}
		}
		{ print }
	' "$STATUS" >"$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
fi

echo "t=$TASK phase=$PHASE${STATE_COL:+ state=$STATE_COL} (state dir: $STATE_DIR)"
