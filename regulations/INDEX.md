# INDEX — proc regulation map

This is a map for the model (not for the hook: the hook resolves `regulations/<ACTIVE_PHASE>.md` by the "phase = filename" convention).

## Two levels

- **Project-level** — `dispatch.md`: selecting/creating/switching tasks (multiplex).
- **Task-level FSM** — each task has its own phase from the set below.

## Single-task FSM

```
dispatch → intake → plan ──[user ok]──► implement → review
review → fix | test | done
fix → review            (loop; after 2 rounds without convergence → escalate to the user)
test → fix | done
done → dispatch
ESCAPE from any non-terminal → plan (rethink) | dispatch (switch task)
```

## Phase → file + intent-guard

| Phase | File | Applies when | If the request is about something else |
|-------|------|--------------|----------------------------------------|
| (none/empty) | `dispatch.md` | no active task, or it's about selecting/creating/switching tasks | — |
| intake | `intake.md` | formulating and clarifying the task | → dispatch (switch task) |
| plan | `plan.md` | designing the solution, getting agreement | → dispatch |
| implement | `implement.md` | writing code per the approved plan | rethink → plan; switch → dispatch |
| review | `review.md` | checking what was done | → fix / plan / dispatch |
| fix | `fix.md` | addressing review/test findings | → dispatch |
| test | `test.md` | running tests / verification | → fix / dispatch |
| done | `done.md` | closing the task | → dispatch |

## Autonomous cycle (overlay)

`cycle.md` is not a phase — it is an **overlay** on the single-task FSM, armed by the `/proc:cycle`
skill and driven by the Stop hook. While a cycle is armed for the active task (`.proc/cycle.env`),
the Stop hook re-invokes the model each turn instead of ending it, so the task walks
`implement → review → fix → … → test → done` without stopping for the user at each phase. The
`plan → implement` agreement gate is **not** bypassed (the cycle pauses once for the user's OK after
`plan`). Convergence budget: `CYCLE_MAX` review→fix rounds (default 3) then escalate; a hard tick
ceiling in the Stop hook is the backstop. See `cycle.md`.

## Invariants (no-dead-end guarantee)

1. Every phase has a regulation file (otherwise the Stop hook blocks the turn from ending).
2. `dispatch` is the entry state: empty/unknown activity leads here.
3. Every non-terminal has an explicit transition + a universal escape to `plan`/`dispatch`.
4. The only terminal is `done` (and it leads straight to `dispatch`).
5. The status is always valid: the model writes the transition, the Stop hook verifies it.
