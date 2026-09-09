# Layer 3: Tests

**Who:** Agent (driven by you)
**Cost:** Tokens (test generation + execution + mutation runs)
**Input:** Red tests from Layer 1 + compiling code from Layer 2
**Output:** Test suite with >= 80% line coverage, >= 80% mutation score
on spec-critical modules, 100% passing

## The Loop

```
Red tests exist (written in Layer 1, from spec failure modes)
  → Agent generates code (Layer 2, compiler loop until it compiles)
    → `cargo test`: red tests go green, one by one
      → A test stays red → agent fixes code, never the test
        → All green
          → Agent adds tests for edge cases (you review test names)
            → Coverage hits 80%+
              → `cargo mutants` runs
                → Surviving mutants → agent adds red-capable tests
                  → Mutation score hits 80%+ → All green ✓
```

## Why Mutation Testing Is Not Optional

An agent can write a hundred tests that pass no matter what the code
does. Coverage counts lines executed, not behaviors asserted. Mutation
testing flips the question: `cargo mutants` changes the code (`>` to
`>=`, `true` to `false`, deletes a statement) and reruns the suite. If
the suite still passes, that mutant survived, and the test that should
have caught it is not red-capable.

Mutation score is the only direct measure of the "red-capable" promise.
Without it, Layer 3 is an assertion, not a verification.

Run it scoped, not on the whole tree: `cargo mutants --in-diff` on the
PR, plus the modules listed under Failure Modes in the spec. Set
`--timeout` so a runaway mutant cannot eat the CI budget.

## What You Do

1. **Review test names**: `does_user_timeout_when_db_down` → good;
   `test_handle_error` → bad, too vague, send it back
2. **Review coverage report**: which failure modes from the spec have zero coverage?
3. **Review surviving mutants**: each one names a behavior nobody asserts.
   Either the behavior matters (add a test) or the code is dead (delete it).
4. **Flag missing edge cases**: "the spec says 'returns error on invalid UTF-8'
   but I don't see a test for that"

## What You Do NOT Do

- Read the test code. The agent writes `assert_eq!`, not you.
- Read the implementation code. Layer 2 handled that.
- Debug test failures yourself. Tell the agent: "test X failed, fix it."

## Test Categories

### Unit Tests
- One function = one test file
- Test all code paths: happy path, edge cases, error cases
- Mock external dependencies

### Integration Tests
- Test the module against real dependencies (DB, API, filesystem)
- Use Testcontainers for databases, message brokers
- One test per public API endpoint

### Property-Based Tests (`proptest`)
- Required for parsers, serializers, codecs, math, anything with an
  invariant ("decode(encode(x)) == x", "total is conserved")
- Optional elsewhere
- Every proptest failure is minimized and committed as a regression case

## Completion Criterion

**Layer 3 is closed when** each of these has run once and returned its
final verdict:

- `cargo test`: `test result: ok. 0 failed`
- `cargo llvm-cov`: >= 80% line coverage
- `cargo mutants --in-diff` (+ spec failure-mode modules): >= 80% caught,
  zero surviving mutants on a failure-mode path
- Every failure mode from the specification has at least one test whose
  name explicitly mentions it

No need to read the test code; names, coverage and mutation score are
sufficient.

A test that always passes (never red-capable) does not count. If you find
a test whose assertion is `assert!(true)`, `assert_eq!(x, x)`, or any
tautology, delete it. `cargo mutants` will find the ones you missed.

## Hard Gates

- `cargo test` passes with 100% success
- Coverage >= 80% (`cargo llvm-cov`)
- Mutation score >= 80% on the diff and on spec failure-mode modules
- Every failure mode from `spec.md` has >= 1 red-capable test

## Core Insight

> "You don't read your code anymore. Your code is your specifications,
> architecture, construction, test environment. You will never rewrite
> it again."

Your tests ARE your understanding of the code. If the tests describe the
behavior correctly, and mutation testing proves they can tell right from
wrong, the code is correct by definition.
