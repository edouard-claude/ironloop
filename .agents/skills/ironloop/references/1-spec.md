# Layer 1: Specification

**Who:** Human (you)
**Cost:** Thinking time
**Output:** `spec.md` (see [template](../assets/spec.md))

## Completion Criterion

**Layer 1 is closed when:** the file `spec.md` exists, contains its
sections (what it does, public API, constraints, failure modes, layer
decisions, success criteria), you have read and signed off on it, the
skeleton compiles, and every failure mode in `spec.md` has a red test
written by the agent and reviewed by you (test names only). Not before.

Run `cargo test`: the suite must **compile**, and every new test must
**fail on an assertion**. That is what red means. A test that does not
compile is not red, it is absent. A test that passes before any
implementation exists is not red-capable. Both go back.

## The Sparring Loop

Default mode: you arrive with the spec. When you do not, the agent runs a
sparring loop instead of guessing, and you keep the pen.

Rules of the loop:

1. **One question at a time.** No questionnaire dumps. The agent asks,
   you answer, `spec.md` grows by that much, next question.
2. **Fill in order**: what it does, then Public API, then Constraints,
   then Failure Modes, then Concurrency, then Layer Decisions. A
   question about a later section before the earlier one is signed is
   out of order.
3. **The agent proposes, you dispose.** It may draft a row, a signature,
   an invariant. It never marks a section settled; you do.
4. **Failure Modes is where the loop earns its cost.** Once you have
   listed yours, the agent must propose the modes you did not think of,
   drawn from the Public API: every input that can be malformed, every
   bound that can overflow, every dependency that can time out, every
   caller that can retry. It proposes, you accept or reject each row.
5. **Stop at the contract.** The loop is over when the sections are
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

## The Skeleton

"No code before the red tests" cannot be obeyed literally in a typed
language: a test against types that do not exist does not compile, and a
suite that does not compile is not red, it is broken. Layer 1 therefore
ships two artefacts: the specification, and its skeleton.

The skeleton is the Public API section in the compiler's language. Every
type, trait and function signature, exactly as the spec declares them,
with every body returning a typed error:

```rust
pub fn parse_bound(input: &str) -> Result<Bound, Error> {
    Err(Error::Unimplemented("parse_bound"))
}
```

Rules:

- Never `todo!()` or `unimplemented!()`: the lints deny them, and a
  panic is not a failure mode, it is the absence of one.
  `Error::Unimplemented` is a variant the spec's error type carries until
  Layer 3 closes, and a Layer 3 gate greps that no body still returns it.
- The skeleton contains no logic. A body that does anything but return
  the typed error is Layer 2 work leaking into Layer 1.
- The skeleton changes only when the spec changes. Layer 2 fills bodies;
  it does not touch signatures.

The agent writes the skeleton from the Public API, then the red tests
against it. `cargo test` compiles, every test fails on an assertion, and
only then is the layer closed.

## What Goes In the Spec

1. **What it does**: one sentence. If you need two, split the project.
2. **Public API**: every function, trait, type that another module will
   call. Every trait that abstracts an external system or another module
   is a seam, and a seam gets exactly one fake (Layer 3, contract tests).
3. **Constraints**: language, runtime, dependencies. Each dependency
   passes the **notability rule**: widely used, actively maintained,
   clean under `cargo deny`, and justified in one line. Five is not a
   cap; it is the point past which the list itself needs a justification.
   A crate that fails `cargo deny` leaves, whatever the count says.
4. **Failure modes**: what happens when things break, explicitly. Each
   row becomes at least one Layer 3 test and, if Layer 4 applies, one
   simulation scenario. Each row about an external system cites its
   evidence (see below).
5. **Layer decisions**: one line for Layer 4 and one for Layer 5,
   `REQUIRED because <trigger from triggers.md>` or `SKIPPED because
   <reason>`. An empty line is a stop, not a default.
6. **Success criteria**: how you know it's done

## External Systems: Evidence, Not Memory

Greenfield has an oracle too: every third-party system the code talks
to. An agent writing the Failure Modes of an external API from memory is
guessing, and a guess that is right by chance is the worst outcome,
because nothing ever corrects it. A scope list, an error envelope, a
pagination shape: one real call shows what a page of documentation and a
confident memory both get wrong.

Before the Failure Modes section is signed:

1. For every external system behind a Public API trait, make one real
   call per behavior the spec depends on (the success shape, each error
   shape, the auth handshake, the rate-limit response) and freeze the
   responses as fixtures under `tests/fixtures/<system>/`, with the date
   and the account or sandbox used.
2. Every Failure Modes row about an external system cites its fixture in
   the Evidence column. A row with no fixture is marked `ASSUMED`.
3. `ASSUMED` rows are collected in a checklist in the spec, and that
   checklist is a deployment gate: each item is replaced by a fixture or
   signed off by you, in writing, before the first deploy.

The fixtures are the contract tests' data (Layer 3): the fake that
implements the trait replays them, which is what keeps the fake honest.

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

A brownfield spec carries one extra section, **Oracle**, written during
Phase 0 and before any capture:

- every backing service the legacy can touch, with the check that proves
  it reachable *from inside the legacy*
- every piece of state the legacy keeps between requests, with how it is
  reset before each recorded case

Without it, a capture taken against a partially-down stack looks exactly
like a capture of a contract with no write seam, and every later layer
agrees on it. See [brownfield.md](../brownfield.md), Phase 0.