# ADR-0007: docs-check checks em dashes and links only

- **Status:** accepted
- **Date:** 2026-10-19
- **Approved by:** Sanam

## Context

`docs-check` (ADR-0004, gate 8) also rejected internal task IDs in the pages a user reads. Task IDs
no longer appear anywhere in the repository, so the rule had nothing left to guard, and it named an
internal convention in a public tool.

## Decision

`docs-check` checks two things in `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`
and the top-level `docs/*.md` pages: no em dash, and every relative link resolves. ADR-0004 gate 8
is amended to match.

## Consequences

The CI step that proves `docs-check` fails now covers the em dash and the broken link.
