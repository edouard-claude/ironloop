# Greenfield Workflow: IRONLOOP

For a brand-new project. All 5 layers from the first commit.

## Layer 1: SPEC

**You write:**
- The public API: function signatures, types, traits
- The constraints: language (Rust by default, see language matrix in
  SKILL.md), runtime (Tokio/no_std), dependencies
- The failure modes: what happens when the DB is down, when the network
  partitions, when input is invalid
- The success criteria: the gates of Layers 2 to 5 that apply

Use the [spec template](assets/spec.md).

**Do not move to Layer 2 until the spec is complete.**

## Layer 2: GEN

Before the first loop: paste [assets/lints.toml](assets/lints.toml) into
`Cargo.toml` and add a `deny.toml` (`cargo deny init`).

**The agent generates code. The compiler rejects it. The agent corrects.**
Loop on `cargo check` until it passes, then close with:
- `cargo build --release` succeeds with zero warnings
- `cargo clippy --all-targets -- -D warnings` passes
- `cargo fmt --check` passes
- `cargo deny check` passes
- No `#[allow(...)]` without a justification comment

**You do not read the code.** You read the compiler output and the
clippy output. If clippy reports `unwrap_used` and the diff adds an
`#[allow]`, reject it: that is compiler appeasement.

## Layer 3: TEST

**The agent writes tests.** You specify what to test: edge cases, failure
modes from the spec, integration points with external systems.

Loop until:
- `cargo test` passes with 100% success
- Coverage >= 80% (`cargo llvm-cov`)
- `cargo mutants --in-diff` plus spec failure-mode modules: >= 80% caught
- Every failure mode from the spec has a corresponding test

**You review the test names, the coverage report and the surviving
mutants, not the test code.** If a test name describes the wrong
behavior, flag it. If a mutant survives on a failure-mode path, the test
is not red-capable: send it back.

## Layer 4: SIM (if distributed/critical)

**Tier A, every commit, in-process and seeded:** `turmoil` for network
faults, `madsim` for deterministic whole-system runs, `loom` for the
concurrency hot spots, `proptest` for invariants, `cargo fuzz` bounded
on parsers. One scenario per row of the spec's Failure Modes table.
Every failure is reported with its seed.

**Tier B, nightly, real infrastructure:** Testcontainers or Docker
Compose cluster, faults injected from the
[simulation config template](assets/sim.yaml) via Toxiproxy / Pumba /
Chaos Mesh. Every Tier B failure is reduced to a Tier A scenario before
it is closed.

Log every failure as a GitHub issue, tagged `ironloop/sim`.

## Layer 5: PENTEST (if exposed surface)

**Stage 0 on every commit:** `cargo audit`, `cargo deny check`,
`cargo geiger`, `semgrep`, `cargo fuzz` on exposed parsers. Blocking.

**Stage 1 on every commit to main:** at least two models from two
vendors attack the code in parallel, then cross-review. A finding counts
only with a reproduction (failing test, request sequence, fuzz input).
Confirmed findings become Layer 3 tests.

Log findings as GitHub issues, tagged `ironloop/pentest`.

## Closing the Task

Report the token ratio: generation (Layer 2) vs verification (Layers 3
to 5). Compare it to the budget in [triggers.md](triggers.md). An
inverted ratio means the harness was too light for the project type.

## Exit Criteria

- [ ] Layer 1: spec.md reviewed and signed off
- [ ] Layer 2: `cargo build`, `cargo clippy -D warnings`, `cargo fmt`, `cargo deny` pass; no unjustified `#[allow]`
- [ ] Layer 3: `cargo test` 100%, coverage >= 80%, mutation score >= 80%
- [ ] Layer 4: Tier A simulation green with recorded seed (if applicable)
- [ ] Layer 5: Stage 0 green, Stage 1 zero critical confirmed findings (if applicable)
- [ ] Token ratio reported and within budget

Only then is the project "done."
