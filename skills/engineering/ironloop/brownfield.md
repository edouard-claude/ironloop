# Brownfield Workflow — IRONLOOP

For existing codebases. Add layers progressively without breaking what works.

## Phase A: Add Layer 3 (Tests)

**Goal:** Cover existing behavior with tests before touching anything.

1. Agent reads the legacy code module by module
2. Agent generates unit tests that capture *current* behavior
3. You validate: "Do these tests describe what the code actually does?"
   (Not what it *should* do — that comes later.)
4. Run tests. Fix any that fail due to misunderstood behavior.
5. Commit: "ironloop: layer 3 baseline for <module>"

**Exit:** `cargo test` suite exists for all critical paths.

## Phase B: Extract Layer 1 (Specs)

**Goal:** Retro-engineer specs from existing code.

1. Agent reads the code + the tests from Phase A
2. Agent generates a spec document: interfaces, types, constraints, failure modes
3. You review: "Is this accurate? Is this what we *want*?"
4. Edit the spec to reflect the desired behavior, not just the current behavior
5. Commit: "ironloop: layer 1 spec for <module>"

**Exit:** Every critical module has a reviewed spec.

## Phase C: Add Layer 4 (Simulation) on hot paths

**Goal:** Protect the parts that are hardest to test manually.

1. Identify modules that are: distributed, concurrent, or handle data integrity
2. Add simulation configuration
3. Run simulation in CI on PRs touching those modules
4. Fix any flakiness (simulation must be deterministic-ish)

**Exit:** Simulation gate active on hot paths.

## Phase D: Add Layer 5 (Pentest) on exposed surfaces

**Goal:** Find what attackers will find, before they do.

1. Identify modules with: network exposure, user input parsing, auth handling
2. Configure multi-model pentest in CI
3. Triage findings: fix critical, document informational
4. Run on every commit to main

**Exit:** Pentest gate active on exposed surfaces.

## Phase E: Rewrite progressively (expand-contract)

**Goal:** Replace legacy with greenfield, module by module, without
breaking anything in between. Use the **expand-contract** pattern:
add the new form beside the old → migrate callers → remove the old.

### E1. Expand: add the new module

1. Pick a module. Write the new spec (greenfield Phase 1).
2. Generate the new module under a new path (e.g. `module_v2/`).
3. The new module must pass all 5 layers before it touches production.
4. Both old and new modules coexist. Nothing is broken.
5. Commit: "ironloop: <module>_v2 passes all 5 layers, ready for migration."

### E2. Migrate: cut over callers batch by batch

1. List every caller of the old module.
2. Migrate callers one batch at a time (per package, per directory).
   Each batch is its own commit.
3. After each batch: `cargo test` must stay green. Old module still
   exists, so failures are real regressions, not unfinished migrations.
4. If a batch can't stay green alone, land all batches on an integration
   branch and verify at the end.

### E3. Contract: delete the old module

1. Once zero callers reference the old module, delete it.
2. Run the full test suite one last time.
3. Commit: "ironloop: <module> rewritten, old module decommissioned."

### Wide refactors

When the blast radius fans across the entire codebase (e.g. renaming a
shared type), don't force it into tracer bullets. Use expand-contract:
add the new form, migrate callers in blast-radius batches, delete the
old form only when zero callers remain.

**Exit:** Zero legacy code. Every module is greenfield-verified.