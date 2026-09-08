# Layer 4 — Simulation

**Who:** Automation (CI)
**Cost:** CPU time
**Input:** Test suite from Layer 3 + simulation config
**Output:** Pass/fail gate in CI, issues for failures

## What This Is

Chaos engineering for code. Your system passes unit tests on one machine.
Will it pass on 96 machines with one RAM stick failing and 20% packet loss?

Simulation answers that question, on every commit.

## When to Activate

- Any system that runs on >1 machine
- Any system that handles money, auth, or data integrity
- Any system where "it worked on my machine" ≠ "it works in production"

## How It Works

1. CI spins up a test cluster (N instances of your service)
2. A chaos controller injects failures:
   - Network: packet loss, latency spikes, partition
   - Process: SIGKILL, OOM, SIGSTOP/SIGCONT
   - Disk: I/O errors, full disk, slow writes
   - Clock: time jumps, clock skew between nodes
3. Your test suite runs under chaos
4. Results:
   - If the system recovers and all assertions pass → green
   - If the system corrupts data, loses writes, deadlocks → red → issue created

## Configuration

See [assets/sim.yaml](../assets/sim.yaml).

## Completion Criterion

**Layer 4 is closed when:** simulation ran on the latest commit, CI status
is green, and zero chaos scenarios caused data corruption or deadlock.
A timeout or degraded latency is not a failure if the system recovers
within the configured window.

## Output

- Green: merge allowed
- Red: merge blocked, issue auto-created with:
  - Chaos scenario that triggered the failure
  - Logs from all nodes
  - Stack trace / error message
  - Tag: `ironloop/sim`

## Core Insight

> "The simulator shakes everything with randomness. If you test by hand,
> it's hundreds of hours. On every commit, it goes to simulation."

This is what makes Layer 3 tests meaningful in production. Without
simulation, your tests prove the code works in a clean room.
Simulation proves it works in hell.