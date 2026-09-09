# Layer 1: Specification

**Who:** Human (you)
**Cost:** Thinking time
**Output:** `spec.md` (see [template](../assets/spec.md))

## Completion Criterion

**Layer 1 is closed when:** the file `spec.md` exists, contains the 5
sections (what it does, public API, constraints, failure modes, success
criteria), you have read and signed off on it, and every failure mode in
`spec.md` has a red test written by the agent and reviewed by you (test
names only). Not before.

Run `cargo test`: every new test must fail. A test that passes before any
implementation exists is not red-capable: send it back.

## The Rule

You never write a line of generated code without a spec.
The spec is the contract. The code is the implementation.
If the spec changes, the code gets regenerated.

## What Goes In the Spec

1. **What it does**: one sentence. If you need two, split the project.
2. **Public API**: every function, trait, type that another module will call
3. **Constraints**: language, runtime, dependency budget (max 5, justify each)
4. **Failure modes**: what happens when things break, explicitly. Each row
   becomes at least one Layer 3 test and, if Layer 4 applies, one
   simulation scenario
5. **Success criteria**: how you know it's done

## Anti-Patterns

- ❌ "I know what I want, let me just start coding"
- ❌ "The spec is in my head"
- ❌ "I'll write the spec after I see the first version"
- ❌ Spec longer than 2 pages (split the project)

## When to Re-spec

- Adding a new public function → update the spec first
- Changing a type signature → update the spec first
- Discovering a new failure mode → update the spec first

## For Brownfield (Phase B)

When extracting specs from existing code, the agent generates a draft.
You review and edit. The spec must reflect *desired* behavior, not
necessarily *current* behavior. Gaps between spec and code become
issues for the next rewrite cycle.