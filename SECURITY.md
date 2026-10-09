# Security policy

`NepDate` and `NepDatePatro` do no I/O and hold no secrets; a security problem is most likely a
crash on crafted input to `parse` or `parseLenient`, or a problem in a workflow
(`.github/workflows/`).

## Reporting a vulnerability

Report privately through
[GitHub security advisories](https://github.com/sanamhub/nepdate-swift/security/advisories/new).
Don't open a public issue. Expect a first reply within a week.

Say which version is affected and how to reproduce it. A wrong date, holiday or tithi isn't a
security problem: open a bug report.
