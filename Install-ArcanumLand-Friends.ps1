[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Client', 'ClientFreedom', 'QuestContent', 'Server', 'Both', 'Restore', 'Verify')]
    [string]$Mode = 'Menu',
    [string]$InstancePath,
    [string]$ServerDestination,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$clientPayload = Join-Path $bundleRoot 'Client-Payload'
$serverArchive = Join-Path $bundleRoot 'Server\ArcanumLand-Recovered-Server-1.0.zip'
$backupPrefix = '_arcanumland_friends_backup_'

function Resolve-DefaultInstance {
    $instancesRoot = Join-Path $env:USERPROFILE 'curseforge\minecraft\Instances'
    $preferred = Join-Path $instancesRoot 'ArcanumLand'
    if (Test-Path -LiteralPath (Join-Path $preferred 'mods')) {
        return [IO.Path]::GetFullPath($preferred)
    }

    if (Test-Path -LiteralPath $instancesRoot) {
        $matches = @(Get-ChildItem -LiteralPath $instancesRoot -Directory |
            Where-Object {
                $_.Name -like '*ArcanumLand*' -and
                (Test-Path -LiteralPath (Join-Path $_.FullName 'mods'))
            })
        if ($matches.Count -eq 1) {
            return $matches[0].FullName
        }
    }
    return $null
}

function Resolve-ClientInstance {
    param([string]$Path)

    if (-not $Path) {
        $Path = Resolve-DefaultInstance
    }
    if (-not $Path -and -not $NonInteractive) {
        $Path = Read-Host 'Enter the full ArcanumLand instance folder'
    }
    if (-not $Path) {
        throw 'ArcanumLand instance folder was not found.'
    }

    $Path = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath (Join-Path $Path 'mods'))) {
        throw "This does not look like a Minecraft instance: $Path"
    }
    return $Path
}

function Read-InstallMode {
    Write-Host ''
    Write-Host 'ArcanumLand Friends Toolkit'
    Write-Host '1. Client Freedom Patch (Singleplayer, quests, remove locked UI)'
    Write-Host '2. Install recovered dedicated server (stock client works)'
    Write-Host '3. Install both the client patch and server'
    Write-Host '4. Install questbook and artwork only (keep original UI)'
    Write-Host '5. Restore the newest client backup'
    Write-Host '6. Check client setup'
    Write-Host '7. Exit'
    $choice = Read-Host 'Choose 1 through 7'
    switch ($choice) {
        '1' { return 'ClientFreedom' }
        '2' { return 'Server' }
        '3' { return 'Both' }
        '4' { return 'QuestContent' }
        '5' { return 'Restore' }
        '6' { return 'Verify' }
        '7' { return 'Exit' }
        default { throw 'Invalid selection.' }
    }
}

function New-ClientBackup {
    param(
        [Parameter(Mandatory)] [string]$Instance,
        [Parameter(Mandatory)] [string]$Operation
    )

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backup = Join-Path $Instance "$backupPrefix$stamp"
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    @{
        operation = $Operation
        created = (Get-Date).ToString('o')
        instance = $Instance
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup '_install-info.json') -Encoding UTF8
    return $backup
}

function Move-ToBackup {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Instance,
        [Parameter(Mandatory)] [string]$Backup
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullInstance = [IO.Path]::GetFullPath($Instance).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($fullInstance, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to move path outside the instance: $fullPath"
    }

    $relative = $fullPath.Substring($fullInstance.Length)
    $destination = Join-Path $Backup $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Move-Item -LiteralPath $fullPath -Destination $destination
    Write-Host "Backed up: $relative"
}

function Install-ContentPayload {
    param(
        [Parameter(Mandatory)] [string]$Instance,
        [Parameter(Mandatory)] [string]$Backup
    )

    if (-not (Test-Path -LiteralPath $clientPayload)) {
        throw "Missing client payload: $clientPayload"
    }

    $payloadRoot = [IO.Path]::GetFullPath($clientPayload).TrimEnd('\') + '\'
    $installed = New-Object System.Collections.Generic.List[string]
    foreach ($source in Get-ChildItem -LiteralPath $clientPayload -Recurse -File) {
        $relative = $source.FullName.Substring($payloadRoot.Length)
        $target = Join-Path $Instance $relative
        Move-ToBackup -Path $target -Instance $Instance -Backup $Backup
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        $installed.Add($relative)
    }
    $installed | Set-Content -LiteralPath (Join-Path $Backup '_installed-files.txt') -Encoding UTF8
}

function Install-ClientFreedom {
    param([Parameter(Mandatory)] [string]$Instance)

    $backup = New-ClientBackup -Instance $Instance -Operation 'ClientFreedom'
    $modPatterns = @(
        'fancymenu*.jar',
        'drippyloadingscreen*.jar',
        'spiffyhud*.jar',
        'spiffyxgnetum*.jar',
        'BetterNews*.jar'
    )
    foreach ($pattern in $modPatterns) {
        foreach ($mod in @(Get-ChildItem -LiteralPath (Join-Path $Instance 'mods') -File -Filter $pattern -ErrorAction SilentlyContinue)) {
            Move-ToBackup -Path $mod.FullName -Instance $Instance -Backup $backup
        }
    }

    $restrictedConfig = @(
        'config\fancymenu',
        'config\drippyloadingscreen',
        'config\spiffyhud',
        'config\spiffyxgnetum',
        'config\betternews',
        'servers.dat',
        'servers.dat_old'
    )
    foreach ($relative in $restrictedConfig) {
        Move-ToBackup -Path (Join-Path $Instance $relative) -Instance $Instance -Backup $backup
    }

    Install-ContentPayload -Instance $Instance -Backup $backup
    Write-Host ''
    Write-Host 'Client Freedom Patch installed.'
    Write-Host "Backup: $backup"
    Write-Host 'Singleplayer is available, restrictive UI/news components are disabled, and quest content is installed.'
}

function Install-QuestContent {
    param([Parameter(Mandatory)] [string]$Instance)

    $backup = New-ClientBackup -Instance $Instance -Operation 'QuestContent'
    Install-ContentPayload -Instance $Instance -Backup $backup
    Write-Host ''
    Write-Host 'Questbook, artwork, language files, and resource packs installed.'
    Write-Host "Backup: $backup"
    Write-Host 'The original ArcanumLand menu and UI were not changed.'
}

function Restore-ClientBackup {
    param([Parameter(Mandatory)] [string]$Instance)

    $backups = @(Get-ChildItem -LiteralPath $Instance -Directory -Filter "$backupPrefix*" |
        Where-Object { $_.Name -notlike '*_restored' } |
        Sort-Object Name -Descending)
    if ($backups.Count -eq 0) {
        throw "No ArcanumLand Friends backup was found in: $Instance"
    }

    $backup = $backups[0].FullName
    $manifest = Join-Path $backup '_installed-files.txt'
    if (Test-Path -LiteralPath $manifest) {
        foreach ($relative in Get-Content -LiteralPath $manifest) {
            if (-not [string]::IsNullOrWhiteSpace($relative)) {
                $target = Join-Path $Instance $relative
                if (Test-Path -LiteralPath $target) {
                    Remove-Item -LiteralPath $target -Force
                }
            }
        }
    }

    $backupRoot = [IO.Path]::GetFullPath($backup).TrimEnd('\') + '\'
    foreach ($source in Get-ChildItem -LiteralPath $backup -Recurse -File |
        Where-Object { $_.Name -notin @('_install-info.json', '_installed-files.txt') }) {
        $relative = $source.FullName.Substring($backupRoot.Length)
        $target = Join-Path $Instance $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
    }

    Rename-Item -LiteralPath $backup -NewName ($backups[0].Name + '_restored')
    Write-Host ''
    Write-Host "Restored newest backup: $($backups[0].Name)"
    Write-Host 'The restored backup folder was retained and marked with _restored.'
}

function Show-ClientStatus {
    param([Parameter(Mandatory)] [string]$Instance)

    $restricted = New-Object System.Collections.Generic.List[string]
    foreach ($pattern in @('fancymenu*.jar', 'drippyloadingscreen*.jar', 'spiffyhud*.jar', 'spiffyxgnetum*.jar', 'BetterNews*.jar')) {
        foreach ($mod in @(Get-ChildItem -LiteralPath (Join-Path $Instance 'mods') -File -Filter $pattern -ErrorAction SilentlyContinue)) {
            $restricted.Add($mod.Name)
        }
    }

    $questPath = Join-Path $Instance 'config\ftbquests\quests'
    $questCount = if (Test-Path -LiteralPath $questPath) {
        @(Get-ChildItem -LiteralPath $questPath -Recurse -File).Count
    } else { 0 }
    $texturePath = Join-Path $Instance 'config\betteritem\textures'
    $textureCount = if (Test-Path -LiteralPath $texturePath) {
        @(Get-ChildItem -LiteralPath $texturePath -Recurse -File).Count
    } else { 0 }

    Write-Host ''
    Write-Host "Instance: $Instance"
    Write-Host "Quest files: $questCount"
    Write-Host "Recovered texture files: $textureCount"
    if ($restricted.Count -eq 0) {
        Write-Host 'Client Freedom status: applied (no restrictive UI mods detected)'
    } else {
        Write-Host 'Client Freedom status: not applied'
        Write-Host "Detected UI mods: $($restricted -join ', ')"
    }
    Write-Host "Backups: $(@(Get-ChildItem -LiteralPath $Instance -Directory -Filter "$backupPrefix*").Count)"
}

function Install-Server {
    param([Parameter(Mandatory)] [string]$Destination)

    if (-not (Test-Path -LiteralPath $serverArchive)) {
        throw "Missing server archive: $serverArchive"
    }

    $Destination = [IO.Path]::GetFullPath($Destination)
    if (Test-Path -LiteralPath $Destination) {
        $existing = @(Get-ChildItem -Force -LiteralPath $Destination)
        if ($existing.Count -gt 0) {
            throw "Server destination must be empty: $Destination"
        }
    } else {
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    }

    Write-Host 'Extracting the recovered server. This may take several minutes...'
    Expand-Archive -LiteralPath $serverArchive -DestinationPath $Destination
    Write-Host ''
    Write-Host "Server installed to: $Destination"
    Write-Host 'The original, unmodified ArcanumLand client can connect to this server.'
    Write-Host 'Read README-SERVER.txt, accept the Minecraft EULA in eula.txt, then run start-server.bat.'
}

if ($Mode -eq 'Client') {
    $Mode = 'ClientFreedom'
}
if ($Mode -eq 'Menu') {
    if ($NonInteractive) {
        throw 'Specify a concrete -Mode when using -NonInteractive.'
    }
    $Mode = Read-InstallMode
}
if ($Mode -eq 'Exit') {
    Write-Host 'No changes made.'
    return
}

if ($Mode -in @('ClientFreedom', 'QuestContent', 'Both', 'Restore', 'Verify')) {
    $InstancePath = Resolve-ClientInstance -Path $InstancePath
}
if ($Mode -in @('ClientFreedom', 'Both')) {
    Install-ClientFreedom -Instance $InstancePath
}
if ($Mode -eq 'QuestContent') {
    Install-QuestContent -Instance $InstancePath
}
if ($Mode -eq 'Restore') {
    Restore-ClientBackup -Instance $InstancePath
}
if ($Mode -eq 'Verify') {
    Show-ClientStatus -Instance $InstancePath
}

if ($Mode -in @('Server', 'Both')) {
    if (-not $ServerDestination -and -not $NonInteractive) {
        $defaultServer = Join-Path ([Environment]::GetFolderPath('Desktop')) 'ArcanumLand Recovered Server'
        $entered = Read-Host "Server destination [$defaultServer]"
        $ServerDestination = if ($entered) { $entered } else { $defaultServer }
    }
    if (-not $ServerDestination) {
        throw 'A server destination is required.'
    }
    Install-Server -Destination $ServerDestination
}

Write-Host ''
Write-Host 'Done.'
