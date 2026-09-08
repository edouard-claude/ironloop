# IRONLOOP — Verification-First Agent Skill
#
# Load this file as your agent's project context, or install via:
#   npx skills add edouard-claude/ironloop
#
# The main skill is at skills/engineering/ironloop/SKILL.md
# Read it first, then follow the workflow files.

## Project Identity

This project implements IRONLOOP: a 5-layer verification harness for
AI-assisted software engineering. Code is disposable, the harness is
permanent.

## Language

Default to Rust for all new projects. Existing Go projects stay on Go.

## Key Files

- skills/engineering/ironloop/SKILL.md — Main system prompt
- skills/engineering/ironloop/greenfield.md — New project workflow
- skills/engineering/ironloop/brownfield.md — Legacy migration workflow
- skills/engineering/ironloop/triggers.md — When to activate each layer