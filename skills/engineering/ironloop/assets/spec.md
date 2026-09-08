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

## Success Criteria

- [ ] `cargo build --release` compiles with zero errors, zero warnings
- [ ] `cargo clippy -- -D warnings` passes
- [ ] `cargo fmt --check` passes
- [ ] `cargo test` passes with 100% success
- [ ] Coverage >= 80%
- [ ] All failure modes have >= 1 test
- [ ] [Layer 4: simulation passes] (if distributed)
- [ ] [Layer 5: pentest zero critical] (if exposed surface)