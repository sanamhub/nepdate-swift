# Runbook: release `nepdate-swift`

Decided in ADR-0005. Owner: maintainer. Approver: a second person.

1. `main` is green: `./scripts/ci.sh` passes on macOS and Linux, `./scripts/ci.ps1` on Windows. The
   Linux job also builds the pushed commit from its GitHub URL (`scripts/verify-published.sh
   --revision`), so a package that only builds from a local checkout is caught before the tag.
2. `CHANGELOG.md` has `## [X.Y.Z] - YYYY-MM-DD`, moved out of `[Unreleased]`. The one tag releases
   both products, `NepDate` and `NepDatePatro`. `bash scripts/release-check.sh X.Y.Z` checks the
   version and the section locally.
3. Optional dry run: run `release.yml` from the Actions tab with the version. It runs the preflight
   and CI and creates nothing.
4. Tag and push (no `v` prefix, the SwiftPM convention):

   ```bash
   git tag -s X.Y.Z -m "X.Y.Z"
   git push origin X.Y.Z
   ```

5. Approve the `production` environment in `release.yml`. It creates the GitHub Release from the
   changelog section, then calls `verify-published.yml`, which builds a fresh package depending on
   `.exact("X.Y.Z")` on macOS, Linux and Windows and compares the Examples output with the tagged
   checkout. It can be run by hand from the Actions tab for any released tag.
6. Check the Swift Package Index page shows the version and its build matrix (Apple, Linux, Android,
   Wasm) is green. The first release is added once by hand at
   <https://swiftpackageindex.com/add-a-package>.
7. Add an empty `## [Unreleased]` to the changelog.

## Pre-releases

A tag such as `0.1.0-beta.1` goes through the same steps. Its changelog section is
`## [0.1.0-beta.1] - YYYY-MM-DD`; a stable section does not satisfy a pre-release tag and the other
way round. The GitHub Release is marked as a pre-release. SwiftPM never picks a pre-release for a
`from:` requirement unless the requirement itself names one, so users opt in with
`exact: "0.1.0-beta.1"` or `from: "0.1.0-beta.1"`.

Rolling back: never move or delete a tag. Release `X.Y.(Z+1)` with the fix and note it.
