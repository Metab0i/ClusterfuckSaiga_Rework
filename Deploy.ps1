# Build ClusterfuckStability_P.pak and copy it into the game's ~mods folder.
#
#   .\Deploy.ps1            -> pack + install
#   .\Deploy.ps1 -NoDeploy  -> pack only (dist\ClusterfuckStability_P.pak)
#   .\Deploy.ps1 -Target "D:\...\Stalker2\Content\Paks\~mods"
param(
    [string]$Target = "",
    [switch]$NoDeploy
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$modDir = Join-Path $root "mod\ClusterfuckStability_P"
$pakName = "ClusterfuckStability_P.pak"
$distDir = Join-Path $root "dist"
$pakPath = Join-Path $distDir $pakName
$repak = Join-Path $root "tools\repak\repak.exe"
$SteamAppId = "1643320"
$GameFolderName = "S.T.A.L.K.E.R. 2 Heart of Chornobyl"

if (-not (Test-Path (Join-Path $modDir "Stalker2"))) { throw "mod payload not found: $modDir" }

if (-not (Test-Path $repak)) {
    Write-Host "repak not found, downloading..."
    $tmp = Join-Path $root "tools\repak.zip"
    New-Item -ItemType Directory -Path (Join-Path $root "tools") -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/trumank/repak/releases/download/v0.2.3/repak_cli-x86_64-pc-windows-msvc.zip" -OutFile $tmp -UseBasicParsing
    Expand-Archive -LiteralPath $tmp -DestinationPath (Join-Path $root "tools\repak") -Force
    Remove-Item $tmp -Force
}
if (-not (Test-Path $repak)) { throw "repak.exe not found at $repak" }

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
if (Test-Path $pakPath) { Remove-Item -LiteralPath $pakPath -Force }

Write-Host "packing $modDir"
& $repak pack $modDir $pakPath -m "../../../" --version V11
if ($LASTEXITCODE -ne 0) { throw "repak pack failed with exit code $LASTEXITCODE" }
if (-not (Test-Path $pakPath)) { throw "pak was not created: $pakPath" }

& $repak info $pakPath
& $repak list $pakPath

function Find-GameRoot {
    $cfg = Join-Path $root "deploy.target"
    if (Test-Path $cfg) {
        $p = (Get-Content $cfg -Raw).Trim()
        if ($p -and (Test-Path (Join-Path $p "Stalker2\Binaries\Win64"))) { return $p }
    }

    foreach ($key in @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $SteamAppId",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $SteamAppId",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $SteamAppId"
    )) {
        try {
            $loc = (Get-ItemProperty -Path $key -ErrorAction Stop).InstallLocation
            if ($loc -and (Test-Path (Join-Path $loc "Stalker2\Binaries\Win64"))) { return $loc }
        } catch { }
    }

    $libraries = @()
    foreach ($key in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam")) {
        try {
            $props = Get-ItemProperty -Path $key -ErrorAction Stop
            foreach ($candidate in @($props.SteamPath, $props.InstallPath)) {
                if ($candidate -and (Test-Path $candidate)) { $libraries += ($candidate -replace '/', '\'); break }
            }
        } catch { }
        if ($libraries.Count -gt 0) { break }
    }
    foreach ($steam in $libraries) {
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $lib = $m.Groups[1].Value -replace '\\\\', '\'
                if ($lib -and (Test-Path $lib)) { $libraries += $lib }
            }
        }
    }
    foreach ($lib in ($libraries | Select-Object -Unique)) {
        foreach ($rel in @("steamapps\common\$GameFolderName", "SteamApps\common\$GameFolderName")) {
            $cand = Join-Path $lib $rel
            if (Test-Path (Join-Path $cand "Stalker2\Binaries\Win64")) { return $cand }
        }
    }
    return $null
}

if ($NoDeploy) {
    Write-Host "packed $pakPath (not deployed)" -ForegroundColor Green
    exit 0
}

if (-not $Target) {
    $game = Find-GameRoot
    if (-not $game) {
        throw "Could not find the game install. Pass -Target '<game>\Stalker2\Content\Paks\~mods' or create deploy.target with the game folder path."
    }
    $Target = Join-Path $game "Stalker2\Content\Paks\~mods"
    Write-Host "found game: $game"
}

if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }
Copy-Item -LiteralPath $pakPath -Destination (Join-Path $Target $pakName) -Force
Write-Host "deployed $pakName to $Target" -ForegroundColor Green
