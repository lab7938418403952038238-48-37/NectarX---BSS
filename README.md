# NectarX---BSS

NectarX is a Windows AutoHotkey v2 project for Bee Swarm Simulator.

## Project layout
- `NectarX.ahk` — main GUI and screen-reader template tester.
- `NectarX paths/` — field movement path snippets.
- `NectarX patterns/` — movement pattern snippets.
- `NectarX images/` — add your own cropped PNG/BMP screen templates here. The screen reader also discovers PNG/BMP assets stored in the repository root for compatibility with the existing image library.
- `docs/IMAGE_ASSET_AUDIT.md` — inventory of the committed image assets and the screen states that still need verified templates.
- `NectarX.ini` and `NectarX.log` — generated locally by the GUI.

## Current features
- GUI subtabs for Dashboard, Farming, Patterns, Conversion, Quests, Planters, Screen Reader, Settings, and Logs.
- Saved Walking/Cannon movement preference (configuration only; not yet connected to a validated runner).
- Roblox process/window detection.
- Template-based screen matching with AutoHotkey `ImageSearch`, limited to the Roblox client area.
- Repetition, movement scale, and image-variation settings.
- Local settings and logs.

## Run
1. Install AutoHotkey v2 on Windows.
2. Download or clone the repository.
3. Run `NectarX.ahk`.
4. To test image recognition, put a tightly cropped PNG/BMP of a stable UI element in `NectarX images`, refresh the template list, open Roblox, and select **Test selected image**.

For best results, use a crop taken at the same UI scale/resolution as the game. Templates can fail if the UI changes, an animation covers them, or the game is scaled differently.

## Important development status
The GUI and basic template-matching test are scaffolding; they have not been runtime-tested on the user's Windows setup. The Start button is intentionally guarded. Existing path/pattern scripts call shared functions and use key variables that are not yet integrated into one runner. Farming, conversion, quest and planter pages are currently planning/configuration UI, not completed automation. The saved Walking/Cannon preference does not execute travel yet. A complete runner, tested stop handling, route-specific travel helpers, validated screen-state templates and more robust capture/matching still need implementation before unattended use.

## Reference
Natro Macro is an independent open-source project. NectarX uses an original scaffold and built-in AutoHotkey ImageSearch in this first screen-recognition pass; it does not copy Natro's GUI or source files.
