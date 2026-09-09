# Gate Cost Budgets

**Who:** Automation (CI) + Agent
**Purpose:** keep every gate under a time budget so the harness never gets
skipped for being slow. A gate that exceeds its budget is scoped down,
never removed.

## Budgets

| Gate | Per PR (blocking) | Nightly (non-blocking) | Scope rule when over budget |
|------|-------------------|------------------------|-----------------------------|
| `cargo check` loop | < 30 s per loop | n/a | Split the crate; a slow `check` is a workspace problem |
| `cargo clippy` | < 2 min | n/a | `--all-targets` per PR; never scope down |
| `cargo test` | < 5 min | full suite | Mark tests > 10 s as `#[ignore]` + nightly `--ignored` |
| `cargo llvm-cov` | < 5 min | full | Same partition as `cargo test` |
| `cargo mutants` | < 10 min | full tree | `--in-diff` on the PR, plus the failure-mode modules of the spec; `--timeout 60`; `--jobs` = cores |
| Tier A sim (`turmoil`, `madsim`) | < 10 min | 1000 seeds | 50 seeds per PR; nightly widens |
| `loom` | < 5 min | full | Only functions tagged `// ironloop: loom` in the spec's Concurrency table; `LOOM_MAX_PREEMPTIONS=2` per PR, `3` nightly |
| `proptest` | inside `cargo test` | `PROPTEST_CASES=10000` | `PROPTEST_CASES=256` per PR |
| `cargo fuzz` | 60 s per target | 1 h per target | Only targets listed in `sim.yaml`; nightly keeps the corpus |
| Stage 0 scanners | < 3 min | n/a | Never scope down |
| Stage 1 multi-model | < 15 min, 2 models | 4 models | Diff-only per PR; full surface nightly |
| Tier B chaos | n/a | < 1 h | Nightly only, ever |

Total blocking budget per PR: **< 40 min**. Above that, the agent must
scope down following the rules in the last column, and report which
gate was scoped and why in the PR under `ironloop-scoped:`.

## Scoping Is Not Skipping

Scoped means: the same gate, on a smaller surface, with the full surface
running nightly. Skipped means: the gate did not run. Only the first is
allowed. A PR that reports `ironloop-scoped:` with no nightly job
covering the rest is a skipped gate.

## What Feeds the Scope

The spec decides the surface, not the agent:

- Failure Modes table → modules for `cargo mutants` and Tier A scenarios
- Concurrency table (new, see `assets/spec.md`) → functions for `loom`
- Public API table → fuzz targets (every parser/decoder of external input)

If a module is not in the spec, it gets the diff-level gates only.

## When the Budget Cannot Hold

If a gate cannot fit its budget even scoped, the problem is the code, not
the gate:

- `cargo check` > 30 s → the crate is too big; split it
- `loom` explodes → the critical section is too wide; narrow it
- `cargo mutants` > 10 min on the diff → the diff is too big; split the PR

The agent reports "Layer N over budget: <gate>" and stops, same protocol
as "Layer 2 blocked".
