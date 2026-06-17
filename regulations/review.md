# review — review

## Purpose
Check what was done for correctness and quality, decide what's next.

## Applies when
The active task is in the `review` phase. If the request is about something else → dispatch.

## Steps
1. Identify what changed for the task:
   - **Git repo** → review the diff (`git diff`, `git status`); the `code-review` skill operates on it.
   - **No git repo** (e.g. proc itself) → review the working tree directly against the plan. There is no diff, so `code-review` cannot run on one; apply its judgement manually over the changed files.
2. Assess: conformance to the plan, correctness, obvious bugs, simplifications.
3. Make the transition decision (below).

## Who does it
Self.

## Skills
- `code-review` — the main review tool **when there is a diff** (git repo). For non-git work, review manually using the same checklist; do not block on the skill.
- `security-review` — if the changes touch security/sensitive areas.

## Transition (guarded)
- Findings exist → `fix` (`ACTIVE_PHASE=fix`), record them in the task notes.
- Clean and tests/verification are needed → `test`.
- Clean and tests are not needed → `done`.
- A finding is real but deliberately deferred → log it under `## Backlog` in `STATUS.md` (don't lose it), then proceed.
- Update `state.env` and `STATUS.md` via `transition.sh <task> <phase> [state]`.
