# WeaponSwayless

Removes idle weapon sway for selected weapons in S.T.A.L.K.E.R. 2 using player-only aiming effects. No DLL, no script extender — each weapon is a game-data pak.

## Install

Copy the paks from `Stalker2\Content\Paks\~mods` into your game's `~mods` folder and restart the game. Works as shipped with the default configuration.

## Configure

Edit `Configure\weapons.ini`, one section per weapon:

- `enabled=1` / `0` — patch this weapon or leave it vanilla
- `sway=0-100` — percent of idle sway removed

Configuration is **build-time**: `weapons.ini` only tells the generator what to write into the pak, so after editing you must rerun `Configure\Deploy.ps1` and restart the game. A live, in-game ini is not possible with this design; pak content is loaded at startup.

Supported today: `[clusterfuck]` (Clusterfuck) and `[justice]` (Justice, Cost of Hope). Another weapon is one more section with its `setup`/`dlc` values.

## Scripts

`Deploy.ps1` — generates and builds the paks, then installs them.

1. Reads `weapons.ini` and validates each section.
2. Writes per-weapon patch configs (sway effect prototypes plus the weapon's aiming-effects entry) into a temporary build folder.
3. Packs each weapon into `dist\Swayless_<weapon>_P.pak` with `repak` (auto-downloads it to `tools\repak` on first run).
4. Copies the paks into the game's `~mods` folder, removing stale paks for weapons you disabled, and the legacy combined pak.

```powershell
.\Deploy.ps1                 # build + install
.\Deploy.ps1 -NoDeploy       # build only, output in dist\
.\Deploy.ps1 -Target "<game>\Stalker2\Content\Paks\~mods"
```

`package.ps1` — builds the distributable zip: the paks at their game path plus `Configure\` (this README, `Deploy.ps1`, `weapons.ini`).

```powershell
.\package.ps1 -Version 1.1   # -> dist\WeaponSwayless_1.1.zip
```
