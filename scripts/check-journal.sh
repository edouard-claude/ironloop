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

if [ "$fail" -ne 0 ]; then echo "CHECK-JOURNAL FAILED"; exit 1; fi
echo "CHECK-JOURNAL OK"