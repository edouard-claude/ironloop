# Greenfield Workflow: IRONLOOP

For a brand-new project. All 5 layers from the first commit.

## Phase 0: Capture the outside world

Greenfield has an oracle too: every third-party system the code will
talk to. Before the spec, make the real calls, one per behavior the spec
will depend on, and freeze the responses as fixtures under
`tests/fixtures/<system>/`. See
[references/1-spec.md](references/1-spec.md), "External Systems".

Every Failure Modes row about an external system will cite one of those
fixtures or carry `ASSUMED`. No fixtures, no signed Failure Modes.

## Layer 1: SPEC

**You write:**
- The public API: function signatures, types, traits. Every trait that
  abstracts an external system or another module is a seam and gets
  exactly one fake (Layer 3, contract tests)
- The constraints: language (Rust by default, see language matrix in
  SKILL.md), runtime (Tokio/no_std), dependencies under the notability
  rule
- The failure modes: what happens when the DB is down, when the network
  partitions, when input is invalid, each external row with its evidence
- The layer decisions: Layer 4 and Layer 5, one line each, `REQUIRED
  because <trigger>` or `SKIPPED because <reason>`
- The success criteria: the gates of Layers 2 to 5 that apply

Use the [spec template](assets/spec.md).

**The agent writes the skeleton from the Public API**: every type, trait
and signature, every body returning `Err(Error::Unimplemented)`, no
logic. **Then the red tests from the spec failure modes.** You review the
test names. `cargo test` must compile and show every one of them failing
on an assertion: that is red. A suite that does not build is not red, it
is absent.

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
`#[allow]`, reject it: that is compiler appeasement. If the diff adds a
fallback path instead (a default, a retry, a `loop {}`), reject it too:
same thing with more lines. The agent climbs the exit ladder in
[references/2-gen.md](references/2-gen.md), and the ladder has three
rungs, not four.

## Layer 3: TEST

**The agent turns the red tests green, then extends the suite.** You
specify what to test: edge cases, failure modes from the spec,
integration points with external systems.

Loop until:
- `cargo test` passes with 100% success
- No body still returns `Error::Unimplemented`
- Coverage >= 80% (`cargo llvm-cov`)
- `cargo mutants --in-diff` plus spec failure-mode modules: >= 80% caught
- Every failure mode from the spec has a corresponding test
- Every spec trait has one fake, in one place, and its contract suite
  has run against both the fake and the real implementation

**You review the test names, the coverage report and the surviving
mutants, not the test code.** If a test name describes the wrong
behavior, flag it. If a mutant survives on a failure-mode path, the test
is not red-capable: send it back.

## Layer 4: SIM (when the spec says REQUIRED)

The spec's Layer Decisions line says whether this layer runs. `SKIPPED
because <reason>` is a valid outcome you signed; a missing line is not.

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

## Layer 5: PENTEST (when the spec says REQUIRED)

Same rule. An OAuth server on the public internet is the textbook Layer 5
trigger, and "if applicable" is how it gets skipped without anyone
opening `triggers.md`. The decision line closes that exit.

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

- [ ] Phase 0: fixtures captured for every external system; `ASSUMED` rows listed and signed
- [ ] Layer 1: spec.md reviewed and signed off; skeleton compiles; every red test fails on an assertion; Layer Decisions filled
- [ ] Layer 2: `cargo build`, `cargo clippy -D warnings`, `cargo fmt`, `cargo deny` pass; no unjustified `#[allow]`; no fallback path added to silence a lint
- [ ] Layer 3: `cargo test` 100%, coverage >= 80%, mutation score >= 80%, survivors classified, one fake per trait with its contract suite run against fake and real
- [ ] Layer 4: Tier A simulation green with recorded seed, or `SKIPPED because` in the spec
- [ ] Layer 5: Stage 0 green, Stage 1 zero critical confirmed findings, or `SKIPPED because` in the spec
- [ ] Token ratio reported and within budget

Only then is the project "done."
