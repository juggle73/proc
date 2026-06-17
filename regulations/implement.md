# implement — implementation

## Purpose
Write code strictly per the solution approved in `plan`.

## Applies when
The active task is in the `implement` phase. If asked to rethink → plan; to switch task → dispatch.

## Steps
1. Implement per the plan. Deviations from the approved plan only with agreement.
2. Write code in the style of the surrounding code (naming, comment density, idioms).
3. Carry it through to the end, leaving nothing "for later".

## Who does it / parallelism
- Small/cohesive changes — self.
- Several **independent** parts of one task — fan out subagents (intra-task parallelism). This is allowed even though there is no concurrency between tasks.
- Do not parallelize conflicting edits in shared files.

## Skills
- `frontend-design` — if building UI/frontend.
- Other skills — as needed from the actual work.

## Transition
- Implementation ready → `review`: run `transition.sh <task> review`.
- A fundamental flaw in the plan surfaced → escape to `plan`.
