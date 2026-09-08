# Layer 2 — Generation

**Who:** Agent + Compiler
**Cost:** Tokens (generation)
**Input:** `spec.md` from Layer 1
**Output:** Compiling, clippy-clean code

## The Loop

```
Agent generates code
  → Compiler rejects it (Rust: detailed error message)
    → Agent reads error, fixes code
      → Compiler rejects again (different error)
        → Agent fixes again
          → Compiler accepts: `cargo build --release` ✓
```

## Completion Criterion

**Layer 2 is closed when:** you have run `cargo build --release` once and
seen `Finished` with zero warnings. Then `cargo clippy -- -D warnings` once
and seen zero lints. Then `cargo fmt --check` once and seen zero diffs.
No need to read the full output — just the final verdict of each command.
If you are reading the generated code, you are doing Layer 3's job for it.
Stop.

## Hard Gates

- `cargo build --release` — zero errors, zero warnings
- `cargo clippy -- -D warnings` — zero lints
- `cargo fmt --check` — formatted

## You Do NOT Read the Code

At this layer, you read:
1. The compiler output (did it pass?)
2. The clippy output (any lints?)
3. The diff of the spec vs what was requested

You do NOT read the generated code line by line. That's what tests are for.
If you find yourself reading the code, you're doing Layer 3's job wrong —
the tests should tell you if the code is correct.

## When It Gets Stuck

If the agent loops more than 5 times on the same compiler error:
1. The spec might be contradictory → go back to Layer 1
2. The compiler error might be obscure → add a comment in the spec explaining the constraint
3. The agent might need a hint → provide a one-line direction (not code)

If the loop spins more than 10 times total across all errors, the layer is
blocked. Do not keep looping silently. Stop, say "Layer 2 blocked", show
the last 3 errors, and ask for a specification change or a hint. Never burn
tokens on a loop that isn't converging.

## Language-Specific Notes

- **Rust:** The borrow checker is your best friend. Every "cannot borrow as mutable" error is free training data for the agent. Let it fight.
- **Go:** Less compiler feedback. Layer 3 becomes even more critical since the compiler won't catch runtime panics.
- **Python/JS:** Layer 2 is weak. Layers 3-5 must be proportionally stronger. Avoid these languages for critical systems.