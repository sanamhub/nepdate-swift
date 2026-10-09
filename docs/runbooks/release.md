# Runbook: release `nepdate-swift`

Decided in ADR-0005. Owner: maintainer. Approver: a second person.

1. `main` is green: `./scripts/ci.sh` passes on macOS and Linux, `./scripts/ci.ps1` on Windows.
2. `CHANGELOG.md` has `## [X.Y.Z] - YYYY-MM-DD`, moved out of `[Unreleased]`. The one tag releases
   both products, `NepDate` and `NepDatePatro`.
3. Tag and push (no `v` prefix, the SwiftPM convention):

   ```bash
   git tag -s X.Y.Z -m "X.Y.Z"
   git push origin X.Y.Z
   ```

4. Approve the `production` environment in `release.yml`; it creates the GitHub Release.
5. Check the Swift Package Index page shows the version and its build matrix (Apple, Linux, Android,
   Wasm) is green.
6. Add an empty `## [Unreleased]` to the changelog.

Rolling back: never move or delete a tag. Release `X.Y.(Z+1)` with the fix and note it.
