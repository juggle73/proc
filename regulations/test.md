# test — testing

## Purpose
Confirm the change actually works: run tests and/or manually verify behavior.

## Applies when
The active task is in the `test` phase. If the request is about something else → dispatch.

## Steps
1. Decide what to check (automated tests, build, application behavior).
2. Run it and observe the result. Report honestly: if it failed, say it failed, with the output.

## Who does it
Self.

## Skills
- `verify` — confirm the change does what it is supposed to.
- `run` — launch the app and observe behavior.

## Transition (guarded)
- Failure → `fix`, record the failures in the notes: run `transition.sh <task> fix`.
- Success → `done`: run `transition.sh <task> done`.
