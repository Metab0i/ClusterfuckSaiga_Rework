# Build WeaponSwayless: one pak per weapon, configured in weapons\<name>\weapon.ini.
#
#   .\Deploy.ps1            -> generate + pack + install into ~mods
#   .\Deploy.ps1 -NoDeploy  -> generate + pack only (dist\Swayless_<Weapon>_P.pak)
#   .\Deploy.ps1 -Target "D:\...\Stalker2\Content\Paks\~mods"
param(
    [string]$Target = "",
    [switch]$NoDeploy
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$weaponsDir = Join-Path $root "weapons"
$distDir = Join-Path $root "dist"
$repak = Join-Path $root "tools\repak\repak.exe"
$SteamAppId = "1643320"
$GameFolderName = "S.T.A.L.K.E.R. 2 Heart of Chornobyl"
$legacyPak = "ClusterfuckStability_P.pak"

function Read-Ini($path) {
    $cfg = @{}
    foreach ($line in Get-Content -LiteralPath $path) {
        $t = $line.Trim()
        if (-not $t -or $t.StartsWith(";") -or $t.StartsWith("#")) { continue }
        if ($t -match '^([^=]+)=(.*)$') { $cfg[$Matches[1].Trim().ToLower()] = $Matches[2].Trim() }
    }
    return $cfg
}

function Get-Int($cfg, $key, $default) {
    if (-not $cfg.ContainsKey($key)) { return $default }
    $v = 0
    if (-not [int]::TryParse($cfg[$key], [ref]$v)) { throw "bad value for ${key}: '$($cfg[$key])'" }
    return $v
}

if (-not (Test-Path $weaponsDir)) { throw "weapons folder not found: $weaponsDir" }

# --- read weapon configs ---
$weapons = @()
foreach ($dir in Get-ChildItem -Path $weaponsDir -Directory | Sort-Object Name) {
    $iniPath = Join-Path $dir.FullName "weapon.ini"
    if (-not (Test-Path $iniPath)) { continue }
    $cfg = Read-Ini $iniPath
    $name = $dir.Name.ToLower()
    if (-not $cfg.ContainsKey("setup")) { throw "${name}: missing setup" }
    $sway = Get-Int $cfg "sway" 80
    if ($sway -lt 0 -or $sway -gt 100) { throw "${name}: sway must be 0-100" }
    $weapons += [pscustomobject]@{
        name = $name
        label = $(if ($cfg.ContainsKey("label")) { $cfg["label"] } else { $dir.Name })
        setup = $cfg["setup"]
        dlc = (Get-Int $cfg "dlc" 0) -ne 0
        enabled = (Get-Int $cfg "enabled" 1) -ne 0
        sway = $sway
        attachment = $(if ($cfg.ContainsKey("attachment")) { $cfg["attachment"] } else { "" })
        holdBreath = (Get-Int $cfg "hold_breath" 0) -ne 0
        x = "Swayless_${name}_X"; y = "Swayless_${name}_Y"; template = "Swayless_${name}_Template"
        pak = "Swayless_$($dir.Name)_P.pak"
    }
}
if ($weapons.Count -eq 0) { throw "no weapon.ini found under $weaponsDir" }
$knownPaks = @($weapons | ForEach-Object { $_.pak })

# --- repak (download on first run) ---
if (-not (Test-Path $repak)) {
    Write-Host "repak not found, downloading..."
    $tmp = Join-Path $root "tools\repak.zip"
    New-Item -ItemType Directory -Path (Join-Path $root "tools") -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/trumank/repak/releases/download/v0.2.3/repak_cli-x86_64-pc-windows-msvc.zip" -OutFile $tmp -UseBasicParsing
    Expand-Archive -LiteralPath $tmp -DestinationPath (Join-Path $root "tools\repak") -Force
    Remove-Item $tmp -Force
}
if (-not (Test-Path $repak)) { throw "repak.exe not found at $repak" }

# --- generate payloads ---
if (Test-Path $distDir) { foreach ($p in $knownPaks) { $f = Join-Path $distDir $p; if (Test-Path $f) { Remove-Item -LiteralPath $f -Force } } }
else { New-Item -ItemType Directory -Path $distDir -Force | Out-Null }
$buildRoot = Join-Path $env:TEMP "opencode\weaponswayless_build"
if (Test-Path $buildRoot) { Remove-Item -LiteralPath $buildRoot -Recurse -Force }

foreach ($w in $weapons) {
    if (-not $w.enabled -or $w.sway -eq 0) {
        Write-Host ("{0}: disabled" -f $w.label)
        continue
    }

    $stage = Join-Path $buildRoot $w.name
    $gamedata = Join-Path $stage "Stalker2\Content\GameLite\GameData"
    New-Item -ItemType Directory -Path $gamedata -Force | Out-Null

    $neg = "-$($w.sway)%"
    $effectDir = Join-Path $gamedata "EffectPrototypes"
    New-Item -ItemType Directory -Path $effectDir -Force | Out-Null
    @"
$($w.template) : struct.begin {refurl=../EffectPrototypes.cfg; refkey=[0]}
    SID = $($w.template)
    Type = EEffectType::None
    bIsPermanent = true
    ValueMin = $neg
    ValueMax = $neg
struct.end

$($w.x) : struct.begin {refkey=$($w.template)}
    SID = $($w.x)
    Type = EEffectType::IdleSwayXModifier
struct.end

$($w.y) : struct.begin {refkey=$($w.template)}
    SID = $($w.y)
    Type = EEffectType::IdleSwayYModifier
struct.end
"@ | Set-Content -LiteralPath (Join-Path $effectDir "EffectPrototypes_patch_$($w.name).cfg") -Encoding Ascii

    $setupBlock = @"
$($w.setup) : struct.begin {bpatch}
   AimingEffects : struct.begin {bpatch}
      PlayerOnlyEffects : struct.begin {bpatch}
         [*] = $($w.x)
         [*] = $($w.y)
      struct.end
   struct.end
struct.end
"@
    $setupRel = if ($w.dlc) { "DLCGameData\DLC1\WeaponData\WeaponGeneralSetupPrototypes" } else { "GameData\WeaponData\WeaponGeneralSetupPrototypes" }
    New-Item -ItemType Directory -Path (Join-Path $stage ("Stalker2\Content\GameLite\" + $setupRel)) -Force | Out-Null
    $setupBlock | Set-Content -LiteralPath (Join-Path $stage ("Stalker2\Content\GameLite\" + $setupRel + "\WeaponGeneralSetupPrototypes_patch_$($w.name).cfg")) -Encoding Ascii

    if ($w.attachment) {
        $attachDir = Join-Path $gamedata "ItemPrototypes\AttachPrototypes"
        New-Item -ItemType Directory -Path $attachDir -Force | Out-Null
        $holdLine = if ($w.holdBreath) { "   CanHoldBreath = true`n" } else { "" }
        @"
$($w.attachment) : struct.begin {bpatch}
$holdLine   Scope : struct.begin {bpatch}
      AimingEffects : struct.begin {bpatch}
         PlayerOnlyEffects : struct.begin {bpatch}
            [*] = $($w.x)
            [*] = $($w.y)
         struct.end
      struct.end
   struct.end
struct.end
"@ | Set-Content -LiteralPath (Join-Path $attachDir "AttachPrototypes_patch_$($w.name).cfg") -Encoding Ascii
    }

    $pakPath = Join-Path $distDir $w.pak
    & $repak pack $stage $pakPath -m "../../../" --version V11 | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pakPath)) { throw "repak pack failed for $($w.name)" }
    Write-Host ("{0}: -{1}% -> {2}" -f $w.label, $w.sway, $w.pak)
}

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
    Write-Host "packed into $distDir (not deployed)" -ForegroundColor Green
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

$built = @(Get-ChildItem $distDir -Filter "Swayless_*_P.pak" | ForEach-Object { $_.Name })
foreach ($p in $knownPaks) {
    if (($built -notcontains $p) -and (Test-Path (Join-Path $Target $p))) {
        Remove-Item -LiteralPath (Join-Path $Target $p) -Force
        Write-Host "removed stale $p"
    }
}
if (Test-Path (Join-Path $Target $legacyPak)) { Remove-Item -LiteralPath (Join-Path $Target $legacyPak) -Force }
foreach ($p in Get-ChildItem $distDir -Filter "Swayless_*_P.pak") {
    Copy-Item -LiteralPath $p.FullName -Destination (Join-Path $Target $p.Name) -Force
    Write-Host "deployed $($p.Name)"
}
