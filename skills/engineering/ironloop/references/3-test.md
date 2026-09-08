# Layer 3 — Tests

**Who:** Agent (driven by you)
**Cost:** Tokens (test generation + execution)
**Input:** Compiling code from Layer 2 + `spec.md` from Layer 1
**Output:** Test suite with >= 80% coverage, 100% passing

## The Loop

```
Agent generates tests based on spec failure modes
  → Tests fail (code doesn't handle edge case)
    → Agent fixes code
      → Tests pass
        → Agent generates more tests (you review test names)
          → Coverage hits 80%+
            → All tests green ✓
```

## What You Do

1. **Review test names** — "does_test_user_timeout_when_db_down" → good
   "test_handle_error" → bad, too vague, send it back
2. **Review coverage report** — which failure modes from the spec have zero coverage?
3. **Flag missing edge cases** — "the spec says 'returns error on invalid UTF-8'
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

### Property-Based Tests (opt-in, Rust: `proptest`)
- "For any input matching this schema, the output must match this schema"
- Use for parsers, serializers, math functions

## Completion Criterion

**Layer 3 is closed when:** you have run `cargo test` once and seen
`test result: ok. 0 failed`. Then checked the coverage report and seen
a number >= 80%. Then verified that every failure mode from the specification
has at least one test whose name explicitly mentions it. No need to read
the test code — names + coverage are sufficient.

A test that always passes (never red-capable) does not count. If you find
a test whose assertion is `assert!(true)`, `assert_eq!(x, x)`, or any
tautology, delete it.

## Hard Gates

- `cargo test` passes with 100% success
- Coverage >= 80% (`cargo tarpaulin` or `cargo llvm-cov`)
- Every failure mode from `spec.md` has >= 1 red-capable test

## Core Insight

> "You don't read your code anymore. Your code is your specifications,
> architecture, construction, test environment. You will never rewrite
> it again."

Your tests ARE your understanding of the code. If the tests describe
the behavior correctly, the code is correct by definition.