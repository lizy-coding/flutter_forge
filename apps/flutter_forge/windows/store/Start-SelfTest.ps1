# Local convenience wrapper. Does not change execution policy, trust, or installation.
param(
    [ValidateSet('check', 'run', 'report')][string]$Mode = 'check',
    [string]$Output,
    [ValidateSet('installed', 'user-exe')][string]$Target = 'user-exe',
    [ValidateSet('physical-x64', 'vm-x64', 'arm64-emulation', 'unknown')][string]$DeviceKind = 'unknown',
    [switch]$ManualStartMenu
)
$ErrorActionPreference = 'Stop'
$python = Join-Path $PSScriptRoot '.selftest-venv/Scripts/python.exe'
$prefix = @()
if (-not (Test-Path -LiteralPath $python)) {
    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if (-not $launcher) { throw 'Python launcher not found. Follow START_HERE.md; manual testing needs no Python.' }
    $python = $launcher.Source
    $prefix = @('-3')
}
$tool = Join-Path $PSScriptRoot 'recheck-tools/windows_self_test.py'
if (-not (Test-Path -LiteralPath $tool)) { throw 'Extract the complete candidate artifact first.' }
$arguments = $prefix + @($tool, $Mode, '--bundle', $PSScriptRoot, '--device-kind', $DeviceKind, '--target', $Target)
if ($Output) { $arguments += @('--output', $Output) }
if ($ManualStartMenu) { $arguments += '--manual-start-menu' }
& $python @arguments
exit $LASTEXITCODE
