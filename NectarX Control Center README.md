# NectarX Control Center (Preview build)

This is a new standalone AutoHotkey v2 control-center GUI with an original dark navy / electric-blue visual theme.

## Included pages
- Dashboard: session preview timer, gather configuration summary, nectar target display, planter ownership count, selected sprinkler, and log view.
- Gather: field and pattern selection, pattern size/width, repetitions, gather duration, backpack threshold, Shift Lock preference, movement preferences, and return-to-hive preference.
- Sprinklers: owned sprinkler checkboxes, active sprinkler selection, per-field placement presets, offsets, and placement configuration.
- Planters & Nectar: planter ownership, target percentages for five nectar types, harvest rules and intervals, and three planter field assignments.
- Patterns: scans the existing `NectarX patterns/` and `NectarX paths/` folders and opens selected scripts in Notepad.
- Screen Reader: Roblox window detection and a built-in AutoHotkey ImageSearch template test using original PNG/BMP files in `NectarX images/`.
- Settings: local settings, start/pause/stop UI hotkeys, and named profiles.
- Logs: refresh and clear the local activity log.

## Run
1. Install AutoHotkey v2 on Windows.
2. Download the repository and open `NectarX Control Center.ahk`.
3. Use Save settings to write choices to `NectarX.ini`.
4. Use Start / Preview to check the session timer and Pause / Resume / Stop behaviour.

## Important limitation
This is a GUI/configuration preview, not a complete Bee Swarm farming macro. Start / Preview only runs the NectarX UI timer. It does not move the Roblox character, gather pollen, convert a backpack, place sprinklers, read live nectar percentages, harvest planters, or automatically return to the hive. The pattern/path files are catalogued but not executed because their shared movement helpers have not been integrated and tested. The displayed actual nectar, backpack, and planter-growth values are explicitly marked unavailable rather than fabricated.

The source has not been runtime-tested in AutoHotkey v2 on a Windows/Roblox setup. Please test the GUI locally before relying on it. The existing `NectarX.ahk` was left unchanged; this is an additional standalone file.
