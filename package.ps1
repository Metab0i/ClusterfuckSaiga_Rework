# Build a distributable zip in dist\ containing every per-weapon pak at the game-relative path.
#   .\package.ps1 [-Version 1.0]
param(
    [string]$Version = "1.0"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$dist = Join-Path $root "dist"
$stage = Join-Path $env:TEMP "opencode\weaponswayless_pkg"
$zipPath = Join-Path $dist "WeaponSwayless_$($Version).zip"

$paks = @(Get-ChildItem $dist -Filter "Swayless_*_P.pak" -ErrorAction SilentlyContinue)
if ($paks.Count -eq 0) {
    & (Join-Path $root "Deploy.ps1") -NoDeploy
    $paks = @(Get-ChildItem $dist -Filter "Swayless_*_P.pak")
}
if ($paks.Count -eq 0) { throw "no paks found in $dist" }

if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
$mods = Join-Path $stage "Stalker2\Content\Paks\~mods"
New-Item -ItemType Directory -Path $mods -Force | Out-Null
foreach ($p in $paks) { Copy-Item -LiteralPath $p.FullName -Destination (Join-Path $mods $p.Name) }

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zipPath)
Write-Output "built $zipPath"
