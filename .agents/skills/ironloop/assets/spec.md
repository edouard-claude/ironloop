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
- **Dependencies (notability rule: widely used, maintained, `cargo deny` clean, one-line reason each; past 5, justify the list itself):**
  1. [crate name]: because [justification]
  2. [crate name]: because [justification]
- **Performance:** [p99 latency / throughput / memory budget]
- **Deployment:** [binary + CapRover / container / static]

## Failure Modes
<!-- Evidence: `fixture:<path>` for a captured external response, `ASSUMED` when
     none exists yet, `internal` when no external system is involved. -->

| Scenario | Expected Behavior | Evidence |
|----------|------------------|----------|
| Database down | [ ] | internal |
| Network partition | [ ] | internal |
| Invalid input | [ ] | internal |
| Out of memory | [ ] | internal |
| Dependency timeout | [ ] | [fixture:... / ASSUMED] |
| Concurrent writes | [ ] | internal |
| [External system] returns [error shape] | [ ] | [fixture:... / ASSUMED] |

## External Systems
<!-- Phase 0. One row per behavior the spec depends on. Delete if none. -->

| System | Behavior | Fixture | Captured on / with |
|--------|----------|---------|--------------------|
| [API name] | [success shape / error shape / auth / rate limit] | `tests/fixtures/[system]/[name].json` | [date, sandbox account] |

**ASSUMED checklist** (deployment gate: each line replaced by a fixture or
signed off in writing before the first deploy):

- [ ] [row from Failure Modes marked ASSUMED, and why no fixture yet]

## Concurrency
<!-- Functions with shared mutable state. Each row becomes a loom target. -->

| Function | Shared state | Invariant |
|----------|--------------|-----------|
| [ ] | [ ] | [ ] |

## Oracle (brownfield only)

Filled during Phase 0, before any capture. Delete this section for
greenfield.

| Backing service | Reachability check, from inside the legacy |
|-----------------|--------------------------------------------|
| [db / cache / broker / API / fs] | [the assertion that proves it live] |

| State kept between requests | Reset before each case by |
|-----------------------------|---------------------------|
| [per-worker connection, tenant context, static cache] | [the reset] |

Corpus replayed twice in a different order, identical output: [yes/no]

## Layer Decisions
<!-- One line each. REQUIRED or SKIPPED, with the reason. An empty line is a
     stop (agent-budget.md, rule 7). Triggers are in triggers.md. -->

- **Layer 4 (SIM):** [REQUIRED because <trigger> | SKIPPED because <reason>]
- **Layer 5 (PENTEST):** [REQUIRED because <trigger> | SKIPPED because <reason>]

## Budget

- **Task budget:** [tokens, default 500k]
- **Blocking CI budget:** [minutes, default 40]

## Success Criteria

- [ ] Skeleton compiles; every red test fails on an assertion (Layer 1 close)
- [ ] `cargo build --release` compiles with zero errors, zero warnings
- [ ] `cargo clippy --all-targets -- -D warnings` passes (lints.toml active)
- [ ] `cargo fmt --check` passes
- [ ] `cargo deny check` passes
- [ ] `cargo test` passes with 100% success
- [ ] Coverage >= 80%
- [ ] Mutation score >= 80% on the failure-mode modules
- [ ] All failure modes have >= 1 red-capable test
- [ ] No body still returns `Error::Unimplemented`
- [ ] One fake per spec trait, contract suite green against fake and real
- [ ] ASSUMED checklist empty or signed
- [ ] Layer 4: Tier A simulation green, seed recorded, or SKIPPED in Layer Decisions
- [ ] Layer 5: Stage 0 scanners green, Stage 1 zero critical confirmed, or SKIPPED in Layer Decisions
- [ ] Token ratio reported (generation vs verification)