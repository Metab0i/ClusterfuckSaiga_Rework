# Clusterfuck Saiga Rework

Adds technician upgrades to S.T.A.L.K.E.R. 2 weapons. Game-data pak only - no DLL, no script extender.

## Install

Copy `ClusterfuckSaigaRework_P.pak` from `Stalker2\Content\Paks\~mods` into your game's `~mods` folder and restart the game.

## Clusterfuck

The AR416 "Clusterfuck" keeps its vanilla sway at base. New upgrades at any technician:

| Upgrade | Part | Cost | Effect |
| --- | --- | --- | --- |
| Adjustable cheek riser | Stock | 10,000 | Sway -40% |
| Handstop and stippled grip | Grip | 10,000 | Sway -40% |
| Bedded match barrel | Body | 9,000 | Damage falloff pushed further out (+30%) |
| High-pressure bolt and chamber | Body | 12,000 | Damage +45% |
| Cut-rifled AP barrel | Barrel | 7,500 | Armor penetration +25% |

The two sway upgrades stack to roughly the old no-sway baseline. All five are standalone purchases.

Upgrades are plain data - the game's own effect prototypes are reused wherever the values match, and custom effects are defined in the mod so no vanilla stat is changed. The Clusterfuck's weapon prototype ships its Handguard section disabled, so its upgrades live on the Stock, Grip, Body and Barrel sections that have markers.

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

## Scripts

`Deploy.ps1` - packs `src\` into `dist\ClusterfuckSaigaRework_P.pak`, installs it into `~mods`, and removes paks from the previous mod versions.

```powershell
.\Deploy.ps1                 # build + install
.\Deploy.ps1 -NoDeploy       # build only
.\Deploy.ps1 -Target "<game>\Stalker2\Content\Paks\~mods"
```

`package.ps1` - builds the distributable zip with the pak at its game path plus this README.

```powershell
.\package.ps1 -Version 1.0   # -> dist\ClusterfuckSaigaRework_1.0.zip
```
