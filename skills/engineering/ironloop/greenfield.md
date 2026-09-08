# Greenfield Workflow — IRONLOOP

For a brand-new project. All 5 layers from the first commit.

## Phase 1: SPEC (Layer 1)

**You write:**
- The public API: function signatures, types, traits
- The constraints: language (Rust), runtime (Tokio/no_std), dependencies
- The failure modes: what happens when the DB is down, when the network
  partitions, when input is invalid
- The success criteria: "compiles with `cargo build --release`"

Use the [spec template](assets/spec.md).

**Do not move to Phase 2 until the spec is complete.**

## Phase 2: GEN (Layer 2)

**The agent generates code. The compiler rejects it. The agent corrects.**
Loop until:
- `cargo build --release` succeeds with zero warnings
- `cargo clippy` passes
- `cargo fmt --check` passes

**You do not read the code.** You read the compiler output.
The compiler is your first reviewer. If it's happy, you move on.

## Phase 3: TEST (Layer 3)

**The agent writes tests.** You specify what to test: edge cases, failure
modes from the spec, integration points with external systems.

Loop until:
- `cargo test` passes with 100% success
- Coverage >= 80% (use `cargo tarpaulin` or `cargo llvm-cov`)
- Every failure mode from the spec has a corresponding test

**You review the test names and coverage report, not the test code.**
If a test name describes the wrong behavior, flag it.

## Phase 4: SIM (Layer 4) — IF distributed/critical

**Enable simulation in CI.** For every open PR:
- Spin up a test cluster (Testcontainers, Docker Compose)
- Inject chaos: network partitions, process kills, disk failures, latency spikes
- Run the test suite under chaos
- Log every failure as a GitHub issue, tagged `ironloop/sim`

Use the [simulation config template](assets/sim.yaml).

## Phase 5: PENTEST (Layer 5) — IF exposed surface

**Run multi-model pentest on every commit to main:**
- Claude (Anthropic) — broad attack surface
- Gemini (Google) — injection & prompt attacks
- Grok (xAI) — creative exploit chains
- Any other model available in CI budget

Log findings as GitHub issues, tagged `ironloop/pentest`.

## Exit Criteria

- [ ] Layer 1: spec.md reviewed and signed off
- [ ] Layer 2: `cargo build`, `cargo clippy`, `cargo fmt` pass
- [ ] Layer 3: `cargo test` 100%, coverage >= 80%
- [ ] Layer 4: simulation suite passes under chaos (if applicable)
- [ ] Layer 5: pentest run, zero critical findings (if applicable)

Only then is the project "done."