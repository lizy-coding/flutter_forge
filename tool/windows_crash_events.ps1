param(
  [Parameter(Mandatory=$true)][string]$Executable,
  [Parameter(Mandatory=$true)][datetime]$StartedAt,
  [Parameter(Mandatory=$true)][string]$ProcessIds
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$ids = @($ProcessIds.Split(',') | ForEach-Object { [long]$_ })
Start-Sleep -Seconds 5
$events = @(Get-WinEvent -FilterHashtable @{
  LogName='Application'; ProviderName='Application Error'; Id=1000; StartTime=$StartedAt
} -ErrorAction SilentlyContinue -ErrorVariable readErrors)
foreach ($readError in $readErrors) {
  if ($readError.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw $readError }
}
$matches = @($events | Where-Object {
  $fields = @{}
  ([xml]$_.ToXml()).Event.EventData.Data | ForEach-Object { $fields[$_.Name] = $_.InnerText }
  $eventProcess = if ($fields['ProcessId']) { [Convert]::ToInt64(($fields['ProcessId'] -replace '^0x',''),16) } else { -1 }
  $fields['AppPath'] -ieq $Executable -and $eventProcess -in $ids
} | ForEach-Object { @{recordId=$_.RecordId; time=$_.TimeCreated.ToString('o'); message=$_.Message} })
@{matches=$matches; checkedAt=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 5 -Compress
