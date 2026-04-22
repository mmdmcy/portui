param(
    [string]$ManifestDir = (Join-Path $PSScriptRoot 'examples/demo'),
    [switch]$List,
    [string]$Run
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Variables = @{}

function Set-PortUIVariable {
    param(
        [string]$Name,
        [string]$Value
    )

    if ($Name -notmatch '^[A-Za-z0-9_]+$') {
        throw "Invalid variable name: $Name"
    }

    $script:Variables[$Name] = $Value
}

function Expand-PortUIText {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    $expanded = $Text
    for ($pass = 0; $pass -lt 8; $pass++) {
        $changed = $false
        foreach ($entry in $script:Variables.GetEnumerator()) {
            $token = '{{' + $entry.Key + '}}'
            $updated = $expanded.Replace($token, [string]$entry.Value)
            if ($updated -ne $expanded) {
                $expanded = $updated
                $changed = $true
            }
        }

        if (-not $changed) {
            break
        }
    }

    return $expanded
}

function Get-KeyValueData {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing file: $Path"
    }

    $map = @{}
    foreach ($rawLine in [System.IO.File]::ReadAllLines($Path)) {
        $line = $rawLine.TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }

        $splitIndex = $line.IndexOf('=')
        if ($splitIndex -lt 0) {
            continue
        }

        $key = $line.Substring(0, $splitIndex)
        $value = $line.Substring($splitIndex + 1)
        $map[$key] = $value
    }

    return $map
}

function Get-HostOSName {
    if ($env:OS -eq 'Windows_NT') { return 'windows' }

    try {
        $runtime = [System.Runtime.InteropServices.RuntimeInformation]
        if ($runtime::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) { return 'macos' }
        if ($runtime::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) { return 'linux' }
    } catch {
    }

    return 'unknown'
}

function Initialize-Builtins {
    param(
        [string]$ResolvedManifestDir
    )

    $homeDir = [Environment]::GetFolderPath('UserProfile')
    $cwd = (Get-Location).Path
    $osName = Get-HostOSName

    Set-PortUIVariable -Name 'home' -Value $homeDir
    Set-PortUIVariable -Name 'cwd' -Value $cwd
    Set-PortUIVariable -Name 'os' -Value $osName
    Set-PortUIVariable -Name 'manifestDir' -Value $ResolvedManifestDir

    if ($osName -eq 'windows') {
        Set-PortUIVariable -Name 'pathSep' -Value '\'
        Set-PortUIVariable -Name 'listSep' -Value ';'
        Set-PortUIVariable -Name 'exeSuffix' -Value '.exe'
    } else {
        Set-PortUIVariable -Name 'pathSep' -Value '/'
        Set-PortUIVariable -Name 'listSep' -Value ':'
        Set-PortUIVariable -Name 'exeSuffix' -Value ''
    }
}

function Load-Manifest {
    param(
        [string]$ResolvedManifestDir
    )

    $manifestPath = Join-Path $ResolvedManifestDir 'manifest.env'
    $data = Get-KeyValueData -Path $manifestPath
    $manifest = @{
        Name = 'PortUI'
        Description = ''
    }

    foreach ($entry in $data.GetEnumerator()) {
        switch -Wildcard ($entry.Key) {
            'NAME' { $manifest.Name = $entry.Value }
            'DESCRIPTION' { $manifest.Description = $entry.Value }
            'VARIABLE_*' {
                $variableName = $entry.Key.Substring('VARIABLE_'.Length)
                Set-PortUIVariable -Name $variableName -Value $entry.Value
            }
        }
    }

    $keys = @($script:Variables.Keys)
    foreach ($key in $keys) {
        Set-PortUIVariable -Name $key -Value (Expand-PortUIText $script:Variables[$key])
    }

    return $manifest
}

function New-Variant {
    return @{
        Program = ''
        Args = ''
        Cwd = ''
        Env = @{}
    }
}

function Load-Action {
    param(
        [string]$Path
    )

    $action = @{
        ID = ''
        Title = ''
        Description = ''
        TimeoutSeconds = 30
        Base = New-Variant
        Posix = New-Variant
        Linux = New-Variant
        MacOS = New-Variant
        Windows = New-Variant
        Path = $Path
    }

    $data = Get-KeyValueData -Path $Path
    foreach ($entry in $data.GetEnumerator()) {
        $key = $entry.Key
        $value = $entry.Value

        switch -Wildcard ($key) {
            'ID' { $action.ID = $value }
            'TITLE' { $action.Title = $value }
            'DESCRIPTION' { $action.Description = $value }
            'TIMEOUT_SECONDS' {
                $parsed = 0
                if ([int]::TryParse($value, [ref]$parsed) -and $parsed -gt 0) {
                    $action.TimeoutSeconds = $parsed
                }
            }
            'PROGRAM' { $action.Base.Program = $value }
            'ARGS' { $action.Base.Args = $value }
            'CWD' { $action.Base.Cwd = $value }
            'ENV_*' { $action.Base.Env[$key.Substring(4)] = $value }
            'POSIX_PROGRAM' { $action.Posix.Program = $value }
            'POSIX_ARGS' { $action.Posix.Args = $value }
            'POSIX_CWD' { $action.Posix.Cwd = $value }
            'POSIX_ENV_*' { $action.Posix.Env[$key.Substring(10)] = $value }
            'LINUX_PROGRAM' { $action.Linux.Program = $value }
            'LINUX_ARGS' { $action.Linux.Args = $value }
            'LINUX_CWD' { $action.Linux.Cwd = $value }
            'LINUX_ENV_*' { $action.Linux.Env[$key.Substring(10)] = $value }
            'MACOS_PROGRAM' { $action.MacOS.Program = $value }
            'MACOS_ARGS' { $action.MacOS.Args = $value }
            'MACOS_CWD' { $action.MacOS.Cwd = $value }
            'MACOS_ENV_*' { $action.MacOS.Env[$key.Substring(10)] = $value }
            'WINDOWS_PROGRAM' { $action.Windows.Program = $value }
            'WINDOWS_ARGS' { $action.Windows.Args = $value }
            'WINDOWS_CWD' { $action.Windows.Cwd = $value }
            'WINDOWS_ENV_*' { $action.Windows.Env[$key.Substring(12)] = $value }
        }
    }

    if ([string]::IsNullOrWhiteSpace($action.ID)) {
        throw "Action file is missing ID: $Path"
    }
    if ([string]::IsNullOrWhiteSpace($action.Title)) {
        $action.Title = $action.ID
    }

    return $action
}

function Get-ActionFiles {
    param(
        [string]$ResolvedManifestDir
    )

    $actionsDir = Join-Path $ResolvedManifestDir 'actions'
    if (-not (Test-Path -LiteralPath $actionsDir)) {
        throw "Missing actions directory: $actionsDir"
    }

    return Get-ChildItem -LiteralPath $actionsDir -Filter '*.env' -File | Sort-Object Name
}

function Merge-Variant {
    param(
        [hashtable]$Resolved,
        [hashtable]$Variant,
        [string]$Label
    )

    $hasChanges = $false

    if (-not [string]::IsNullOrWhiteSpace($Variant.Program)) {
        $Resolved.Program = $Variant.Program
        $hasChanges = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($Variant.Args)) {
        $Resolved.Args = $Variant.Args
        $hasChanges = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($Variant.Cwd)) {
        $Resolved.Cwd = $Variant.Cwd
        $hasChanges = $true
    }
    foreach ($key in $Variant.Env.Keys) {
        $Resolved.Env[$key] = $Variant.Env[$key]
        $hasChanges = $true
    }

    if ($hasChanges) {
        $Resolved.Source += " -> $Label"
    }
}

function Resolve-Action {
    param(
        [hashtable]$Action
    )

    $osName = Get-HostOSName
    $resolved = @{
        Program = $Action.Base.Program
        Args = $Action.Base.Args
        Cwd = $Action.Base.Cwd
        Env = @{}
        Source = 'base'
    }

    foreach ($key in $Action.Base.Env.Keys) {
        $resolved.Env[$key] = $Action.Base.Env[$key]
    }

    if ($osName -ne 'windows') {
        Merge-Variant -Resolved $resolved -Variant $Action.Posix -Label 'posix'
    }

    switch ($osName) {
        'linux' { Merge-Variant -Resolved $resolved -Variant $Action.Linux -Label 'linux' }
        'macos' { Merge-Variant -Resolved $resolved -Variant $Action.MacOS -Label 'macos' }
        'windows' { Merge-Variant -Resolved $resolved -Variant $Action.Windows -Label 'windows' }
    }

    if ([string]::IsNullOrWhiteSpace($resolved.Program)) {
        throw "Action $($Action.ID) does not resolve to a runnable program on $osName"
    }

    $resolved.Program = Expand-PortUIText $resolved.Program
    $resolved.Args = Expand-PortUIText $resolved.Args
    if ([string]::IsNullOrWhiteSpace($resolved.Cwd)) {
        $resolved.Cwd = (Get-Location).Path
    } else {
        $resolved.Cwd = Expand-PortUIText $resolved.Cwd
    }

    $expandedEnv = @{}
    foreach ($key in $resolved.Env.Keys) {
        $expandedEnv[$key] = Expand-PortUIText $resolved.Env[$key]
    }
    $resolved.Env = $expandedEnv

    return $resolved
}

function Split-Args {
    param(
        [string]$ArgsString
    )

    if ([string]::IsNullOrWhiteSpace($ArgsString)) {
        return @()
    }

    return @($ArgsString.Split('|'))
}

function Quote-CommandPart {
    param(
        [string]$Value
    )

    if ([string]::IsNullOrEmpty($Value)) {
        return '""'
    }

    if ($Value -match '[^A-Za-z0-9_\./:=+\-]') {
        return '"' + ($Value -replace '"', '\"') + '"'
    }

    return $Value
}

function Format-DisplayCommand {
    param(
        [hashtable]$Resolved
    )

    $parts = @((Quote-CommandPart $Resolved.Program))
    foreach ($arg in (Split-Args $Resolved.Args)) {
        $parts += Quote-CommandPart $arg
    }
    return ($parts -join ' ')
}

function Build-ArgumentString {
    param(
        [string[]]$Args
    )

    $parts = @()
    foreach ($arg in $Args) {
        if ([string]::IsNullOrEmpty($arg)) {
            $parts += '""'
        } elseif ($arg -match '[\s"]') {
            $parts += '"' + ($arg -replace '"', '\"') + '"'
        } else {
            $parts += $arg
        }
    }

    return ($parts -join ' ')
}

function Invoke-ResolvedAction {
    param(
        [hashtable]$Action,
        [hashtable]$Resolved
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Resolved.Program
    $psi.Arguments = Build-ArgumentString -Args (Split-Args $Resolved.Args)
    $psi.WorkingDirectory = $Resolved.Cwd
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    foreach ($key in $Resolved.Env.Keys) {
        $psi.EnvironmentVariables[$key] = [string]$Resolved.Env[$key]
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    $start = Get-Date
    [void]$process.Start()

    $timedOut = $false
    if (-not $process.WaitForExit($Action.TimeoutSeconds * 1000)) {
        $timedOut = $true
        try { $process.Kill() } catch {}
        $process.WaitForExit()
    }

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $duration = [int]((Get-Date) - $start).TotalSeconds

    Write-Host ""
    if ($timedOut) {
        Write-Host "Status: timed out after $($Action.TimeoutSeconds)s"
    } else {
        Write-Host "Status: exit code $($process.ExitCode)"
    }
    Write-Host "Duration: ${duration}s"
    Write-Host ""

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        Write-Host $stdout.TrimEnd()
    }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Host ""
        }
        Write-Host $stderr.TrimEnd()
    }

    if ($timedOut) { return 124 }
    return $process.ExitCode
}

function Show-ActionPreview {
    param(
        [hashtable]$Action,
        [hashtable]$Resolved
    )

    Write-Host ""
    Write-Host $Action.Title
    if ($Action.Description) {
        Write-Host $Action.Description
    }
    Write-Host "Working directory: $($Resolved.Cwd)"
    Write-Host "Resolution: $($Resolved.Source)"
    Write-Host "Command: $(Format-DisplayCommand -Resolved $Resolved)"

    if ($Resolved.Env.Count -gt 0) {
        Write-Host "Environment overrides:"
        foreach ($key in ($Resolved.Env.Keys | Sort-Object)) {
            Write-Host "  ${key}=$($Resolved.Env[$key])"
        }
    }
}

$resolvedManifestDir = (Resolve-Path -LiteralPath $ManifestDir).Path
Initialize-Builtins -ResolvedManifestDir $resolvedManifestDir
$manifest = Load-Manifest -ResolvedManifestDir $resolvedManifestDir
$actions = @(Get-ActionFiles -ResolvedManifestDir $resolvedManifestDir | ForEach-Object { Load-Action -Path $_.FullName })

if ($List) {
    Write-Host $manifest.Name
    if ($manifest.Description) {
        Write-Host $manifest.Description
    }
    Write-Host ""
    $index = 1
    foreach ($action in $actions) {
        Write-Host ('{0,2}. {1} [{2}]' -f $index, $action.Title, $action.ID)
        if ($action.Description) {
            Write-Host "    $($action.Description)"
        }
        $index++
    }
    exit 0
}

if ($Run) {
    $action = $actions | Where-Object { $_.ID -eq $Run } | Select-Object -First 1
    if (-not $action) {
        throw "No action with id: $Run"
    }

    $resolved = Resolve-Action -Action $action
    Show-ActionPreview -Action $action -Resolved $resolved
    $exitCode = Invoke-ResolvedAction -Action $action -Resolved $resolved
    exit $exitCode
}

while ($true) {
    Clear-Host
    Write-Host $manifest.Name
    if ($manifest.Description) {
        Write-Host $manifest.Description
    }
    Write-Host "OS: $(Get-HostOSName)"
    Write-Host "Manifest: $resolvedManifestDir"
    Write-Host ""

    if ($actions.Count -eq 0) {
        throw "No actions found."
    }

    for ($i = 0; $i -lt $actions.Count; $i++) {
        $action = $actions[$i]
        Write-Host ('{0,2}. {1} [{2}]' -f ($i + 1), $action.Title, $action.ID)
        if ($action.Description) {
            Write-Host "    $($action.Description)"
        }
    }

    Write-Host ""
    $selection = Read-Host 'Select an action number, or q to quit'
    if ($selection -match '^(q|quit|exit)$') {
        exit 0
    }

    $index = 0
    if (-not [int]::TryParse($selection, [ref]$index)) {
        continue
    }
    if ($index -lt 1 -or $index -gt $actions.Count) {
        continue
    }

    $action = $actions[$index - 1]
    $resolved = Resolve-Action -Action $action

    Clear-Host
    Show-ActionPreview -Action $action -Resolved $resolved
    $confirm = Read-Host 'Run this action? [Y/n]'
    if ($confirm -match '^(n|no)$') {
        continue
    }

    $null = Invoke-ResolvedAction -Action $action -Resolved $resolved
    Read-Host 'Press Enter to return to the menu' | Out-Null
}
