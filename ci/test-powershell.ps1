Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$listOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -List | Out-String
if ($listOutput -notmatch 'PortUI Demo') { throw 'List output missing manifest name.' }
if ($listOutput -notmatch 'Git Version') { throw 'List output missing Git Version action.' }

$gitOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -Run git-version | Out-String
if ($gitOutput -notmatch 'git version') { throw 'Git action output missing git version.' }

$doctorOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -Run doctor | Out-String
if ($doctorOutput -notmatch 'shell=PowerShell') { throw 'Doctor output missing shell marker.' }

$homeOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -Run show-home | Out-String
if ($homeOutput -notmatch 'pathSep=') { throw 'Show-home output missing pathSep.' }

$workspaceOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -Run list-workspace | Out-String
if ($workspaceOutput -notmatch 'Status: exit code 0') { throw 'List-workspace action did not exit cleanly.' }

Write-Host 'PowerShell smoke tests passed.'

