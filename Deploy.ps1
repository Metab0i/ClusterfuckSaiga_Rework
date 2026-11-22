# Build Clusterfuck Saiga Rework: packs src\ into one game-data pak and installs it.
#
#   .\Deploy.ps1                                  -> pack + install into ~mods
#   .\Deploy.ps1 -NoDeploy                        -> pack only (dist\ClusterfuckSaigaRework_P.pak)
#   .\Deploy.ps1 -Target "D:\...\Stalker2\Content\Paks\~mods"
param(
    [switch]$NoDeploy,
    [string]$Target
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$srcDir = Join-Path $root "src"
$distDir = Join-Path $root "dist"
$pakName = "ClusterfuckSaigaRework_P.pak"
$repak = Join-Path $root "tools\repak\repak.exe"
$legacyPaks = @("ClusterfuckStability_P.pak", "weaponswayless_P.pak")

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

foreach ($old in $legacyPaks) {
    $p = Join-Path $Target $old
    if (Test-Path $p) { Remove-Item -LiteralPath $p -Force; Write-Host "removed legacy $old" }
}
foreach ($p in Get-ChildItem $Target -Filter "Swayless_*_P.pak" -ErrorAction SilentlyContinue) {
    Remove-Item -LiteralPath $p.FullName -Force
    Write-Host "removed legacy $($p.Name)"
}
