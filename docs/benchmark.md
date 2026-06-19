# proc — token footprint benchmark

What a Claude Code plugin costs you in tokens has two parts: the **always-on tax** (what it
puts into context before you do any work) and the **per-prompt injection** (what its hooks add
to every turn). proc is designed to keep both small by loading detail *on demand*. This page
backs that claim with numbers — including the honest places where proc is **not** cheaper.

## Method & honesty notes

- Token counts are estimated as **characters ÷ 4**. Absolute values are approximate, but every
  figure here is measured the *same* way, so the A/B ratios are robust.
- "Always-on tax" counts only what is actually loaded up front: command/skill/agent **frontmatter**
  (name + description), MCP tool schemas, and per-session/per-prompt hook output — **not** skill or
  agent *bodies*, which load on demand. Counting bodies would be misleading.
- This measures **footprint**, not capability. A plugin that does more naturally ships more surface.
  proc is a lightweight FSM router; heavier suites do far more. "Cheaper" here means "smaller
  always-on context", not "better at the same job".

## Result 1 — what 0.2.0 fixed (per-prompt injection vs project size)

Through v0.1.x, proc's `UserPromptSubmit` hook injected the **entire** `STATUS.md` every prompt —
including each task's verbose definition block — so per-prompt context grew unboundedly as the
project accumulated tasks. v0.2.0 split state into a lean **index** (`STATUS.md`) plus per-task
`tasks/<id>/task.md` read on demand, so only the index is injected.

Measured by running the actual `bootstrap.sh` from each version against synthetic registries of
N tasks (representative ~430-char definition blocks, ~110-char rows):

| tasks (N) | 0.1.x chars (≈tok) | 0.2.0 chars (≈tok) | reduction |
|----------:|-------------------:|-------------------:|----------:|
| 1  |  1 534 (≈384)  |  1 726 (≈432)  | **−13%** |
| 5  |  3 182 (≈796)  |  2 098 (≈525)  | **34%** |
| 10 |  5 244 (≈1 311)|  2 564 (≈641)  | **51%** |
| 20 |  9 384 (≈2 346)|  3 504 (≈876)  | **63%** |
| 50 | 21 804 (≈5 451)|  6 324 (≈1 581)| **71%** |

- **0.1.x grows ~14× from 1→50 tasks** (definitions dominate, unbounded).
- **0.2.0 grows ~3.7×** over the same range — and that residual is just the index table, not task
  detail. At 50 tasks the per-prompt injection is **71% smaller**.
- **Honest caveat:** at N=1, v0.2.0 is *13% larger* — it adds a fixed active-task pointer and a
  `new-task` hint to the protocol. The restructure pays off from ~2–3 tasks on; tiny throwaway
  projects pay a small premium for it.

## Result 2 — always-on tax vs a heavier workflow plugin

Compared with [gsd-plugin](https://github.com/jnuyens/gsd-plugin) (a full planning/execution suite),
counting only always-on surface:

| | proc 0.2.0 | gsd |
|---|---:|---:|
| Agents registered | 0 | 33 |
| Skills registered | 1 | 83 |
| MCP tools (always in context) | 0 | ~8 |
| **Always-on frontmatter tax** | **~165 tok** | **~8 200 tok** (+ MCP + SessionStart) |

- gsd's agent/skill **bodies** (~750 KB) are **not** counted — they load on demand, exactly as they
  should. The ~8 200 tok is just the frontmatter the model always carries to know what exists.
- This is the cost of breadth: gsd does much more. The comparison shows proc's *minimalism*, not
  superiority at the same task.
- Trade-off the other way: proc's tax is paid **per prompt** (and grows with the registry — see
  Result 1), while gsd's frontmatter is paid roughly **once per session** (cached). For long
  sessions on large registries the gap narrows.

## Reproduce

```bash
# Result 1: run each version's real bootstrap against synthetic registries (from a clone).
git show proc--v0.1.1:scripts/bootstrap.sh > /tmp/old-bootstrap.sh   # the pre-restructure hook
# For N tasks, build:
#   - a flat STATUS.md  (header + table of N rows + ## Backlog + N "## tN — definition" blocks)
#   - a lean STATUS.md  (header + table of N rows + ## Backlog) plus .proc/tasks/t1/task.md
# then measure each hook's injected context:
#   printf '{"prompt":"x"}' | CLAUDE_PLUGIN_ROOT=<repo> CLAUDE_PROJECT_DIR=<tmp> bash <bootstrap> \
#     | jq -r '.hookSpecificOutput.additionalContext' | wc -c
```

> Numbers above were produced this way on the v0.2.0 tree. Estimates are chars÷4.
