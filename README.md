# Clusterfuck Saiga Rework

Adds technician upgrades to S.T.A.L.K.E.R. 2 weapons. Game-data pak only - no DLL, no script extender.

## Install

Copy `ClusterfuckSaigaRework_P.pak` from `Stalker2\Content\Paks\~mods` into your game's `~mods` folder and restart the game.

## Clusterfuck

The AR416 "Clusterfuck" keeps its vanilla sway at base. New upgrades at any technician:

| Upgrade | Part | Cost | Effect |
| --- | --- | --- | --- |
| Adjustable cheek riser | Stock | 10,000 | Sway -40% |
| Free-float handguard with handstop | Handguard | 10,000 | Sway -40% |
| Match-length handguard | Handguard | 9,000 | Damage falloff pushed further out (+30%) |
| High-pressure bolt and chamber | Body | 12,000 | Damage +45% |
| Cut-rifled AP barrel | Barrel | 7,500 | Armor penetration +25% |

The two sway upgrades stack to roughly the old no-sway baseline. The match-length handguard requires the free-float handguard; the rest are standalone.

Upgrades are plain data - the game's own effect prototypes are reused wherever the values match, and custom effects are defined in the mod so no vanilla stat is changed.

## Layout

```
src/Stalker2/Content/GameLite/GameData/
  EffectPrototypes/EffectPrototypes_patch_ClusterfuckRework.cfg
  NPCPrototypes/NPCPrototypes_patch_ClusterfuckRework.cfg          # adds the upgrades to every technician
  UpgradePrototypes/UpgradePrototypes_patch_ClusterfuckRework.cfg  # the upgrade nodes themselves
  WeaponData/WeaponGeneralSetupPrototypes/WeaponGeneralSetupPrototypes_patch_ClusterfuckRework.cfg
```

Upgrades are only installable where the technician's own `Upgrades` list contains them, so a new upgrade needs an entry in the NPC patch as well as its prototype and setup-list entry. The patch covers every base-game technician plus the Cost of Hope technicians (`supack_technician_banzaj_0`, `supack_technician_banzaj_fourth_0`).

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
