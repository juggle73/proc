# intake — task statement

## Purpose
Turn the request into a clear, unambiguous task statement: what is needed, why, the definition of done, the boundaries.

## Applies when
The active task is in the `intake` phase — defining its essence. If the user explicitly switches/creates another task → dispatch.

## Steps
1. State the task in your own words: goal, context, definition of done.
2. Find ambiguities and **ask questions — argue until there is 100% clarity** (see the working style). Do not make silent assumptions.
3. Record the final statement and the definition of done in the task's file `.proc/tasks/<id>/task.md` (keep the `STATUS.md` row note to one short phrase).

## Who does it
Self. For reconnaissance over a large/unfamiliar codebase an Explore agent is acceptable.

## Skills
Usually none.

## Transition
- Clarity reached → `plan`: run `transition.sh <task> plan` and record the statement in `.proc/tasks/<id>/task.md`.
- If it turns out this is not one task but several → go back to `dispatch` and register them.
