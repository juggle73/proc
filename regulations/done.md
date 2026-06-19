# done — completion

## Purpose
Close the task and return to the dispatcher.

## Applies when
The active task is in the `done` phase.

## Steps
1. Briefly summarize what was done and verified in `.proc/tasks/<id>/task.md`.
2. Check the `## Backlog` section in `STATUS.md` for items this task should have closed — close or re-file them; don't silently leave them.
3. If a non-trivial fact surfaced that is not obvious from the code — save it to project memory.
4. Move the task to the `done` state in the registry.

## Who does it
Self.

## Skills
None required.

## Transition
- Task closed → `dispatch` (pick the next one).
- Run `transition.sh <task> done done` to mark the row done, then `transition.sh --clear` to release ACTIVE (or pick the next task right away in `dispatch`).
