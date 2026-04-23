Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$starterOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -List | Out-String
if ($starterOutput -notmatch 'PortUI Starter') { throw 'Starter output missing starter manifest name.' }
if ($starterOutput -notmatch 'Doctor \[doctor\]') { throw 'Starter output missing doctor action.' }

$listOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -ManifestDir .\examples\demo -List | Out-String
if ($listOutput -notmatch 'PortUI Demo') { throw 'List output missing manifest name.' }
if ($listOutput -notmatch 'Git Version') { throw 'List output missing Git Version action.' }

$gitOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -ManifestDir .\examples\demo -Run git-version | Out-String
if ($gitOutput -notmatch 'git version') { throw 'Git action output missing git version.' }

$doctorOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -ManifestDir .\examples\demo -Run doctor | Out-String
if ($doctorOutput -notmatch 'shell=PowerShell') { throw 'Doctor output missing shell marker.' }

$homeOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -ManifestDir .\examples\demo -Run show-home | Out-String
if ($homeOutput -notmatch 'pathSep=') { throw 'Show-home output missing pathSep.' }

$workspaceOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -ManifestDir .\examples\demo -Run list-workspace | Out-String
if ($workspaceOutput -notmatch 'Status: exit code 0') { throw 'List-workspace action did not exit cleanly.' }

$projectsOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -WorkspaceDir .\examples\workspace -ListProjects | Out-String
if ($projectsOutput -notmatch 'Alpha Workspace App \[alpha\]') { throw 'Workspace output missing alpha project.' }
if ($projectsOutput -notmatch 'Beta Hidden App \[beta\]') { throw 'Workspace output missing beta project.' }

$alphaListOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -WorkspaceDir .\examples\workspace -Project alpha -List | Out-String
if ($alphaListOutput -notmatch 'Alpha Doctor \[doctor\]') { throw 'Alpha project action list missing doctor.' }

$alphaDoctorOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -WorkspaceDir .\examples\workspace -Project alpha -Run doctor | Out-String
if ($alphaDoctorOutput -notmatch 'alpha=alpha') { throw 'Alpha doctor output missing alpha marker.' }
if ($alphaDoctorOutput -notmatch 'workspace=') { throw 'Alpha doctor output missing workspace marker.' }

$betaPingOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -WorkspaceDir .\examples\workspace -Project beta -Run ping | Out-String
if ($betaPingOutput -notmatch 'beta=beta') { throw 'Beta ping output missing beta marker.' }

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('portui-test-' + [System.Guid]::NewGuid().ToString('N'))
$projectDir = Join-Path $tempRoot 'engine-demo'
New-Item -ItemType Directory -Path (Join-Path $projectDir 'portui\actions') -Force | Out-Null
Copy-Item -LiteralPath .\examples\workspace\alpha\portui\manifest.env -Destination (Join-Path $projectDir 'portui\manifest.env') -Force
Copy-Item -LiteralPath .\examples\workspace\alpha\portui\actions\01-doctor.env -Destination (Join-Path $projectDir 'portui\actions\01-doctor.env') -Force

$installOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -InstallProject $projectDir | Out-String
if ($installOutput -notmatch 'Installed PortUI runtime into') { throw 'Install output missing success message.' }

$embeddedOutput = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectDir 'portui.ps1') -Run doctor | Out-String
if ($embeddedOutput -notmatch 'alpha=engine-demo') { throw 'Embedded project output missing project marker.' }

$initRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('portui-init-' + [System.Guid]::NewGuid().ToString('N'))
$ideaDir = Join-Path $initRoot 'idea'
New-Item -ItemType Directory -Path $ideaDir -Force | Out-Null

$initOutput = powershell -NoProfile -ExecutionPolicy Bypass -File .\portui.ps1 -InitProject $ideaDir | Out-String
if ($initOutput -notmatch 'Created starter PortUI app in') { throw 'Init output missing success message.' }
if (-not (Test-Path -LiteralPath (Join-Path $ideaDir 'portui\manifest.env'))) { throw 'Init did not create manifest.' }
if (-not (Test-Path -LiteralPath (Join-Path $ideaDir '.portui-runtime\portui.ps1'))) { throw 'Init did not create vendored runtime.' }

$initEmbeddedOutput = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ideaDir 'portui.ps1') -Run doctor | Out-String
if ($initEmbeddedOutput -notmatch 'project=idea') { throw 'Init project output missing project marker.' }

Remove-Item -LiteralPath $tempRoot -Recurse -Force
Remove-Item -LiteralPath $initRoot -Recurse -Force

Write-Host 'PowerShell smoke tests passed.'
