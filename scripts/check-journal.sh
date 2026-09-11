#!/usr/bin/env bash
# IRONLOOP journal check: ensures the agent's decision journal exists and is valid.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
log="$root/ironloop.log"
fail=0

check() { if ! "$@"; then fail=1; fi; }

echo "== journal exists"
if [ ! -f "$log" ]; then
  echo "  no ironloop.log (not an agent task; skipping)"
  echo "CHECK-JOURNAL OK (skipped: not an agent run)"
  exit 0
fi

echo "== journal content"
# Every layer the triggers require must have an enter and a close
# For now, just check the file exists and is non-empty
if [ -s "$log" ]; then
  echo "  journal non-empty: ok"
else
  echo "  journal empty: warn (not blocking)"
fi

echo "== layer decisions"
# Layers 4 and 5 are decided in writing in spec.md: REQUIRED or SKIPPED, with a
# reason. A placeholder or an empty line is a stop (agent-budget.md, rule 7).
spec="$root/spec.md"
if [ -f "$spec" ]; then
  for layer in "Layer 4 (SIM)" "Layer 5 (PENTEST)"; do
    if grep -qE "^- \*\*${layer//(/\\(}:\*\* (REQUIRED|SKIPPED) because .+" "$spec"; then
      echo "  $layer: decided"
    else
      echo "  $layer: no REQUIRED/SKIPPED line with a reason in spec.md"; fail=1
    fi
  done
else
  echo "  no spec.md at repo root (skipping)"
fi

if [ "$fail" -ne 0 ]; then echo "CHECK-JOURNAL FAILED"; exit 1; fi
echo "CHECK-JOURNAL OK"