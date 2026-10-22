param(
  [Parameter(Mandatory = $true)][string]$Executable,
  [ValidateRange(1, 1000)][int]$Iterations = 20,
  [ValidateRange(1, 60)][int]$StartupSeconds = 3,
  [ValidateRange(1, 120)][int]$ExitTimeoutSeconds = 15
)

# Standalone Windows Release regression. This does not replace real caption,
# Alt+F4, multi-window, or ProcDump first-chance acceptance.
$ErrorActionPreference = 'Stop'
$exePath = (Resolve-Path -LiteralPath $Executable).Path
$startedAt = Get-Date
$runs = @()

if (-not ('ForgeCloseSmoke' -as [type])) {
  Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ForgeCloseSmoke {
  [DllImport("user32.dll", SetLastError = true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wp, IntPtr lp);
}
'@
}

for ($i = 0; $i -lt $Iterations; $i++) {
  $process = Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(30)
    do {
      Start-Sleep -Milliseconds 100
      $process.Refresh()
      if ($process.HasExited) { throw "Startup exited early: PID $($process.Id), code $($process.ExitCode)" }
    } while ($process.MainWindowHandle -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline)
    if ($process.MainWindowHandle -eq [IntPtr]::Zero) { throw 'No main HWND within 30 seconds' }

    # Allow bootstrap to settle; an HWND alone does not prove visible content.
    Start-Sleep -Seconds $StartupSeconds
    $process.Refresh()
    if ($process.HasExited) { throw 'Process exited before the close request' }
    $systemClose = ($i % 2) -eq 1
    $message = if ($systemClose) { 0x0112 } else { 0x0010 } # WM_SYSCOMMAND / WM_CLOSE
    $command = if ($systemClose) { 0xF060 } else { 0 }      # SC_CLOSE
    if (-not [ForgeCloseSmoke]::PostMessage($process.MainWindowHandle, $message, [IntPtr]$command, [IntPtr]::Zero)) {
      throw "Close request failed: Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    }
    if (-not $process.WaitForExit($ExitTimeoutSeconds * 1000)) { throw 'Close timed out' }
    $exitCode = $process.ExitCode
    $runs += [pscustomobject]@{ pid = $process.Id; systemClose = $systemClose; exitCode = $exitCode }
    if ($exitCode -ne 0) { throw "Abnormal exit: PID $($process.Id), code $exitCode" }
    Write-Host "Closed $($i + 1)/$Iterations, PID $($process.Id), exit 0"
  } finally {
    # Only clean up this script's own process on failure.
    if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    $process.Dispose()
  }
}

# WER can be written after process exit. Event-log access failures must fail the
# check, rather than being interpreted as an empty (passing) event list.
Start-Sleep -Seconds 5
$events = @(Get-WinEvent -FilterHashtable @{
  LogName = 'Application'; ProviderName = 'Application Error'; Id = 1000; StartTime = $startedAt
} -ErrorAction SilentlyContinue -ErrorVariable eventErrors)
foreach ($eventError in $eventErrors) {
  if ($eventError.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw $eventError }
}
$crashes = @($events | Where-Object {
  $fields = @{}
  ([xml]$_.ToXml()).Event.EventData.Data | ForEach-Object { $fields[$_.Name] = $_.InnerText }
  $eventPid = 0L
  if ($fields['ProcessId']) {
    $eventPid = [Convert]::ToInt64(($fields['ProcessId'] -replace '^0x', ''), 16)
  }
  $fields['AppPath'] -ieq $exePath -and $eventPid -in $runs.pid
})
if ($crashes.Count -gt 0) {
  $crashes | Format-List TimeCreated, Message | Out-Host
  throw "Application Error recorded for a tested process: $($crashes.Count)"
}

[pscustomobject]@{
  status = 'PASS'
  scope = 'WM_CLOSE and SC_CLOSE; exit code and Application Error 1000 within observation interval'
  executable = $exePath
  sha256 = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
  startedAt = $startedAt.ToString('o')
  checkedAt = (Get-Date).ToString('o')
  runs = $runs
} | ConvertTo-Json -Depth 4
