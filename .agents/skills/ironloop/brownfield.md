# Brownfield Workflow: IRONLOOP

For existing codebases. Add layers progressively without breaking what works.

Two shapes of brownfield work. They share every phase but A:

- **refactor in place**: the legacy stack survives, the code inside it changes.
- **rewrite**: the legacy stack is deleted, its behavior moves to Rust.

Phase 0 is mandatory for both.

## Phase 0: Qualify the oracle

**Goal:** establish that the legacy you are about to record is telling
the truth.

The legacy is the oracle: every later layer compares against what it did.
A degraded oracle produces a green harness around a contract that does
not exist, and no amount of Layer 3 rigour detects it. Mutation testing
proves the tests are red-capable against *the recording*; it says nothing
about whether the recording is complete.

1. Enumerate every backing service the legacy can touch: databases,
   caches, brokers, queues, third-party APIs, filesystem, mail.
2. Assert each one is reachable **from inside the legacy**, not from your
   shell. A backing service that is down usually makes the legacy answer
   normally and write nothing: the response is identical, the side effect
   is gone, and the capture records a request path that has no write seam.
3. Enumerate the state the legacy keeps **between** requests: per-worker
   connections, tenant context, static caches, session files. Each one is
   a way for one recorded case to poison the next, at random, and the
   symptom is a plausible 500 rather than an obvious fault.
4. Reset that state before every case.
5. Prove both checks: replay the same corpus twice, in a different order,
   against the legacy. Identical output, or the oracle is not qualified.

**Exit:** the service list and the state list are written in the
specification, with the check used for each; both checks run inside the
capture harness; a capture that fails either one is discarded.

A capture taken against a partially-down stack is invalid, not a baseline.

## Phase A: Baseline the current behavior

**Goal:** capture what the legacy does today, in an artefact the rest of
the work can gate on.

### A1. Refactor in place: characterization tests

1. Agent reads the legacy code module by module
2. Agent generates unit tests that capture *current* behavior
3. You validate: "Do these tests describe what the code actually does?"
   (Not what it *should* do: that comes later.)
4. Run tests. Fix any that fail due to misunderstood behavior.
5. Commit: "ironloop: layer 3 baseline for <module>"

**Exit:** the test suite (`cargo test`, `go test`, whatever the legacy
stack runs) exists for all critical paths. Run the stack's mutation tool
(`cargo mutants`, `go-mutesting`) once to know how much of that baseline
is red-capable; record the score, it is your starting point.

### A2. Rewrite: golden capture, as data

Characterization tests in the legacy stack are wasted work for a rewrite:
they are written in the language being deleted, run in the runtime being
deleted, and cannot gate the new code. Capture the observable contract as
**data** instead.

1. Define the case format: request in, response out, plus *every* side
   effect the Phase 0 service list names (rows written, jobs enqueued,
   files touched, calls made outbound).
2. Capture a corpus per seam, language-agnostic, replayable against both
   implementations by the same harness.
3. You validate the corpus, not the code: does every service from Phase 0
   appear somewhere in the recorded side effects? A service that never
   shows up is either genuinely unused or was down during capture.
4. Commit the corpus: "ironloop: golden capture for <seam>"

**Exit:** a replayable corpus per critical seam. This corpus *is* the set
of red tests for Layer 1: it fails against an empty Rust module, and
nothing else has been written yet.

## Phase B: Extract Layer 1 (Specs)

**Goal:** Retro-engineer specs from existing code.

1. Agent reads the code + the Phase A artefact (tests or corpus)
2. Agent generates a spec document: interfaces, types, constraints, failure modes
3. You review: "Is this accurate? Is this what we *want*?"
4. Edit the spec to reflect the desired behavior, not just the current behavior
5. Commit: "ironloop: layer 1 spec for <module>"

Write the specification *after* the capture and *before* the port. Both
orders matter: after, because the capture is what the contract actually
is; before, because contract errors are cheap to find on paper and
expensive to find in a diff.

**Exit:** Every critical module has a reviewed spec.

## Phase C: Add Layer 4 (Simulation) on hot paths

**Goal:** Protect the parts that are hardest to test manually.

1. Identify modules that are: distributed, concurrent, or handle data integrity
2. Add simulation configuration
3. Run simulation in CI on PRs touching those modules
4. Prefer Tier A (in-process, seeded) over Tier B (infra chaos); a
   scenario that cannot be replayed from a seed is not a gate

**Exit:** Simulation gate active on hot paths.

## Phase D: Add Layer 5 (Pentest) on exposed surfaces

**Goal:** Find what attackers will find, before they do.

1. Identify modules with: network exposure, user input parsing, auth handling
2. Configure Stage 0 scanners (`cargo audit`, `cargo deny`, `semgrep`)
   first, then the multi-model Stage 1
3. Triage findings: fix critical, document informational
4. Run on every commit to main

**Exit:** Pentest gate active on exposed surfaces.

## Phase E: Rewrite progressively (expand-contract)

**Goal:** Replace legacy with greenfield, module by module, without
breaking anything in between. Use the **expand-contract** pattern:
add the new form beside the old → migrate callers → remove the old.

### E1. Expand: add the new module

1. Pick a module. Write the new spec (greenfield Phase 1).
2. Generate the new module under a new path (e.g. `module_v2/`).
3. The new module must pass all 5 layers before it touches production.
4. Both old and new modules coexist. Nothing is broken.
5. Commit: "ironloop: <module>_v2 passes all 5 layers, ready for migration."

### E2. Migrate: cut over callers batch by batch

1. List every caller of the old module.
2. Migrate callers one batch at a time (per package, per directory).
   Each batch is its own commit.
3. After each batch: the test suite must stay green. Old module still
   exists, so failures are real regressions, not unfinished migrations.
4. If a batch can't stay green alone, land all batches on an integration
   branch and verify at the end.

### E3. Contract: delete the old module

1. Once zero callers reference the old module, delete it.
2. Run the full test suite one last time.
3. Commit: "ironloop: <module> rewritten, old module decommissioned."

### Parallel slices

Several tracer bullets can run at once, one agent per slice, on one
crate. What makes that work is a stated protocol, not tooling:

- **A slice's public surface is one entry point with a fixed signature.**
  The parent fixes the signature before the slice starts.
- **Each agent writes only its own files**: its module, its golden test,
  its spec. Nothing shared.
- **Wiring is the parent's step.** The router, the binary, and every
  other shared file belong to the parent, who adds one line per slice
  when the agent reports its entry point's name. An agent that needs the
  wiring to run its own golden will otherwise invent a workaround and
  leave the shared file dirty.
- **The oracle is a critical section.** Captures and parity runs share
  the legacy's queues and tables, so two of them running at once drain
  each other. Take an exclusive lock around every capture and every
  parity run. A fork that is waiting on the lock reports "waiting" and
  resumes on its own: expect several completion notifications per fork
  and read only the last.

Two classes of finding surface only when slices run side by side: a slice
can go red on plumbing every previous slice passed (a body shape no other
route sent, a header no other route decoded). That is the Phase 0 point
again. A slice's golden tests the plumbing under it, not just the module.

### Wide refactors

When the blast radius fans across the entire codebase (e.g. renaming a
shared type), don't force it into tracer bullets. Use expand-contract:
add the new form, migrate callers in blast-radius batches, delete the
old form only when zero callers remain.

**Exit:** Zero legacy code. Every module is greenfield-verified.

## Phase F: After the rewrite

The end of a migration is the *beginning* of the harness's usefulness.
The layers that proved the port faithful are the same ones that let it
stop being a copy: a frozen contract is what makes an architecture change
cheap, because "did this change anything?" has an answer that is not an
opinion.

1. **Keep the replaced seam switchable.** Put the legacy implementation
   behind a flag (`JOBS=beanstalk`) so the parity gate still has two
   comparable sides. Deleting the seam you verify with, in the same
   change that alters what it verifies, is how a migration loses its
   evidence.
2. **Spec the replacement before building it**, exactly as in greenfield.
   The golden has nothing to say about a component that no longer exists,
   so its behavior is proven by unit tests derived from the spec's own
   prediction table.
3. **Run the first architecture change as the test of the harness.** If
   it is expensive, the harness was built wrong, and that is information
   worth having while the legacy is still switchable.

**Exit:** one architecture change landed, gated by the same harness that
gated the port.

## The harness is an instrument

The capture harness, the replayer and the parity runner are not
scaffolding. They are the instrument every verdict comes from, and an
instrument that is never calibrated reports its own faults as findings.

**When a case that used to pass starts failing, suspect the harness
before the code.** Rule of thumb: if the difference is in *timing,
ordering or shared state* rather than in a value, it is almost always the
harness.

Keep the harness's known failure modes in a list next to it, and add one
line every time a new one costs you an hour:

- A kept table is shared: comparing a whole table makes each case see
  what the previous case left behind. Compare what the request *added*.
- Two runs on one oracle drain each other's queues (see Parallel slices).
- A collection window that closes before the legacy has finished writing
  records a missing side effect.
- Per-worker state carried between requests (see Phase 0).

Give the harness its own regression tests. Every one of the failure modes
above presented as a failing case, and each cost an hour of reading the
port's code first.
