# Triggers: When to Activate Each Layer

| Trigger | L1: SPEC | L2: GEN | L3: TEST | L4: SIM | L5: PENTEST |
|---------|:--------:|:-------:|:--------:|:-------:|:-----------:|
| New greenfield project | ✓ | ✓ | ✓ | ✓¹ | ✓² |
| Feature on existing code | ✓ | ✓ | ✓ | - | - |
| Bug fix (prod incident) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bug fix (non-critical) | ✓ | ✓ | ✓ | - | - |
| Refacto (interface change) | ✓ | ✓ | ✓ | - | - |
| Migration (langage/framework) | ✓ | ✓ | ✓ | ✓¹ | ✓² |
| Proto / POC (< 1 week) | ✓ | ✓ | - | - | - |
| Hotfix urgent (< 2h) | - | ✓ | ✓ | - | ✓³ |
| Dependency update (minor) | - | - | ✓ | - | - |
| Dependency update (major) | ✓ | ✓ | ✓ | ✓¹ | ✓² |
| Config change | - | - | ✓ | ✓¹ | - |

¹ If the system is distributed or handles data integrity.
² If the system has network exposure or parses user input.
³ Pentest on the hotfix path only, defer full surface to post-incident.

## Key Principle

> **A bug in production is proof that the harness failed.**

Every prod incident means: at least one layer didn't catch this.
After the fix:
1. Write the test that would have caught it (Layer 3)
2. Add the failure scenario to simulation (Layer 4)
3. Add the attack vector to pentest (Layer 5)
4. Update the spec if the expected behavior was wrong (Layer 1)

This is how the harness gets stronger over time.

## Layer Budget by Project Type

| Project Type | Gen Tokens | Test/Verify Tokens | Ratio |
|-------------|-----------|-------------------|-------|
| Internal CLI tool | 30% | 70% | 1:2.3 |
| API service | 20% | 80% | 1:4 |
| Distributed system | 10% | 90% | 1:9 |
| Auth/crypto module | 5% | 95% | 1:19 |

The more critical the system, the more verification budget.
If your ratio is inverted, you're doing it wrong.

## Measuring the Ratio

The ratio is a measurement, not a slogan, which means it has to come from
something countable. Per-layer token accounting is not visible to the
agent from inside a run: if your runtime exposes it, count tokens per
layer (generation = every agent turn in Layer 2 including compiler-fix
loops; verification = every agent turn in Layers 3 and 5, plus test and
mutation generation loops) and compare against the table above. If it
does not, do not estimate the ratio and do not assert it. Count the
proxy instead.

**The verification ledger.** Four numbers, all mechanically obtainable
at task close:

| Number | Where it comes from |
|--------|---------------------|
| `gen-lines` | Lines added to non-test sources in the task's diff |
| `ver-lines` | Lines added to tests, corpora, specifications, gate configuration |
| `assertions` | Assertion count in the added tests, over public items generated |
| `gate-runs` | `loop` lines in `ironloop.log`, per layer |

`ver-lines / gen-lines` is the proxy ratio, read against the same table.
It is coarser than tokens and it is honest, which is the trade that
matters: a declared ratio nobody can check is worth less than a crude
one anybody can recompute from the diff.

Report the ledger and the ratio in the PR description under
`ironloop-ratio:`, and name which measure it is (`tokens` or `ledger`).
A PR without a ratio is not closed. Layer 4 is CPU, not tokens; report
its wall-clock time separately.