#!/usr/bin/env pwsh
# Runs the gates of ADR-0004 in order, stops at the first failure and ends with one summary line.
# Mirrors scripts/ci.sh step for step; change both together. PowerShell 7, no WSL.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Invoke-Step {
  param([string] $Command, [string[]] $Arguments)
  Write-Host "+ $Command $($Arguments -join ' ')"
  # Out-Host keeps the command's output off the pipeline, so the function returns only the bool.
  & $Command @Arguments | Out-Host
  return $LASTEXITCODE -eq 0
}

function Gate-Format {
  Invoke-Step swift @('format', 'lint', '--strict', '--recursive', 'Sources', 'Tests')
}

function Gate-Build {
  Invoke-Step swift @('build', '-c', 'release', '-Xswiftc', '-warnings-as-errors',
    '--explicit-target-dependency-import-check', 'error')
}

function Gate-BuildCore {
  Invoke-Step swift @('build', '--target', 'NepDate')
}

function Gate-Test {
  # Coverage is enforced on Linux only (ADR-0004, CI jobs), so Windows runs the tests alone.
  if (-not (Invoke-Step swift @('test'))) { return $false }
  Write-Host 'coverage threshold: skipped (Linux only)'
  return $true
}

function Gate-Codegen {
  Invoke-Step swift @('run', '--package-path', 'Tools/Codegen', 'codegen', '--check')
}

function Gate-PatroFree {
  Write-Host 'skipped (the World Day Against Human Trafficking check runs on Linux)'
  return $true
}

function Gate-Api {
  Write-Host 'skipped (starts with 0.1.1)'
  return $true
}

$gates = @(
  @{ Name = 'format'; Run = { Gate-Format } },
  @{ Name = 'build'; Run = { Gate-Build } },
  @{ Name = 'build-core'; Run = { Gate-BuildCore } },
  @{ Name = 'test'; Run = { Gate-Test } },
  @{ Name = 'codegen'; Run = { Gate-Codegen } },
  @{ Name = 'patro-free'; Run = { Gate-PatroFree } },
  @{ Name = 'api'; Run = { Gate-Api } }
)

for ($i = 0; $i -lt $gates.Count; $i++) {
  $n = $i + 1
  $name = $gates[$i].Name
  Write-Host "== gate $n/$($gates.Count): $name"
  $ok = & $gates[$i].Run
  if ($ok -ne $true) {
    Write-Host "ci: failed at gate ${n}: $name"
    exit 1
  }
}
Write-Host "ci: $($gates.Count)/$($gates.Count) gates passed"
