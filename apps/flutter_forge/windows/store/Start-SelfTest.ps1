# Local convenience wrapper. Does not change execution policy, trust, or installation.
param(
    [ValidateSet('check', 'run', 'report')][string]$Mode = 'check',
    [string]$Output,
    [ValidateSet('installed', 'user-exe')][string]$Target = 'user-exe',
    [ValidateSet('physical-x64', 'vm-x64', 'arm64-emulation', 'unknown')][string]$DeviceKind = 'unknown',
    [switch]$ManualStartMenu
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command py -ErrorAction SilentlyContinue)) {
    throw 'Python launcher not found. Follow START_HERE.md; manual testing needs no Python.'
}
$tool = Join-Path $PSScriptRoot 'recheck-tools/windows_self_test.py'
if (-not (Test-Path -LiteralPath $tool)) { throw 'Extract the complete candidate artifact first.' }
$arguments = @('-3', $tool, $Mode, '--bundle', $PSScriptRoot, '--device-kind', $DeviceKind, '--target', $Target)
if ($Output) { $arguments += @('--output', $Output) }
if ($ManualStartMenu) { $arguments += '--manual-start-menu' }
& py @arguments
exit $LASTEXITCODE
