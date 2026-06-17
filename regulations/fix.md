# fix — fixing

## Purpose
Address the findings discovered in `review` or `test`.

## Applies when
The active task is in the `fix` phase. If the request is about something else → dispatch.

## Steps
1. Take the list of findings from the task notes.
2. Address them, in the style of the surrounding code.
3. Note which fix round this is (cycle 1, 2, …) in the task notes.

## Infinite-loop guard (hard)
`fix → review → fix` is a loop. **After 2 rounds without convergence — stop and escalate to the user** (describe what is not converging and why), do not loop silently.

## Who does it
Self.

## Skills
As needed from the specific findings.

## Transition
- Findings addressed → `review` (re-check): run `transition.sh <task> review`.
- 2 rounds without convergence → escalate to the user (stay in `fix` until decided).
