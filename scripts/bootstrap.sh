#!/bin/bash
# proc — UserPromptSubmit hook. On every prompt (except /proc:nop) injects the current
# state + the regulation-selection protocol. The regulation itself is NOT duplicated —
# the model reads it via Read. The source of truth for the phase is .proc/state.env.
#
# Paths: regulations/skills/scripts live in the plugin ($CLAUDE_PLUGIN_ROOT, read-only);
# mutable state lives in the end-user project ($CLAUDE_PROJECT_DIR/.proc).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
REG_DIR="$PLUGIN_ROOT/regulations"
TRANSITION="$PLUGIN_ROOT/scripts/transition.sh"
NEWTASK="$PLUGIN_ROOT/scripts/new-task.sh"
STATE_DIR="$PROJECT_DIR/.proc"
STATE="$STATE_DIR/state.env"; STATUS="$STATE_DIR/STATUS.md"

INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""')
# /proc:nop — a registered skill (skills/nop/SKILL.md). The hook sees the raw "/proc:nop ...",
# suppresses the bootstrap and leaves the status untouched; the model gets the expanded args.
case "$PROMPT" in /proc:nop*) exit 0 ;; esac

ACTIVE_TASK=""; ACTIVE_PHASE=""; [ -f "$STATE" ] && . "$STATE"
REG_FILE="$REG_DIR/dispatch.md"
[ -n "${ACTIVE_PHASE:-}" ] && [ -f "$REG_DIR/${ACTIVE_PHASE}.md" ] && REG_FILE="$REG_DIR/${ACTIVE_PHASE}.md"
# STATUS.md is the lean INDEX (table + Backlog). Inject it minus HTML comments (human-only notes).
REGISTRY="(no registry yet — .proc/STATUS.md is missing; the SessionStart hook seeds it)"
[ -f "$STATUS" ] && REGISTRY=$(sed '/<!--/,/-->/d' "$STATUS")
# Full definition/notes for the active task live in its own file, read on demand (not injected).
TASK_FILE="$STATE_DIR/tasks/${ACTIVE_TASK:-}/task.md"
TASK_PTR=""
[ -n "${ACTIVE_TASK:-}" ] && [ -f "$TASK_FILE" ] && TASK_PTR="
Active task detail (definition, DoD, notes): $TASK_FILE — Read it on demand when you need the task's specifics; it is NOT injected here."

CTX=$(cat <<EOF
[proc bootstrap] Active task: ${ACTIVE_TASK:-(none)} | phase: ${ACTIVE_PHASE:-(none)}

Task registry ($STATUS):
$REGISTRY
$TASK_PTR

Protocol:
1. Read the regulation for the current state: $REG_FILE
   (Exception: if this message is about selecting / switching / creating / listing tasks, read $REG_DIR/dispatch.md instead.)
2. Do not re-read a regulation if the one for this phase is already in context this session.
3. Act strictly per the regulation: self/agents/parallelism and the required skills come from it.
4. Create a new task (adds the row + scaffolds tasks/<id>/task.md + makes it ACTIVE):
   PROC_STATE_DIR="$STATE_DIR" "$NEWTASK" <id> "<title>"
5. On a phase/task change run the transition helper (it updates state.env + STATUS.md together):
   PROC_STATE_DIR="$STATE_DIR" "$TRANSITION" <task> <phase> [state]
   After closing a task, release ACTIVE with: PROC_STATE_DIR="$STATE_DIR" "$TRANSITION" --clear
   Full task definition/notes live in $STATE_DIR/tasks/<id>/task.md — write detail there, keep the STATUS.md row note to one phrase.
EOF
)
jq -n --arg ctx "$CTX" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
