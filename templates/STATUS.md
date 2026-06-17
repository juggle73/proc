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
Phases (FSM):  intake → plan → implement → review → (fix) → (test) → done
States:        active · paused · blocked · done
On a phase/task change run the transition helper (its exact path is printed by the bootstrap hook):
  transition.sh <task> <phase> [state]   — updates this row + the ACTIVE field + state.env together.
New task rows are added by hand first. ids are assigned sequentially: t1, t2, t3, …
-->
