# WeaponSwayless

Removes idle weapon sway for selected weapons in S.T.A.L.K.E.R. 2 using player-only aiming effects. No DLL, no script extender — each weapon is a game-data pak.

## Install

Copy the paks from `Stalker2\Content\Paks\~mods` into your game's `~mods` folder and restart the game. Works from a fresh install with the default configuration.

## Configure

Edit `Configure\weapons\<name>\weapon.ini`:

- `enabled=1` / `0` — patch this weapon or leave it vanilla
- `sway=0-100` — percent of idle sway removed

Then run `Configure\Deploy.ps1` and restart the game. Configuration is build-time only: paks are generated from these values, so editing the ini after installing does nothing until the script runs.

Supported weapons: `weapons\clusterfuck` (Clusterfuck) and `weapons\justice` (Justice, Cost of Hope). Adding another weapon is a new `weapon.ini` with its `setup`/`dlc` values.
