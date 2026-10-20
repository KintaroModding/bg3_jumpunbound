# Jump Unbound

Jumps cost only the movement you use, with a doubled base range. A Mod Configuration Menu switch decides whether Strength still adds to the distance.

A mod for Baldur's Gate 3 (Patch 8), made with game version 4.1.1.7398727. It needs
[Norbyte's Script Extender](https://github.com/Norbyte/bg3se) and the
[Mod Configuration Menu](https://github.com/AtilioA/BG3-MCM) (MCM) 1.41. This README is for developers. What the mod
does, how to install it and its compatibility are in [openmods.md](openmods.md), the mod page on
[openmods](https://openmods.nexus).

## How it works

- `Public/bg3_jumpunbound/Stats/Generated/Data/Spell_Projectile.txt` replaces the game's `Projectile_Jump`: the full
  Patch 8 entry (game data 4.8.400.7143220, `Public/Shared` in `Shared.pak`) with two changes, `TargetRadius` 4.5 -> 9
  and `UseCosts` `BonusActionPoint:1;Movement:3` -> `Movement:Distance`. The game's texts stay (same handles).
- The range is `TargetRadius` plus `AddRangeFromAbility`: the game's `"Strength,1"` adds 1 m per point of Strength
  modifier. The MCM checkbox `add_strength_to_jump` (default on, `MCM_blueprint.json`) switches it between
  `"Strength,1"` and `""` at run time (`Shared/JumpStats.lua`).
- A run-time stat change reaches only one game process: `StatsObject:Sync()` refreshes the local spell prototype and
  sends nothing (Script Extender v28 and later; it also saves nothing). So the server applies the host's value on
  `SessionLoaded` and after every MCM change, and sends it to the clients on the `Strength` net channel (broadcast,
  and as the answer to the request each client sends on `SessionLoaded`). Each client applies it in its own process;
  on `StatsLoaded` it applies its local MCM value first. On the host, client and server share one stats instance.
- `meta.lsx` lists MCM 1.41.0.0 (`755a8a72-407f-4f0d-9a33-274ac0f0b53d`) as a dependency, so the mod managers load MCM
  first; only then does MCM put its `MCM` table into this mod. Without MCM, the default applies (`Shared/Settings.lua`).

## Build

Requirements: Windows PowerShell and [LSLib](https://github.com/Norbyte/lslib/releases) (`Divine.exe`).
`build.ps1` looks for `_tools\lslib\Packed\Tools\Divine.exe` in the parent folders of the project; set `BG3_TOOLS` to
a folder that holds `lslib\` to use another place.

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1             # dist\bg3_jumpunbound.pak
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Deploy     # build, then copy the .pak to the Mods folder
powershell -ExecutionPolicy Bypass -File .\deploy.ps1 -Wait      # copy the .pak when the game is closed
```

`deploy.ps1` copies the .pak to the `Mods` folder below `BG3_DATA_DIR` (the BG3 user-data folder), else to
`%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods`; `-ModsDir` overrides both. The running game locks the .pak, so
the script stops (exit code 2) or, with `-Wait`, waits until the game is closed.

## Project layout

```
src/                                     Mod files (packed into the .pak)
  Mods/bg3_jumpunbound/meta.lsx           Mod metadata (UUID 4dca8c92-0ca2-4ac7-a8eb-882e08ce796e), MCM dependency
  Mods/bg3_jumpunbound/MCM_blueprint.json The MCM settings page (one checkbox)
  Mods/bg3_jumpunbound/ScriptExtender/
    Config.json
    Lua/BootstrapServer.lua              Server entry point
    Lua/BootstrapClient.lua              Client entry point
    Lua/Shared/Common.lua                Mod version, spell and setting names, net channel
    Lua/Shared/Settings.lua              MCM access with fallbacks
    Lua/Shared/JumpStats.lua             Sets the Strength part of the jump
    Lua/Shared/FileWriter.lua            Throttled file output in the Script Extender folder
    Lua/Server/StrengthServer.lua        Applies the host's setting and tells the clients
    Lua/Server/ServerLog.lua             server.log
    Lua/Client/StrengthClient.lua        Applies the host's setting in the client's game
    Lua/Client/ClientLog.lua             client.log
  Public/bg3_jumpunbound/Stats/Generated/Data/Spell_Projectile.txt   The jump: base range 9 m, cost movement
docs/                                    Cover and screenshots for openmods.md
tests/                                   Offline tests (Lua 5.4 through lupa)
scripts/bump_version.py                  Raises the last version digit in meta.lsx
scripts/show_log.py                      Prints the mod's log files
build.ps1                                Builds dist/bg3_jumpunbound.pak from src/
deploy.ps1                               Copies the .pak to the Mods folder
openmods.json, openmods.md               Data and mod page for openmods.nexus
```

Versioning: every change raises the last version digit (1.0.0.0 -> 1.0.0.1):

```powershell
python scripts\bump_version.py           # both Version64 values in meta.lsx
python scripts\bump_version.py --show
```

Logs: the mod writes `server.log` and `client.log` to
`%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Script Extender\bg3_jumpunbound\`. Each load writes a line like
`Jump Unbound 1.0.0.1 loaded.`, so the logs show which version runs, and a line with the Strength part and the jump
values, for example `Session loaded: Strength part on (MCM). Projectile_Jump: TargetRadius 9, ...`. MCM stores the
setting in `Script Extender\BG3MCM\Profiles\<Profile>\bg3_jumpunbound\settings.json`. `python scripts\show_log.py`
prints the newest log lines and these settings (from `BG3_DATA_DIR`, if set).

Tests:

```powershell
python -m pip install lupa
python tests\run_tests.py
```

The tests run every mod script against mocks of the Script Extender API (`tests/harness.lua`). The IMGUI, audio and
resource mocks are checked against the Script Extender IDE helpers (`tests/gen_extui_api.py` refreshes
`tests/extui_api.json`), so a property or method that does not exist in the real API fails the tests.

## License

MIT, see [LICENSE](LICENSE).
