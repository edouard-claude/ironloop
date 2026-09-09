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

## The Sparring Loop

Default mode: you arrive with the spec. When you do not, the agent runs a
sparring loop instead of guessing, and you keep the pen.

Rules of the loop:

1. **One question at a time.** No questionnaire dumps. The agent asks,
   you answer, `spec.md` grows by that much, next question.
2. **Fill in order**: what it does, then Public API, then Constraints,
   then Failure Modes, then Concurrency. A question about a later
   section before the earlier one is signed is out of order.
3. **The agent proposes, you dispose.** It may draft a row, a signature,
   an invariant. It never marks a section settled; you do.
4. **Failure Modes is where the loop earns its cost.** Once you have
   listed yours, the agent must propose the modes you did not think of,
   drawn from the Public API: every input that can be malformed, every
   bound that can overflow, every dependency that can time out, every
   caller that can retry. It proposes, you accept or reject each row.
5. **Stop at the contract.** The loop is over when the 5 sections are
   filled. Not when the design feels complete. Implementation choices
   belong to Layer 2, and an agent drifting into them is off-layer.

Two anti-patterns:

- The agent writes the whole spec in one shot and asks you to approve it.
  That is not sparring, that is a draft you will rubber-stamp. Reject it
  and restart the loop question by question.
- You answer "whatever you think is best". Then there is no contract, only
  the agent's assumptions with your name on them.

The sparring loop does not change the completion criterion above. The spec
is still signed by you, and every failure mode still needs its red test.

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