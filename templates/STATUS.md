# proc — task registry

> Multiplex: several tasks are open at once; I work on one (ACTIVE) and switch between
> them on request. There is no true background concurrency.

ACTIVE: (none)

| id | task | phase | state | depends on | notes |
|----|------|-------|-------|------------|-------|

## Backlog

Deferred findings — real but not done now. Reviewed in `review.md` (where to file them) and `done.md`
(checked before closing). When one is picked up, promote it to a task (tN) in `dispatch`.

Format: `- origin · severity · description`

<!--
This file is the INDEX only: the registry table above + the Backlog. Each task's full
definition, DoD, notes and phase log live in .proc/tasks/<id>/task.md (plus any aux files
in that folder). Keep the `notes` cell here to one short phrase; put detail in task.md.

Phases (FSM):  intake → plan → implement → review → (fix) → (test) → done
States:        active · paused · blocked · done
New task (paths are printed by the bootstrap hook):
  new-task.sh <id> "<title>"             — adds the row, creates tasks/<id>/task.md, sets ACTIVE.
On a phase/task change:
  transition.sh <task> <phase> [state]   — updates this row + the ACTIVE field + state.env together.
ids are assigned sequentially: t1, t2, t3, …
-->
