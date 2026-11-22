# Build Stalker 2 - Saiga, AK-74S, Clusterf Overhaul: packs src\ into one game-data pak.
#
#   .\build.ps1   -> dist\nbwpnstriad_overhaul.pak

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$srcDir = Join-Path $root "src"
$distDir = Join-Path $root "dist"
$pakName = "nbwpnstriad_overhaul.pak"
$repak = Join-Path $root "tools\repak\repak.exe"

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
