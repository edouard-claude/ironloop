[![Version](https://img.shields.io/badge/IRONLOOP-v1.2-8B0000?style=for-the-badge)](https://github.com/edouard-claude/ironloop) [![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org) [![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE) [![Agent Skills Spec](https://img.shields.io/badge/Agent_Skills-spec_compliant-10b981?style=for-the-badge)](https://agentskills.io/specification) [![skills.sh](https://skills.sh/b/edouard-claude/ironloop)](https://skills.sh/edouard-claude/ironloop)

**Code is disposable. The harness is permanent.**

---

IRONLOOP is a **verification-first software engineering system** for
AI-assisted development. Five layers of automated verification that turn
code from a liability into a commodity.

You don't write code anymore. You build a harness *around* code. When the
harness passes, the code is correct. When it doesn't, the code gets
regenerated until it does.

## The Five Layers

| Layer | Name        | What happens                                          | Driver |
| ----- | ----------- | ----------------------------------------------------- | ------ |
| 1     | **SPEC**    | Contracts, types, interfaces, failure modes           | Human  |
| 2     | **GEN**     | Code generation + compiler feedback loop, strict lints | Agent  |
| 3     | **TEST**    | TDD loop + mutation testing (proves tests can fail)   | Agent  |
| 4     | **SIM**     | Deterministic simulation, property tests, fuzzing     | CI     |
| 5     | **PENTEST** | Deterministic scanners, then multi-model attack       | CI     |

## The Iron Law

> **More tokens burned on verification than on generation.**
>
> If your verification budget is smaller than your generation budget,
> you are doing it wrong.

For an internal CLI: 30% generation, 70% verification.
For a distributed system: 10% generation, 90% verification.

The more critical the system, the heavier the harness.

The ratio is **measured, not declared**: every layer records the tokens
it consumed, and the PR carries the resulting ratio. A harness that does
not report its ratio is not an IRONLOOP harness.

## Why It Works

AI code generation alone produces correct-looking code that fails at
runtime. Teams that hand developers an AI tool and nothing else see no
durable productivity gain: they took the speed without the harness.

IRONLOOP wraps every line of generated code in verification:

```
SPEC → GEN → TEST → SIM → PENTEST
  ↑       ↓       ↓      ↓       ↓
  └─────── FEEDBACK LOOPS ──────────┘
```

- **Layer 1** defines what "correct" means before any code exists.
- **Layer 2** lets the compiler reject bad code. The compiler is your
  first reviewer. Strict lints stop the agent from *appeasing* the
  compiler (`.clone()`, `.unwrap()`, `unsafe`) instead of solving the
  problem.
- **Layer 3** catches everything the compiler can't. Every failure mode
  from the spec gets at least one red-capable test, and mutation testing
  proves the tests actually go red.
- **Layer 4** proves your code works in hell, not just in a clean room:
  deterministic simulation with recorded seeds, so every failure replays.
- **Layer 5** finds what attackers will find, before they do:
  deterministic scanners first, then several AI models attacking the
  code in parallel. A finding only counts if it reproduces.

## Why Rust

Rust gives an AI agent the tightest feedback loop available. The compiler
enforces four things no other mainstream language enforces at compile
time:

1. **Exhaustive matching**: every enum variant and every `Result` branch
   must be handled.
2. **Non-ignorable errors**: `Result` is `#[must_use]`; an unhandled
   error is a warning, and warnings are errors here.
3. **Aliasing and lifetimes**: the borrow checker rejects data races and
   use-after-free before anything runs.
4. **No implicit null**: `Option` replaces the billion-dollar mistake.

You change an interface used in 40 files, the compiler lists all 40
errors, the agent fixes them one by one. Every `cannot borrow as mutable`
is free training data.

Other languages give weaker signal, not zero signal. Go has static types,
`go vet`, `staticcheck` and `-race`, but nothing stops an ignored error,
a nil dereference or a non-exhaustive switch from compiling. Python and
JavaScript give the agent almost nothing at Layer 2.

The rule is therefore a matrix, not an absolute:

| Criticality                                     | Language          | Reason                                          |
| ----------------------------------------------- | ----------------- | ----------------------------------------------- |
| Money, auth, data integrity, distributed state  | **Rust**          | Compiler is the reviewer; Layer 2 does real work |
| New services on the critical path               | **Rust**          | Same                                            |
| Internal tooling, glue, CLIs, existing Go code  | Go acceptable     | Shorter loop; compensate with heavier Layer 3   |
| Anything critical                               | Never Python / JS | Layer 2 is empty; the harness cannot compensate |

## Two Workflows

### Greenfield: New Projects

All 5 layers from the first commit. Spec first, then generation, then
tests, then simulation, then pentest. Never generate code before the
spec is written. Never declare done before Layer 3 passes.

### Brownfield: Legacy Code

Progressive adoption. Add tests first (capture current behavior), extract
specs by reverse-engineering, add simulation on hot paths, add pentest on
exposed surfaces, then rewrite modules one by one using **expand-contract**:
add new form → migrate callers in batches → delete old form.

## Quick Start

```
# Install via skills.sh
npx skills add edouard-claude/ironloop

# Or install a specific skill
npx skills add edouard-claude/ironloop --skill ironloop
```

For Claude Code:

```
claude plugins install edouard-claude/ironloop
```

Or just drop `SKILL.md` into your agent's skills directory.

## Toolchain (Rust)

| Layer | Tools                                                                          |
| ----- | ------------------------------------------------------------------------------ |
| 2     | `cargo check`, `cargo clippy -D warnings` (pedantic), `cargo fmt`, `cargo deny` |
| 3     | `cargo test`, `cargo llvm-cov`, `cargo mutants`, `proptest`                    |
| 4     | `turmoil`, `madsim`, `loom`, `cargo fuzz`, `miri`; nightly: Toxiproxy / Chaos Mesh |
| 5     | `cargo audit`, `cargo deny`, `cargo geiger`, `semgrep`; then multi-model attack |

## Structure

```
skills/engineering/ironloop/
├── SKILL.md              ← Main entry point (YAML frontmatter + instructions)
├── greenfield.md          ← New project workflow
├── brownfield.md          ← Legacy migration workflow
├── triggers.md            ← When to activate each layer
├── references/            ← Detailed docs loaded on demand
│   ├── 1-spec.md          ← Specification layer
│   ├── 2-gen.md           ← Generation + compiler loop + anti-appeasement lints
│   ├── 3-test.md          ← TDD layer + mutation testing
│   ├── 4-sim.md           ← Deterministic simulation + infra chaos
│   └── 5-pentest.md       ← Deterministic scanners + multi-model pentest
└── assets/                ← Templates and resources
    ├── spec.md             ← Project spec template
    ├── lints.toml          ← Cargo [lints] block to paste into Cargo.toml
    └── sim.yaml            ← Simulation config
```

## Verifying the Harness Itself

This repository runs a CI check on every push: frontmatter present,
every relative link resolves, `SKILL.md` stays under 500 lines. A
verification harness that does not verify itself has no standing.

Roadmap: a dogfooded example service (`examples/`) running Layers 2 to 5
in GitHub Actions and publishing the generation/verification token ratio
on each PR.

## How It Was Built

Distilled from 15 years of building and operating backend systems and
cloud platforms, then refined through systematic R&D with AI coding
agents. The five-layer structure and the Iron Law owe a debt to Quentin
Adam (Clever Cloud): a constrained language makes a better agent, and
verification must cost more than generation.

## Spec Compliance

IRONLOOP follows the [Agent Skills open specification](https://agentskills.io/specification):

- **SKILL.md** with required `name` + `description` YAML frontmatter
- **Progressive disclosure**: `references/` loaded on demand, core instructions under 500 lines
- **`assets/`** for templates (spec.md, lints.toml, sim.yaml)
- **LLM-agnostic**: works with Claude Code, OpenAI Codex, Gemini CLI, Cursor, and any agent supporting the Agent Skills standard

## License

MIT, © 2026 Edouard Claude

---

Built with 🦾 by [edouard-claude](https://github.com/edouard-claude)
