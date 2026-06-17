# plan — planning

## Purpose
Design the solution and agree it with the user BEFORE writing code.

## Applies when
The active task is in the `plan` phase. If the request is clearly about something else → dispatch.

## Steps
1. Study the relevant code/context (an Explore/Plan agent for large tasks).
2. Propose an approach: key files, steps, risks, alternatives. If there is a better solution than the user's — argue for it, do not agree blindly.
3. Put the plan up for agreement.

## Agreement gate (hard)
**Transition to `implement` only after the user's explicit "ok".** Without confirmation — stay in `plan`.

## Who does it
Self; for large/ambiguous tasks — a Plan agent for the design, and if needed several variants followed by a choice.

## Skills
Usually none (analysis — self/agents).

## Transition
- Got the "ok" → `implement`: run `transition.sh <task> implement`.
- Need to rethink later → stay in `plan` or escape to `dispatch`.
