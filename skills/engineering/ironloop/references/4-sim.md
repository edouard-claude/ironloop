# Layer 4: Simulation

**Who:** Automation (CI)
**Cost:** CPU time
**Input:** Test suite from Layer 3 + simulation config
**Output:** Pass/fail gate in CI, issues for failures, each with a seed

## What This Is

Your system passes unit tests on one machine. Will it pass on 96 machines
with one node dead and 20% packet loss?

Simulation answers that question, on every commit. Two tiers:

| Tier | Where | When | Determinism |
|------|-------|------|-------------|
| **A: in-process simulation** | Test binary, single process | Every commit | Fully deterministic, seeded |
| **B: infrastructure chaos** | Real containers, real network | Nightly / pre-release | Best effort |

Tier A is the gate. Tier B is the smoke test. A failure that cannot be
replayed from a seed is a rumor, not a finding, and an agent cannot fix
a rumor.

## When to Activate

- Any system that runs on >1 machine
- Any system that handles money, auth, or data integrity
- Any concurrent code (async tasks, threads, locks)
- Any system where "it worked on my machine" ≠ "it works in production"

## Tier A: In-Process Deterministic Simulation

Rust is the ecosystem where this is mature. Pick per concern:

| Concern | Tool | What it does |
|---------|------|--------------|
| Network partitions, latency, drops between nodes | `turmoil` (tokio) | Runs N "hosts" in one process on a simulated network; faults are scripted and seeded |
| Whole-system determinism (FoundationDB style) | `madsim` | Deterministic scheduler, clock, disk and network; same seed, same run, every time |
| Concurrency interleavings, locks, atomics | `loom` | Exhaustively explores thread schedules of a small critical section |
| Invariants under random inputs | `proptest` | Property-based generation with shrinking |
| Parsers, codecs, untrusted input | `cargo fuzz` | Coverage-guided fuzzing; run bounded in CI, unbounded nightly |
| Undefined behavior in the little `unsafe` you couldn't forbid | `miri` | Interprets the tests and flags UB |

Rules:
1. Every run logs its seed. Every failure report starts with the seed.
2. `cargo test` must be able to replay a failure with
   `IRONLOOP_SEED=<seed>`; no failure is closed without a replay.
3. Scenarios come from the spec's Failure Modes table: one scenario per
   row, minimum.
4. Assertions are invariants, not outputs: no lost write, no duplicate
   side effect, no deadlock, recovery within the window.

## Tier B: Infrastructure Chaos

For what Tier A cannot model: real kernels, real disks, real containers.

1. CI spins up a test cluster (Testcontainers or Docker Compose, N
   instances of your service)
2. A chaos controller injects failures from [assets/sim.yaml](../assets/sim.yaml):
   - Network (Toxiproxy): latency, jitter, bandwidth, partition
   - Process (Pumba / Chaos Mesh): SIGKILL, SIGSTOP/SIGCONT, OOM
   - Disk: I/O errors, full disk, slow writes
   - Clock: time jumps, skew between nodes
3. Your test suite runs under chaos
4. Results:
   - System recovers and all assertions pass → green
   - Data corruption, lost writes, deadlock → red → issue created

Tier B is nightly, not per-commit: it is slow and only best-effort
reproducible. Every Tier B failure must be reduced to a Tier A scenario
before it is considered fixed.

## Completion Criterion

**Layer 4 is closed when:** Tier A ran on the latest commit with a
recorded seed, CI status is green, and zero scenarios caused data
corruption or deadlock. A timeout or degraded latency is not a failure
if the system recovers within the configured window. Tier B is required
before a release, not before a merge.

## Output

- Green: merge allowed
- Red: merge blocked, issue auto-created with:
  - Seed (Tier A) or scenario id (Tier B)
  - Chaos scenario that triggered the failure
  - Logs from all nodes
  - Stack trace / error message
  - Tag: `ironloop/sim`

## Core Insight

> "The simulator shakes everything with randomness. If you test by hand,
> it's hundreds of hours. On every commit, it goes to simulation."

This is what makes Layer 3 tests meaningful in production. Without
simulation, your tests prove the code works in a clean room.
Simulation proves it works in hell, and the seed proves it again
tomorrow.
