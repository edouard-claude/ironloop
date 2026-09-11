# Layer 2: Generation

**Who:** Agent + Compiler
**Cost:** Tokens (generation)
**Input:** `spec.md`, its skeleton, and the red test suite from Layer 1
**Output:** Compiling, lint-clean, dependency-clean code

## The Loop

```
Agent fills the skeleton's bodies (signatures stay as the spec wrote them)
  → `cargo check` rejects it (Rust: detailed error message)
    → Agent reads error, fixes code
      → `cargo check` rejects again (different error)
        → Agent fixes again
          → `cargo check` accepts
            → `cargo clippy` rejects an appeasement pattern
              → Agent fixes the design, not the lint
                → All gates pass ✓
                  → `cargo test` compiles the red tests against the new
                    code (they may still fail; Layer 3 turns them green)
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
| A fallback path added to silence a lint (default value, retry cascade, `loop {}`) | The lint's point | No lint catches it; the exit ladder below and mutation timeouts do |

The lints are the enforcement. Paste [assets/lints.toml](../assets/lints.toml)
into `Cargo.toml` before the first generation loop. An agent that hits
`unwrap_used` and rewrites the code to handle the error has learned
something. An agent that adds `#[allow(clippy::unwrap_used)]` has not:
reject the diff.

Editing, weakening or `#[ignore]`-ing a red test to make it pass is
compiler appeasement applied to tests. Forbidden.

## When the Lint Is Right: the Exit Ladder

The table says what is forbidden. It does not say what to do when the
lint is right and the honest fix is not local. Left alone with
`unwrap_used` on `Url::parse("https://api.example.com")`, an agent
writes a fallback cascade that ends in `loop {}`: strictly worse than the
`unwrap`, unreachable by any test, and a factory for mutation timeouts.

**A lint fix that adds a path no test can reach is itself appeasement.**
Climb the ladder instead, in order, and stop at the first rung that
holds:

1. **Propagate.** Change the signature to return `Result` and let the
   caller decide. Most `unwrap` sites are a function that should have
   been fallible from the start; the lint is saying the spec's Public
   API is missing an error. Re-spec, then change the signature.
2. **Make the invalid state unrepresentable.** Parse at the boundary,
   once, into a type that cannot be wrong afterwards: a `Url` built from
   the literal in one place (`LazyLock`, or a constructor the tests
   exercise), a newtype validated on construction, an enum instead of a
   string. The `unwrap` disappears because the question it answered no
   longer exists on the hot path.
3. **Prove it infallible, then allow it.** For the residue (a literal
   that cannot fail to parse, a match the compiler cannot see is
   exhaustive), a scoped `#[allow]` on that one expression, with a
   comment stating the proof. This is the only rung where `allow` is
   honest, and it is the last one.

There is no fourth rung. No default value the spec did not name, no
retry the spec did not bound, no `loop {}`, no `std::process::exit`.
Each of those is a failure mode the spec does not have, added to make a
lint go quiet. If none of the three rungs fits, the spec is missing a
row: back to Layer 1.

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
