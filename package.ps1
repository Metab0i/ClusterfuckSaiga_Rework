# Build the distributable zip: the pak at its game path plus the README.
#
#   .\package.ps1 -Version 1.0   -> dist\Stalker2_SACTriadOverhaul_1.0.zip
param(
    [string]$Version = "1.0"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$distDir = Join-Path $root "dist"
$pakName = "Stalker2_SACTriadOverhaul.pak"
$pak = Join-Path $distDir $pakName

if (-not (Test-Path $pak)) { throw "$pakName not found; run .\build.ps1 first" }

$stage = Join-Path $env:TEMP "opencode\clusterfucksaiga_pkg"
if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
$mods = Join-Path $stage "Stalker2\Content\Paks\~mods"
New-Item -ItemType Directory -Path $mods -Force | Out-Null
Copy-Item -LiteralPath $pak -Destination (Join-Path $mods $pakName)
Copy-Item -LiteralPath (Join-Path $root "README.md") -Destination (Join-Path $stage "README.md")

$zip = Join-Path $distDir "Stalker2_SACTriadOverhaul_$Version.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal
Write-Host "built $zip"
