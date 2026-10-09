# Contributing

This is the Swift port of the NepDate family. Data and behaviour come from the hub
([`sanamhub/nepdate`](https://github.com/sanamhub/nepdate)), copied read-only into `shared/`.
[`AGENTS.md`](AGENTS.md) holds the rules for every change, from people and agents alike: read it
first.

## Checks

Swift 6.0 or later. Before a PR, run `./scripts/ci.sh` (macOS, Linux) or `./scripts/ci.ps1`
(Windows, PowerShell 7). The last line reads `ci: 7/7 gates passed`.

## Commits and PRs

- [Conventional Commits](https://www.conventionalcommits.org/) with the task ID first when there is
  one (`feat(nepdate): S1-03 serial conversion`). One task per PR; fill in the PR template.
- Prose, comments and commit messages follow
  [`.claude/skills/writing-style/SKILL.md`](.claude/skills/writing-style/SKILL.md), with no AI
  attribution lines.
- Never edit `shared/` or a `*.generated.swift` file by hand.

By contributing you agree that your contribution is licensed under the MIT license
([LICENSE](LICENSE)).
