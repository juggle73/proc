# dispatch — task dispatcher (project-level)

## Purpose
Manage the task multiplex: create a new task, switch the active one, pause, show the list. We also land here when there is no active task or the state is broken.

## Applies when
- `ACTIVE_PHASE` is empty / there is no active task;
- the message is about selecting / creating / switching / listing / prioritizing tasks;
- the user explicitly asks "switch task", "new task", "what's in progress".

## Steps
1. Read `STATUS.md` — understand which tasks exist and in which phases.
2. Determine the intent:
   - **Create**: assign the next id (t1, t2, …), add a row to the registry (phase `intake`, state `active`), make it ACTIVE.
   - **Switch**: change ACTIVE to the chosen task; its saved phase becomes the current one. Move the previous one to `paused` (unless it is `done`).
   - **Show**: just show the registry, do not change the active task.
3. Remember: there is no concurrency — exactly one task is active at any moment. If the user wants things "in parallel", that means "keep them open, switch between them".

## Who does it
Self. Agents/parallelism are not needed here.

## Skills
None required.

## Transition
- Created a task → add its row to the registry by hand (the helper only updates existing rows), then `intake`: run `transition.sh <task> intake active`.
- Switched to an existing one → its saved phase: run `transition.sh <task> <saved-phase>` (and move the previous one to `paused` with `transition.sh <prev> <prev-phase> paused` unless it is `done`).
- The helper rewrites `state.env` and the `STATUS.md` row + `ACTIVE` field together, so they never drift.
