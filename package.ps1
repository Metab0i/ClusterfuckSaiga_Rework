# Build a distributable zip in dist\ containing the pak at the game-relative path.
#   .\package.ps1 [-Version 1.0]
param(
    [string]$Version = "1.0"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$dist = Join-Path $root "dist"
$pak = Join-Path $dist "ClusterfuckStability_P.pak"
$stage = Join-Path $env:TEMP "opencode\Clusterfuck Stability Mod_pkg"
$zipPath = Join-Path $dist "Clusterfuck Stability Mod_$($Version).zip"

if (-not (Test-Path $pak)) {
    & (Join-Path $root "Deploy.ps1") -NoDeploy
}
if (-not (Test-Path $pak)) { throw "pak not found: $pak" }

if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
$mods = Join-Path $stage "Stalker2\Content\Paks\~mods"
New-Item -ItemType Directory -Path $mods -Force | Out-Null
Copy-Item -LiteralPath $pak -Destination (Join-Path $mods "ClusterfuckStability_P.pak")

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zipPath)
Write-Output "built $zipPath"
