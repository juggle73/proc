# cycle — autonomous cycle (overlay)

## Purpose
Drive one task to completion on its own: implement → review (agent panel) → fix → re-review →
test → done, without pausing for the user at each phase. This is an **overlay** on the normal
per-task FSM — armed by `/proc:cycle`, driven by the Stop hook — not a phase of its own. The task
still moves through the real phases; the cycle just removes the per-phase stops.

## Applies when
A cycle is armed for the active task: `.proc/cycle.env` holds `CYCLE_TASK` = the active task, and
the bootstrap shows `[proc cycle] Autonomous cycle ON`. The Stop hook keeps re-invoking you until
the task reaches `done` (and ACTIVE is cleared) or the continuation budget runs out.

## The one gate that still holds
The `plan → implement` agreement gate is **not** bypassed. If the task has not yet passed `plan`
with the user's explicit OK, do `intake`/`plan` first and **stop for approval** — the cycle waits.
Arm or continue the cycle only after the plan is approved. Everything after that runs autonomously.

## The loop (you drive the transitions)
Each pass:
1. **implement** — write code per the approved plan (`transition.sh <id> implement`). Skip if the
   pass started from an existing implementation.
2. **review** — `transition.sh <id> review`, then run the review **panel** and record every finding
   in `.proc/tasks/<id>/task.md`. Fan the independent reviewers out as parallel subagents:
   - `code-review` — on the git diff (bugs, correctness, simplifications). No git diff (e.g. proc
     itself) → apply its checklist manually over the changed files; do not block on the skill.
   - **conformance** ("the analyst") — a subagent that checks the result against the task's
     definition and DoD in `tasks/<id>/task.md`: requirements met, acceptance criteria satisfied,
     nothing out of scope. This is what `code-review` does *not* do.
   - `security-review` — when the changes touch security/sensitive areas.
3. **decide**:
   - Findings exist → **fix** (`transition.sh <id> fix`): address them in the style of the code,
     note the round number in `tasks/<id>/task.md`, then go back to step 2 (review).
   - Clean → **test** (`transition.sh <id> test`): run tests/build and `verify`/`run` the behavior.
     Failure → back to **fix**. Success → **done**.
4. **done** — `transition.sh <id> done done`, do the `done.md` closure (summary, backlog, memory),
   then end the cycle: `cycle.sh stop` and `transition.sh --clear`.

## Convergence (hard)
- Budget: `CYCLE_MAX` review→fix rounds (default 3). After the budget without convergence — **stop
  the cycle** (`cycle.sh stop`), stay put, and escalate to the user with an honest summary of what
  did not converge and the open findings. Do not loop silently.
- The Stop hook enforces a hard continuation ceiling as a backstop. If it fires, it will tell you to
  stop and report — comply; do not try to re-arm the cycle to get around it.

## Who does it / parallelism
Self drives the transitions; the review panel fans out to subagents (intra-task parallelism, as in
`implement.md`). Do not parallelize conflicting edits in shared files.

## Skills
`code-review`, `security-review` (review panel); `verify`, `run` (test). Others as the work needs.
