# proc

A hook-driven finite-state machine for Claude Code. On every prompt it injects the current
task state and tells Claude which **regulation** to read for the current phase — so you don't
memorize slash commands, and only the regulation you actually need is loaded into context.

## How it works

- A `UserPromptSubmit` hook (`scripts/bootstrap.sh`) reads the project's state and injects a short
  protocol: *"you are in phase X → read `regulations/X.md`"*. The regulation itself is read on demand,
  not duplicated into every prompt.
- A `Stop` hook (`scripts/guard-status.sh`) enforces the invariant that the state is always valid
  (a phase always has a regulation file), so the FSM never dead-ends.
- A `SessionStart` hook (`scripts/seed.sh`) scaffolds the per-project state on first run.
- Transitions are applied by `scripts/transition.sh`, which rewrites the state file and the task
  registry together so they never drift.

### The FSM

```
dispatch → intake → plan ──[user ok]──► implement → review
review → fix | test | done
fix → review            (loop; after 2 rounds without convergence → escalate)
test → fix | done
done → dispatch
```

`dispatch` is the project-level task multiplex (create / switch / list tasks); every task then runs
its own phase FSM. See `regulations/INDEX.md` for the full map.

## State vs. plugin

- **Plugin (read-only, shared):** `regulations/`, `skills/`, `scripts/`, `hooks/` — installed under
  `${CLAUDE_PLUGIN_ROOT}`.
- **Per-project state (mutable):** `${CLAUDE_PROJECT_DIR}/.proc/` — `STATUS.md` (task registry) and
  `state.env` (machine state). Add `.proc/` to your `.gitignore`.

## Install

```
/plugin marketplace add juggle73/proc
/plugin install proc@proc
```

Then restart Claude Code so the hooks register. On first prompt, `.proc/` is scaffolded automatically.

### Local development

From a clone of this repo:

```
claude --plugin-dir .
```

`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` both resolve to the repo, so proc dogfoods itself.

## Skipping the bootstrap

To answer a single prompt without the regulation protocol:

```
/proc:nop <your message>
```

## License

MIT
