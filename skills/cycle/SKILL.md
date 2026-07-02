---
name: cycle
description: Autonomously drive a task to completion — implement, review with an agent panel (code-review, task-conformance, security), fix, re-review and test in a loop until it converges or the round budget is spent. User-invoked.
argument-hint: <task description, or an existing task id to resume>
disable-model-invocation: true
---

You are starting an **autonomous cycle** for the task below. The cycle self-drives the proc FSM
(implement → review → fix → … → test → done) without stopping for approval at each phase — the Stop
hook keeps it running, and you drive the transitions. Follow `regulations/cycle.md`.

Task: $ARGUMENTS

Do this now:

1. **Identify the task.**
   - If `$ARGUMENTS` names an existing task id in `STATUS.md`, use it.
   - Otherwise create one with the resolved `new-task.sh <id> "<title>"` command the bootstrap
     injected. The task starts in `intake`, ACTIVE.
2. **Respect the agreement gate.** Run `intake` then `plan` normally, present the plan, and **stop
   for the user's explicit OK** — the cycle does not bypass this one gate. If the task is already
   past `plan` with an approved plan, skip ahead.
3. **Arm the cycle** once the plan is approved (or immediately if resuming an already-approved task),
   using the resolved `cycle.sh start <id> [max-rounds]` command the bootstrap injected. Default
   budget: 3 review→fix rounds.
4. **Run the loop** per `regulations/cycle.md`: implement → review with the panel (code-review +
   task-conformance subagent + security-review where relevant) → fix findings → re-review → test →
   close with `done.md`. The Stop hook re-invokes you until the task reaches `done` or the budget is
   spent; you own the `transition.sh` calls.

To stop a running cycle early, use the resolved `cycle.sh stop` command.
