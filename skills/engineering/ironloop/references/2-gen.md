# Layer 2: Generation

**Who:** Agent + Compiler
**Cost:** Tokens (generation)
**Input:** `spec.md` from Layer 1
**Output:** Compiling, lint-clean, dependency-clean code

## The Loop

```
Agent generates code
  → `cargo check` rejects it (Rust: detailed error message)
    → Agent reads error, fixes code
      → `cargo check` rejects again (different error)
        → Agent fixes again
          → `cargo check` accepts
            → `cargo clippy` rejects an appeasement pattern
              → Agent fixes the design, not the lint
                → All gates pass ✓
```

Use `cargo check` inside the loop, not `cargo build --release`. The loop
must be seconds, not minutes. Run the release build once, at closure.

## Compiler Appeasement

The borrow checker catches memory and aliasing errors. It does not catch
an agent that makes errors disappear instead of solving them. Known
patterns:

| Pattern | What it dodges | Lint |
|---------|----------------|------|
| `.clone()` on every borrow error | Ownership design | `clippy::redundant_clone`, review of `Clone` bounds |
| `.unwrap()` / `.expect()` | `Result` handling | `clippy::unwrap_used`, `clippy::expect_used` |
| `Arc<Mutex<_>>` everywhere | Ownership design | `clippy::arc_with_non_send_sync`, `clippy::mutex_atomic` |
| `unsafe` | Everything | `unsafe_code = "forbid"` |
| `#[allow(...)]` | The lints themselves | Grep in CI; every `allow` needs a comment citing the spec |
| `todo!()` / `unimplemented!()` | The spec | `clippy::todo`, `clippy::unimplemented` |
| `panic!()` in library code | Failure modes | `clippy::panic` |

The lints are the enforcement. Paste [assets/lints.toml](../assets/lints.toml)
into `Cargo.toml` before the first generation loop. An agent that hits
`unwrap_used` and rewrites the code to handle the error has learned
something. An agent that adds `#[allow(clippy::unwrap_used)]` has not:
reject the diff.

## Completion Criterion

**Layer 2 is closed when** each of these has run once and returned its
final verdict:

- `cargo build --release`: `Finished`, zero warnings
- `cargo clippy --all-targets -- -D warnings`: zero lints
- `cargo fmt --check`: zero diffs
- `cargo deny check`: zero advisories, zero banned licenses, zero
  duplicate versions
- `grep -rn "#\[allow(" src/`: every hit has a justification comment

No need to read the full output, just the final verdict of each command.
If you are reading the generated code, you are doing Layer 3's job for it.
Stop.

## You Do NOT Read the Code

At this layer, you read:
1. The compiler output (did it pass?)
2. The clippy output (any lints? any appeasement?)
3. The diff of the spec vs what was requested

You do NOT read the generated code line by line. That's what tests are for.
If you find yourself reading the code, you're doing Layer 3's job wrong;
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

- **Rust:** the borrow checker is your best reviewer. Every "cannot borrow
  as mutable" error is free training data for the agent. Let it fight,
  but with the lints above active, otherwise it wins by appeasement.
- **Go:** static types plus `go vet`, `staticcheck` and `go test -race`
  give real signal, but ignored errors, nil dereferences and
  non-exhaustive switches compile fine. Use `golangci-lint` with
  `errcheck`, `nilnil`, `exhaustive` and `gosec` enabled, and move the
  budget saved in Layer 2 to Layer 3.
- **Python/JS:** Layer 2 is nearly empty. Layers 3-5 must be
  proportionally stronger. Avoid these languages for critical systems.
