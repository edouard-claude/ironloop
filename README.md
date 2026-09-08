<p align="center">
  <img src="https://img.shields.io/badge/IRONLOOP-v1.1-8B0000?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white" alt="Rust">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Agent_Skills-spec_compliant-10b981?style=for-the-badge" alt="Agent Skills Spec">
  <a href="https://skills.sh/edouard-claude/ironloop"><img src="https://skills.sh/b/edouard-claude/ironloop" alt="skills.sh"></a>
</p>

<p align="center">
  <b>Code is disposable. The harness is permanent.</b>
</p>

---

IRONLOOP is a **verification-first software engineering system** for
AI-assisted development. Five layers of automated verification that turn
code from a liability into a commodity.

You don't write code anymore. You build a harness *around* code. When the
harness passes, the code is correct. When it doesn't, the code gets
regenerated until it does.

## The Five Layers

| Layer | Name | What happens | Driver |
|:-----:|------|-------------|--------|
| 1 | **SPEC** | Contracts, types, interfaces, failure modes | Human |
| 2 | **GEN** | Code generation + compiler feedback loop | Agent |
| 3 | **TEST** | Unit + integration tests, TDD loop | Agent |
| 4 | **SIM** | Chaos simulation for distributed systems | CI |
| 5 | **PENTEST** | Multi-model attack surface scan | CI |

## The Iron Law

> **More tokens burned on verification than on generation.**
>
> If your verification budget is smaller than your generation budget,
> you are doing it wrong.

For an internal CLI: 30% generation, 70% verification.
For a distributed system: 10% generation, 90% verification.

The more critical the system, the heavier the harness.

## Why It Works

AI code generation alone produces correct-looking code that fails at
runtime. Companies that just hand their developers an AI tool see no
productivity gains — because they took the gains without the harness.

IRONLOOP wraps every line of generated code in verification:

```
SPEC → GEN → TEST → SIM → PENTEST
  ↑       ↓       ↓      ↓       ↓
  └─────── FEEDBACK LOOPS ──────────┘
```

- **Layer 1** defines what "correct" means before any code exists
- **Layer 2** lets the compiler reject bad code — the compiler is your
  first reviewer. Rust's borrow checker is your best pair programmer
- **Layer 3** catches everything the compiler can't — every failure mode
  from the spec gets at least one red-capable test
- **Layer 4** proves your code works in hell, not just in a clean room —
  network partitions, process kills, clock skew, memory pressure
- **Layer 5** finds what attackers will find, before they do — multiple
  AI models attacking your code in parallel, then cross-referencing findings

## Why Rust

Rust's strict compiler provides the tightest feedback loop for AI agents.
Every `cannot borrow as mutable` is free training data. The compiler
drives the agent — you change an interface used in 40 files, the compiler
lists all 40 errors, the agent fixes them one by one.

Go, Python, and JS compile fine and explode at runtime. The agent gets no
signal. **Opt for Rust for all new projects.**

## Two Workflows

### Greenfield — New Projects

All 5 layers from the first commit. Spec first, then generation, then
tests, then simulation, then pentest. Never generate code before the
spec is written. Never declare done before Layer 3 passes.

### Brownfield — Legacy Code

Progressive adoption. Add tests first (capture current behavior), extract
specs by reverse-engineering, add simulation on hot paths, add pentest on
exposed surfaces, then rewrite modules one by one using **expand-contract**:
add new form → migrate callers in batches → delete old form.

## Quick Start

```bash
# Install via skills.sh
npx skills add edouard-claude/ironloop

# Or install a specific skill
npx skills add edouard-claude/ironloop --skill ironloop
```

For Claude Code:
```bash
claude plugins install edouard-claude/ironloop
```

Or just drop `SKILL.md` into your agent's skills directory.

## Structure

```
skills/engineering/ironloop/
├── SKILL.md              ← Main entry point (YAML frontmatter + instructions)
├── greenfield.md          ← New project workflow
├── brownfield.md          ← Legacy migration workflow
├── triggers.md            ← When to activate each layer
├── references/            ← Detailed docs loaded on demand
│   ├── 1-spec.md          ← Specification layer
│   ├── 2-gen.md           ← Generation + compiler loop
│   ├── 3-test.md          ← TDD layer
│   ├── 4-sim.md           ← Chaos simulation
│   └── 5-pentest.md       ← Multi-model pentest
└── assets/                ← Templates and resources
    ├── spec.md             ← Project spec template
    └── sim.yaml            ← Simulation config
```

## How It Was Built

Distilled from production engineering experience spanning 15 years of
building critical infrastructure, cloud platforms, and distributed systems.
The patterns in IRONLOOP were proven across teams shipping software that
handles money, auth, and data integrity at scale — then refined through
systematic R&D with AI coding agents.

No hype. Just the harness that survived contact with reality.

## Spec Compliance

IRONLOOP follows the [Agent Skills open specification](https://agentskills.io/specification):

- **SKILL.md** with required `name` + `description` YAML frontmatter
- **Progressive disclosure**: `references/` loaded on demand, core instructions under 500 lines
- **`assets/`** for templates (spec.md, sim.yaml)
- **LLM-agnostic**: works with Claude Code, OpenAI Codex, Gemini CLI, Cursor, and any agent supporting the Agent Skills standard

## License

MIT — © 2026 Edouard Claude

---

<p align="center">
  <sub>Built with 🦾 by <a href="https://github.com/edouard-claude">edouard-claude</a></sub>
</p>