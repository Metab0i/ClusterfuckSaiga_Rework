# Build Stalker 2 - Saiga, AK-74S, Clusterf Overhaul: packs src\ into one game-data pak and installs it.
#
#   .\build.ps1                                   -> pack + install into ~mods
#   .\build.ps1 -NoDeploy                         -> pack only (dist\Stalker2_Saiga_AK74S_Clusterf_Overhaul_P.pak)
#   .\build.ps1 -Target "D:\...\Stalker2\Content\Paks\~mods"
param(
    [switch]$NoDeploy,
    [string]$Target
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$srcDir = Join-Path $root "src"
$distDir = Join-Path $root "dist"
$pakName = "Stalker2_Saiga_AK74S_Clusterf_Overhaul_P.pak"
$repak = Join-Path $root "tools\repak\repak.exe"

function Find-GameRoot {
    $hint = Join-Path $root "deploy.target"
    if (Test-Path $hint) {
        $p = (Get-Content -LiteralPath $hint -Raw).Trim()
        if ($p -and (Test-Path $p)) { return $p }
    }
    $default = "D:\Steam\steamapps\common\S.T.A.L.K.E.R. 2 Heart of Chornobyl"
    if (Test-Path $default) { return $default }
    return $null
}

if (-not (Test-Path $srcDir)) { throw "source folder not found: $srcDir" }

# --- repak (download on first run) ---
if (-not (Test-Path $repak)) {
    New-Item -ItemType Directory -Path (Split-Path $repak) -Force | Out-Null
    $zip = Join-Path $env:TEMP "opencode\repak.zip"
    New-Item -ItemType Directory -Path (Split-Path $zip) -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/trumank/repak/releases/download/v0.2.3/repak_cli-x86_64-pc-windows-msvc.zip" -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath (Split-Path $repak) -Force
    Remove-Item -LiteralPath $zip -Force
}
if (-not (Test-Path $repak)) { throw "repak.exe not found at $repak" }

# --- pack ---
New-Item -ItemType Directory -Path $distDir -Force | Out-Null
$outPak = Join-Path $distDir $pakName
if (Test-Path $outPak) { Remove-Item -LiteralPath $outPak -Force }
& $repak pack $srcDir $outPak
if ($LASTEXITCODE -ne 0) { throw "repak failed with exit code $LASTEXITCODE" }
Write-Host "built $outPak"

if ($NoDeploy) { return }

# --- install ---
if (-not $Target) {
    $game = Find-GameRoot
    if (-not $game) { throw "game not found; pass -Target pointing at Stalker2\Content\Paks\~mods" }
    $Target = Join-Path $game "Stalker2\Content\Paks\~mods"
}
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }

Copy-Item -LiteralPath $outPak -Destination (Join-Path $Target $pakName) -Force
Write-Host "installed $pakName to $Target"
