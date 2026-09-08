# [PROJECT NAME]

## What it does
<!-- One sentence. If you need two, split the project. -->

[ ]

## Public API

### Types
```rust
// Type definitions
```

### Functions
```rust
// Function signatures
```

### Traits / Interfaces
```rust
// Trait definitions
```

## Constraints

- **Language:** Rust
- **Runtime:** [Tokio / no_std / async-std]
- **Dependencies (max 5):**
  1. [crate name] — because [justification]
  2. [crate name] — because [justification]
- **Performance:** [p99 latency / throughput / memory budget]
- **Deployment:** [binary + CapRover / container / static]

## Failure Modes

| Scenario | Expected Behavior |
|----------|------------------|
| Database down | [ ] |
| Network partition | [ ] |
| Invalid input | [ ] |
| Out of memory | [ ] |
| Dependency timeout | [ ] |
| Concurrent writes | [ ] |

## Concurrency
<!-- Functions with shared mutable state. Each row becomes a loom target. -->

| Function | Shared state | Invariant |
|----------|--------------|-----------|
| [ ] | [ ] | [ ] |

## Budget

- **Task budget:** [tokens, default 500k]
- **Blocking CI budget:** [minutes, default 40]

## Success Criteria

- [ ] `cargo build --release` compiles with zero errors, zero warnings
- [ ] `cargo clippy --all-targets -- -D warnings` passes (lints.toml active)
- [ ] `cargo fmt --check` passes
- [ ] `cargo deny check` passes
- [ ] `cargo test` passes with 100% success
- [ ] Coverage >= 80%
- [ ] Mutation score >= 80% on the failure-mode modules
- [ ] All failure modes have >= 1 red-capable test
- [ ] [Layer 4: Tier A simulation green, seed recorded] (if distributed)
- [ ] [Layer 5: Stage 0 scanners green, Stage 1 zero critical confirmed] (if exposed surface)
- [ ] Token ratio reported (generation vs verification)