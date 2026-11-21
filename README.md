# WeaponSwayless

Removes idle weapon sway for selected weapons in S.T.A.L.K.E.R. 2 using player-only aiming effects. No DLL or script extender: each weapon ships as its own game-data pak generated from its config.

## Layout

```
weapons\<weapon>\weapon.ini   per-weapon config (the only thing you edit)
Deploy.ps1                    generates paks, installs into ~mods
package.ps1                   zips every built pak for distribution
dist\                         built paks (git-ignored)
```

## Config

`weapons\<weapon>\weapon.ini`:

```ini
label=Justice          ; display name, pak becomes Swayless_justice_P.pak
setup=GunTundra_DMR_GS ; WeaponGeneralSetup SID
dlc=1                  ; 1 = setup ships in DLCGameData\DLC1, 0 = GameData
enabled=1              ; 0 = leave this weapon vanilla
sway=80                ; percent of idle sway removed (0-100)

attachment=M701_Scope  ; optional: attachment prototype getting the same effects
hold_breath=1          ; optional: allow hold-breath on that attachment
```

Config is build-time: edit, then rerun `Deploy.ps1`. Set `enabled=0` and rebuild to remove a weapon's pak from the game.

## Build & install

```powershell
.\Deploy.ps1                  # generate, pack, install into ~mods
.\Deploy.ps1 -NoDeploy        # pack only -> dist\Swayless_*_P.pak
.\Deploy.ps1 -Target "<game>\Stalker2\Content\Paks\~mods"
.\package.ps1 -Version 1.1    # dist\WeaponSwayless_1.1.zip
```

The game is located through the Steam registry/library folders; if that fails, pass `-Target` or put the game folder path in `deploy.target`. `repak.exe` is expected at `tools\repak\repak.exe`.

## Supported weapons

| Folder | Item | Setup | Data |
| --- | --- | --- | --- |
| `weapons\clusterfuck` | Clusterfuck | `Gun_Sharpshooter_AR_GS` | base game |
| `weapons\justice` | Justice (Cost of Hope) | `GunTundra_DMR_GS` | DLC1 |

Add a weapon by creating `weapons\<name>\weapon.ini` with `setup`/`dlc`/`sway`; no script changes.

## Notes

- Effects are player-only aim effects, so NPC accuracy is untouched.
- Each pak carries only its own weapon's effects and setup patch; paks never share generated files.
- Disabled or removed weapons have their stale paks deleted from `dist\` and `~mods\` on the next build.
