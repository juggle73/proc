# proc

A hook-driven finite-state machine for Claude Code. On every prompt it injects the current
task state and tells Claude which **regulation** to read for the current phase — so you don't
memorize slash commands, and only the regulation you actually need is loaded into context.

## Demo

<!-- TODO: record a terminal GIF and drop it at docs/demo.gif, then replace this note with:
       ![proc in action](docs/demo.gif)
     Suggested capture: `asciinema rec demo.cast` → `agg demo.cast docs/demo.gif` -->
> _A demo GIF is pending. The annotated walkthrough below shows the same flow as text._

A typical turn, as it appears in your session — no slash command typed:

```text
you ▸ let's add a telegram bot that mirrors my session

[proc bootstrap] Active task: (none) | phase: (none)
   → proc reads regulations/dispatch.md, opens task t1, moves it to `intake`,
     and starts asking clarifying questions.

you ▸ ok, the plan looks good

[proc bootstrap] Active task: t1 | phase: plan
   → the plan→implement gate is satisfied; proc transitions t1 to `implement`,
     writes the code, then self-reviews in `review`.
```

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
- **Per-project state (mutable):** `${CLAUDE_PROJECT_DIR}/.proc/` — add it to your `.gitignore`:
  - `STATUS.md` — the lean **index** (registry table + backlog); this is what the hook injects each prompt.
  - `tasks/<id>/task.md` — each task's full definition, DoD, notes and phase log (plus any aux files in
    that folder). Read on demand, **not** injected — so per-prompt context stays small as the project grows.
  - `state.env` — machine state (active task + phase).

## Requirements

The hooks are POSIX shell scripts. On the machine running Claude Code you need:

- `bash`
- `jq` — the hooks parse their JSON input with it; without `jq` the bootstrap can't run
- `git` — used by the repo and the transition helper

Install `jq` if it is missing: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu), etc.

## Install

```
/plugin marketplace add juggle73/proc
/plugin install proc@proc
```

Then restart Claude Code so the hooks register. On first prompt, `.proc/` is scaffolded automatically.

### Install scope (where it lands)

Plugins install at a **scope**. The typed `/plugin install proc@proc` above defaults to **user**
scope (active in all your projects) — it does *not* prompt. To choose, either pass `--scope` or use
the interactive `/plugin` menu (Discover → select → Install), which *does* ask:

```
/plugin install proc@proc --scope user      # you, everywhere (default)
/plugin install proc@proc --scope project   # everyone on this repo (written to .claude/settings.json, committed)
/plugin install proc@proc --scope local     # just you, just this repo (.claude/settings.local.json, gitignored)
```

### Turn proc on per project (team setup)

Enablement is separate from installation and lives under `enabledPlugins` in `settings.json`. So you
can install proc globally but only activate it where you want it. Disable by default, enable per repo:

```jsonc
// ~/.claude/settings.json — off everywhere by default
{ "enabledPlugins": { "proc@proc": false } }

// <repo>/.claude/settings.json — on for this repo, shared with the team (commit it)
{ "enabledPlugins": { "proc@proc": true } }
```

Project settings override user settings, so proc switches on in that repo and stays off elsewhere.
Precedence (strongest first): managed → `.claude/settings.local.json` (personal per-repo) →
`.claude/settings.json` (team) → `~/.claude/settings.json` (your defaults). To opt out of a
team-enabled proc on just your machine, set it to `false` in `.claude/settings.local.json`.

Toggle an installed proc at runtime via the `/plugin` menu or `/plugin enable proc@proc` /
`/plugin disable proc@proc`. Changes apply without a full restart via `/reload-plugins` — but since
the hooks are snapshotted at session start, restart if the `[proc bootstrap]` line doesn't appear.

### Local development

From a clone of this repo:

```
claude --plugin-dir .
```

`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` both resolve to the repo, so proc dogfoods itself.

## Quickstart on a fresh project

1. Install the plugin and restart Claude Code (see above).
2. On the first prompt, the `SessionStart` hook creates `.proc/` — a `STATUS.md` task registry and a
   `state.env` machine-state file. Add `.proc/` to your `.gitignore`.
3. Just talk to Claude; there are no commands to memorize:
   - *"let's build X"* → proc opens a task and walks it through intake → plan → implement → review → done.
   - *"switch task"* / *"what's in progress?"* → proc shows or switches the task registry.
4. **The agreement gate:** proc will not start writing code until you explicitly approve the plan.
5. Need a one-off answer without the protocol? Use `/proc:nop <message>` (see below).

## Skipping the bootstrap

To answer a single prompt without the regulation protocol:

```
/proc:nop <your message>
```

The command is namespaced by the plugin, so it is `/proc:nop` — not `/nop`.

## Troubleshooting

- **`Stop hook error: … guard-status.sh: No such file or directory`, or hook/regulation changes not taking
  effect** — hook registration and the plugin manifest are snapshotted at session start. Restart Claude Code
  (or relaunch with `claude --plugin-dir .`) to pick up structural changes. Script *bodies* are re-read each call.
- **No `[proc bootstrap]` line appears / hooks never fire** — you are not running under the plugin. Install it
  and restart, or launch `claude --plugin-dir .` from the repo. Also confirm `jq` is installed.
- **The bootstrap appears twice** — proc is loaded twice (e.g. `--plugin-dir .` *and* an installed copy). Use one.
- **`/nop` does not skip the protocol** — the command is namespaced: use `/proc:nop`, not `/nop`.
- **`.proc/` got committed to your repo** — add `.proc/` to `.gitignore`; it is per-project state, not part of the project.

## License

MIT
