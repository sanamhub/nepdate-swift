# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are SwiftPM tags without a `v`
prefix (ADR-0005).

## [Unreleased]

### Added

- SwiftPM package `NepDate` with product `NepDate` (S0-01).
- `Tools/Codegen` package: `codegen` writes `Calendar.generated.swift` from `shared/data`, `--check` fails on drift (S0-02).
- `scripts/ci.sh` and `scripts/ci.ps1` run the seven gates of ADR-0004; `coverage-check` enforces 90 % line coverage on Linux (S0-03).
