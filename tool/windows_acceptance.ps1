$ErrorActionPreference = 'Stop'

# Run from the repository root on Windows. The patched Flutter tool snapshot
# may be supplied by the caller; otherwise use the installed Flutter tool.
$appDir = Join-Path $PSScriptRoot '..\apps\flutter_forge'
$generator = 'NMake Makefiles'
$env:FLUTTER_WINDOWS_CMAKE_GENERATOR = $generator
$env:CMAKE_GENERATOR = $generator

function Invoke-Flutter {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  $snapshot = $env:FLUTTER_TOOL_SNAPSHOT
  if ($snapshot -and (Test-Path -LiteralPath $snapshot)) {
    $flutterRoot = Split-Path (Split-Path $snapshot -Parent) -Parent
    $packages = Join-Path $flutterRoot 'packages\flutter_tools\.dart_tool\package_config.json'
    & dart --packages=$packages $snapshot @Arguments
  } else {
    & flutter @Arguments
  }
  if ($LASTEXITCODE -ne 0) { throw "Flutter command failed with exit code $LASTEXITCODE" }
}

# Do not terminate processes by executable name: they may belong to another
# checkout or to the user. This harness does not start a child process that it
# needs to clean up, so no process termination is required here.
$existingProcesses = Get-Process -Name 'flutter','dart','flutter_tester' -ErrorAction SilentlyContinue |
  Select-Object Id, ProcessName, StartTime
if ($existingProcesses) {
  Write-Host 'Existing Flutter-related processes (left untouched):'
  $existingProcesses | Format-Table -AutoSize | Out-String | Write-Host
} else {
  Write-Host 'No existing Flutter-related processes found.'
}

Push-Location $appDir
try {
  Invoke-Flutter clean
  Invoke-Flutter pub get
  Invoke-Flutter build windows --release
  Invoke-Flutter test integration_test/windows_acceptance_test.dart -d windows
}
finally {
  Pop-Location
}
