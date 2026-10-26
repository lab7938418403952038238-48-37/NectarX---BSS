# NectarX GUI — first build

NectarX is a lightweight AutoHotkey v2 GUI starter for the existing Bee Swarm Simulator route.

## Files

- `NectarX_GUI.ahk` — GUI, route controls, hive-image selection, image detection, and route playback.
- `NectarX.ini` — created beside the script to remember the selected screenshot and route repetition count.

## Requirements

- Windows
- AutoHotkey v2
- Roblox with Bee Swarm Simulator open
- A screenshot of the hive/claim prompt to use for image matching

## First run

1. Download `NectarX_GUI.ahk` and open it with AutoHotkey v2.
2. Join Bee Swarm Simulator and place your character at the starting position expected by your recorded route.
3. Open **Route & Detection**, choose the hive screenshot, and choose 1–20 route repetitions.
4. Return to **Dashboard** and press **Start (F1)**.
5. Watch the first run. Use **F2** to pause/resume, **F3** to stop, or **F4** to exit.

The script attempts to activate the Roblox player before it sends the route inputs. It checks the screen for the selected screenshot and presses E when it detects a match, then exits.

## Current limitations

- This is an early prototype and has not been tested in a live Roblox session.
- The route uses keyboard timings from the TinyTask recording. Mouse movement and clicks are ignored, so a route that depends on camera rotation may not match the original recording.
- Image matching depends on the screenshot, display scale, game UI, and screen appearance. If it fails to detect the hive, recapture a tight screenshot of the exact visible prompt and select it again.
- The macro does not change Roblox WalkSpeed. Set the desired in-game speed yourself.
- Test while watching the game before using it unattended.

## GUI design notes

The interface takes general inspiration from the tab-based configuration and status-oriented workflow common in Bee Swarm Simulator macros such as [Natro Macro](https://github.com/NatroTeam/NatroMacro) and the modern setup-oriented presentation of [Revolution Macro](https://revolutionmacro.com/docs/). NectarX uses its own lightweight AutoHotkey implementation and does not include their code or branding.
