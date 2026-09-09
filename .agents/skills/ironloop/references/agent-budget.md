# Agent Budget and Journal

**Who:** Agent, enforced by you and by CI
**Purpose:** the harness verifies the code; this file verifies the agent.
Token ceilings per layer, one global stop rule, and a decision journal so
every run is auditable.

## Token Ceilings

Ceilings scale with the project type from `triggers.md`. The agent reads
its own usage after each loop and compares.

| Layer | Ceiling (per task) | On breach |
|-------|--------------------|-----------|
| 1. SPEC | none (human) | n/a |
| 2. GEN | 20% of task budget | Stop, "Layer 2 over budget", show last 3 errors |
| 3. TEST | 40% of task budget | Stop, "Layer 3 over budget", list surviving mutants |
| 5. PENTEST | 30% of task budget | Stop, list unconfirmed findings |
| Reserve | 10% | Journal, ratio report, PR description |

Task budget is set by the human in the spec (`## Budget` section, see
`assets/spec.md`). Default when absent: 500k tokens.

## Global Stop Rules

The agent stops and hands back to the human when any of these is true:

1. Any layer breaches its ceiling
2. Layer 2 loops > 10 times total (existing rule)
3. Layer 3 produces the same surviving mutant after 3 attempts
4. Layer 5 produces a critical confirmed finding the agent cannot fix
   without changing the spec
5. The agent has modified the spec, the lints, the `deny.toml`, the CI
   workflow, or any file under `assets/` : these are human-owned; any
   diff there is a stop
6. Wall clock > 2 h on a single task

Stopping is a success state. Burning the reserve to avoid stopping is a
failure state.

## Decision Journal

Every task writes `ironloop.log` at the repo root, one line per decision,
append-only, committed with the PR:

```
<iso-time> L<layer> <event> <detail>
```

Events:

| Event | When |
|-------|------|
| `enter` | Layer starts; detail = input file or commit |
| `loop` | One feedback loop closed; detail = gate + verdict |
| `choice` | Agent picked between alternatives; detail = the alternatives and the reason, one line |
| `scope` | A gate was scoped down; detail = gate + rule from `cost.md` |
| `stop` | A stop rule fired; detail = which one |
| `close` | Layer closed; detail = tokens used / ceiling |

Example:

```
2026-09-08T10:12:03Z L2 enter spec.md@4f1c9a
2026-09-08T10:12:41Z L2 loop cargo check FAIL E0502 borrow
2026-09-08T10:13:05Z L2 choice clone-vs-restructure -> restructure (lints deny redundant_clone)
2026-09-08T10:14:10Z L2 loop cargo check OK
2026-09-08T10:15:00Z L2 close 41k/100k
2026-09-08T10:15:01Z L3 enter
2026-09-08T10:21:30Z L3 scope cargo-mutants --in-diff (cost.md: >10min)
2026-09-08T10:29:12Z L3 close 118k/200k
```

## What You Read

You do not read the code. You read `ironloop.log`:

- every `choice` line: is the reason consistent with the spec?
- every `scope` line: is there a nightly job covering the rest?
- every `stop` line: what does the agent need from you?
- the `close` lines: is the ratio (L3+L5) / L2 within `triggers.md`?

Five minutes on the journal replaces an hour on the diff.

## CI Enforcement

`scripts/check-journal.sh` runs on every PR:

1. `ironloop.log` exists and was modified in the PR
2. Every layer that the triggers require has an `enter` and a `close`
3. No `close` line exceeds its ceiling
4. Every `scope` line names a rule that exists in `cost.md`
5. `ironloop-ratio:` in the PR body matches the `close` lines
