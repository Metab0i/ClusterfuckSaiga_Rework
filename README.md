# Stalker2-SACTriadOverhaul

Game-data overhaul for S.T.A.L.K.E.R. 2: new technician upgrades for selected weapons. Pak only - no DLL, no script extender.

## Build

Requires Windows PowerShell 5.1+ and internet on first run (`repak` downloads into `tools\repak`).

```powershell
.\build.ps1   # -> dist\Stalker2_SACTriadOverhaul.pak
```

## Install

Copy `Stalker2_SACTriadOverhaul.pak` into:

```
<game>\Stalker2\Content\Paks\~mods
```

Restart the game.

## Clusterfuck

The AR416 "Clusterfuck" keeps its vanilla sway at base. New upgrades at any technician, base game and Cost of Hope:

| Upgrade | Part | Cost | Effect |
| --- | --- | --- | --- |
| Adjustable cheek riser | Stock | 10,000 | Sway -40% |
| Handstop and stippled grip | Grip | 10,000 | Sway -40% |
| Free-floated match barrel | Body | 9,000 | Damage falloff pushed further out (+30%) |
| High-pressure bolt and chamber | Body | 12,000 | Damage +45% |
| AP-optimised barrel | Barrel | 7,500 | Armor penetration +25% |

The two sway upgrades stack to roughly the old no-sway baseline. All five are standalone purchases.

Upgrades are plain data - the game's own effect prototypes are reused wherever the values match, and custom effects are defined in the mod so no vanilla stat is changed. The Clusterfuck's weapon prototype ships its Handguard section disabled, so its upgrades live on the Stock, Grip, Body and Barrel sections that have markers.

## Saiga D-12

WIP.

## AK-74S

WIP.

## Layout

```
src/Stalker2/Content/GameLite/GameData/
  EffectPrototypes/EffectPrototypes_patch_ClusterfuckRework.cfg
  NPCPrototypes/NPCPrototypes_patch_ClusterfuckRework.cfg          # adds the upgrades to every base-game technician
  UpgradePrototypes/UpgradePrototypes_patch_ClusterfuckRework.cfg  # the upgrade nodes themselves
  WeaponData/WeaponGeneralSetupPrototypes/WeaponGeneralSetupPrototypes_patch_ClusterfuckRework.cfg
src/Stalker2/Content/GameLite/DLCGameData/DLC1/NPCPrototypes/
  NPCPrototypes_patch_ClusterfuckRework.cfg                        # Cost of Hope technicians (azot, gumorok/ Jokelet)
```

Upgrades are only installable where the technician's own `Upgrades` list contains them, so a new upgrade needs an entry in the NPC patch as well as its prototype and setup-list entry. The base patch covers every base-game technician; the DLC patch covers the Cost of Hope technicians in `DLCGameData/DLC1` (`DLC01_azot_0`, `DLC01_gumorok_0` and Jokelet, `DLC01_gumorok_1`).

`package.ps1` builds the distributable zip: `.\package.ps1 -Version 1.0` -> `dist\Stalker2_SACTriadOverhaul_1.0.zip`.
