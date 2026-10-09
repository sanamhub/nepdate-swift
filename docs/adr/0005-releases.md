# ADR-0005: Releases

- Status: Accepted
- Date: 2026-10-06
- Deciders: Sanam Pakuwal

## Decision

- SwiftPM resolves versions from git tags: semver tags `X.Y.Z` (no `v` prefix, the SwiftPM
  convention). `CHANGELOG.md` (Keep a Changelog).
- `NepDate` and `NepDatePatro` are products of one package, so one tag releases both at the same
  version (hub ADR-0004 §3). A data update that only touches the patro is still a patch release of
  the package.
- `release.yml` on tag: preflight (the tag is semver without `v` and `CHANGELOG.md` has a
  `## [X.Y.Z]` section for it; SwiftPM has no version field to compare), CI, `environment:
  production` approval, GitHub Release with notes from the changelog. No artefact to publish; the
  Swift Package Index picks up the tag.
- Register the package on the Swift Package Index once (human task).
- Never move or delete a published tag. A bad release is fixed by a new patch tag and a changelog
  note.
- The weekly `shared-sync` PR, once merged, is released as a patch version.
