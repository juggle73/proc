#!/bin/bash
# proc — autonomous-cycle state helper.
# /proc:cycle turns a task into a self-driving loop: implement → review (agent panel) → fix → …
# → test → done, without stopping for the user at each phase (after the plan is approved). The
# loop is driven by the Stop hook (guard-status.sh), which keeps re-invoking the model while a
# cycle is active and the task has not reached `done`. This script owns the marker file
# .proc/cycle.env; the model calls it via Bash to arm/stop a cycle, the hook to tick it.
#
# cycle.env fields:
#   CYCLE_TASK   the task id the cycle is bound to (empty / file absent = no cycle)
#   CYCLE_MAX    review→fix rounds the model may run before escalating (semantic, model-enforced)
#   CYCLE_TICKS  Stop-hook continuations so far (hard backstop, hook-maintained)
#
# State dir resolution matches transition.sh (the model's shell usually has neither plugin env
# var, so the bootstrap hook injects a fully-resolved command with PROC_STATE_DIR set):
#   $PROC_STATE_DIR → $CLAUDE_PROJECT_DIR/.proc → $PWD/.proc
#
# Usage:
#   cycle.sh start <task-id> [max]   # begin a cycle (max review→fix rounds, default 3)
#   cycle.sh tick                    # increment CYCLE_TICKS, print the new value (hook use)
#   cycle.sh stop                    # end the cycle (remove the marker); alias: --clear
#   cycle.sh status                  # print the current cycle state (or "none")
set -euo pipefail

STATE_DIR="${PROC_STATE_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}/.proc}"
mkdir -p "$STATE_DIR"
CYCLE="$STATE_DIR/cycle.env"

CYCLE_TASK=""; CYCLE_MAX=3; CYCLE_TICKS=0
[ -f "$CYCLE" ] && . "$CYCLE"

write() { # $1=task $2=max $3=ticks
	cat >"$CYCLE" <<EOF
# proc — autonomous cycle marker. Presence + non-empty CYCLE_TASK = a cycle is running.
# Written by cycle.sh; CYCLE_TICKS is bumped by the Stop hook. Values are single words, no spaces.
CYCLE_TASK=$1
CYCLE_MAX=$2
CYCLE_TICKS=$3
EOF
}

case "${1:-}" in
	start)
		TASK="${2:?usage: cycle.sh start <task-id> [max]}"
		MAX="${3:-3}"
		write "$TASK" "$MAX" 0
		echo "cycle started: task=$TASK max=$MAX (state dir: $STATE_DIR)"
		;;
	tick)
		[ -n "$CYCLE_TASK" ] || { echo 0; exit 0; }
		CYCLE_TICKS=$((CYCLE_TICKS + 1))
		write "$CYCLE_TASK" "$CYCLE_MAX" "$CYCLE_TICKS"
		echo "$CYCLE_TICKS"
		;;
	stop|--clear)
		rm -f "$CYCLE"
		echo "cycle stopped"
		;;
	status)
		if [ -n "$CYCLE_TASK" ]; then
			echo "cycle: task=$CYCLE_TASK max=$CYCLE_MAX ticks=$CYCLE_TICKS"
		else
			echo "cycle: none"
		fi
		;;
	*)
		echo "usage: cycle.sh start <task-id> [max] | tick | stop | status" >&2
		exit 1
		;;
esac
