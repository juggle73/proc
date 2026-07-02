#!/bin/bash
# proc — Stop hook. Two jobs:
#   1. Guard the invariant "status is always valid": don't let the turn end if state.env holds a
#      phase without a regulation file (the model picks the transition; the hook validates it).
#      An empty phase is legitimate (= dispatch).
#   2. Drive the autonomous cycle: while a cycle is armed (.proc/cycle.env, CYCLE_TASK = the active
#      task) and the task has not reached `done`, block the stop and re-inject the cycle protocol so
#      the loop keeps running without the user prompting each phase. A hard tick ceiling guarantees
#      the loop always terminates, regardless of model behavior.
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
REG_DIR="$PLUGIN_ROOT/regulations"
CYCLE_SH="$PLUGIN_ROOT/scripts/cycle.sh"
STATE_DIR="$PROJECT_DIR/.proc"
STATE="$STATE_DIR/state.env"
CYCLE="$STATE_DIR/cycle.env"

INPUT=$(cat)
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')

ACTIVE_TASK=""; ACTIVE_PHASE=""; [ -f "$STATE" ] && . "$STATE"

# 1. Invalid-phase guard. Nudge once (respect stop_hook_active to avoid a tight loop).
if [ -n "${ACTIVE_PHASE:-}" ] && [ ! -f "$REG_DIR/${ACTIVE_PHASE}.md" ]; then
  [ "$STOP_ACTIVE" = "true" ] && exit 0
  jq -n --arg p "$ACTIVE_PHASE" '{decision:"block",reason:("state.env: ACTIVE_PHASE=\($p) is invalid — no regulations/\($p).md. Set a valid phase (intake/plan/implement/review/fix/test/done) or clear it for dispatch, then finish.")}'
  exit 0
fi

# 2. Autonomous-cycle driver. Unlike the guard above, this re-blocks every turn (that IS the loop);
# the CYCLE_TICKS ceiling — not stop_hook_active — is what terminates it.
CYCLE_TASK=""; CYCLE_MAX=3; CYCLE_TICKS=0
[ -f "$CYCLE" ] && . "$CYCLE"
CYCLE_MAX=${CYCLE_MAX:-3}
if [ -n "${CYCLE_TASK:-}" ]; then
  # The task was closed and ACTIVE cleared (done.md → transition.sh --clear) → cycle is complete.
  if [ -z "${ACTIVE_TASK:-}" ]; then
    PROC_STATE_DIR="$STATE_DIR" "$CYCLE_SH" stop >/dev/null 2>&1 || true
    exit 0
  fi
  # A different task is active (the user switched away) → pause driving, keep the marker to resume.
  if [ "${CYCLE_TASK}" != "${ACTIVE_TASK}" ]; then
    exit 0
  fi
  # Hard backstop: a bounded number of continuations no matter what the model does.
  CEIL=$(( CYCLE_MAX * 4 + 4 ))
  TICKS=$(PROC_STATE_DIR="$STATE_DIR" "$CYCLE_SH" tick 2>/dev/null || echo 0)
  if [ "$TICKS" -gt "$CEIL" ]; then
    PROC_STATE_DIR="$STATE_DIR" "$CYCLE_SH" stop >/dev/null 2>&1 || true
    jq -n '{decision:"block",reason:"[proc cycle] Hard stop: the autonomous cycle ran out its continuation budget without reaching done. Stop looping now — summarize honestly for the user what converged, what did not, and the open findings in .proc/tasks/<id>/task.md."}'
    exit 0
  fi
  jq -n --arg t "$ACTIVE_TASK" --arg ph "$ACTIVE_PHASE" --arg reg "$REG_DIR/cycle.md" --arg max "$CYCLE_MAX" \
    '{decision:"block",reason:("[proc cycle] Autonomous cycle is ON for task \($t) (phase: \($ph); budget: \($max) review→fix rounds). Do not stop yet — keep driving per \($reg): review with the panel, fix findings, re-review, then test and close the task with done.md. Finish only when the task reaches `done` and ACTIVE is cleared, or escalate if it will not converge within the budget.")}'
  exit 0
fi

exit 0
