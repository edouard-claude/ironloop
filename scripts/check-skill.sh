#!/usr/bin/env bash
# IRONLOOP self-check: the harness verifies its own structure.
# Gates: frontmatter present, SKILL.md < 500 lines, every relative link resolves.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
skill="$root/skills/engineering/ironloop"
fail=0

check() { if ! "$@"; then fail=1; fi; }

echo "== frontmatter"
check grep -q '^name: ironloop$' "$skill/SKILL.md"
check grep -q '^description: ' "$skill/SKILL.md"
check grep -q '^  version: "' "$skill/SKILL.md"

echo "== SKILL.md length"
lines=$(wc -l < "$skill/SKILL.md")
if [ "$lines" -ge 500 ]; then echo "SKILL.md has $lines lines (limit 500)"; fail=1; fi

echo "== relative links"
while IFS= read -r file; do
  dir="$(dirname "$file")"
  links=$(grep -oE '\]\(([^)#]+)' "$file" | sed -E 's/^\]\(//' | grep -vE '^(https?:|mailto:)' || true)
  for link in $links; do
    if [ ! -e "$dir/$link" ]; then echo "broken link in $file: $link"; fail=1; fi
  done
done < <(find "$root" -name '*.md' -not -path '*/.git/*')

echo "== expected assets"
for f in assets/spec.md assets/lints.toml assets/sim.yaml references/1-spec.md references/2-gen.md references/3-test.md references/4-sim.md references/5-pentest.md references/cost.md references/agent-budget.md greenfield.md brownfield.md triggers.md; do
  [ -f "$skill/$f" ] || { echo "missing $f"; fail=1; }
done

if [ "$fail" -ne 0 ]; then echo "SELF-CHECK FAILED"; exit 1; fi
echo "SELF-CHECK OK"
