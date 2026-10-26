#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Event")
SetKeyDelay(20, 20)

; NectarX starter route: BSS global spawn -> Hive Slot 1 (nearest the red-cannon ramp).
; This is timed navigation, not image-verified navigation. These values are initial
; calibration guesses and may need adjusting for camera angle, movement speed and FPS.
; Test while watching the character. F8 aborts and releases movement keys.

global RouteStopped := false
global RouteHeldKey := ""

Hotkey("F8", EmergencyStop)
OnExit(RouteCleanup)

hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
if !hwnd
    hwnd := WinExist("Roblox")
if !hwnd {
    MsgBox("Open Bee Swarm Simulator in Roblox first, then run this route again.", "NectarX — Hive Slot 1", "Icon!")
    ExitApp()
}

answer := MsgBox("STARTING LOCATION: BSS global spawn platform" Chr(10) Chr(10) "This is an uncalibrated timed route. Watch the character and press F8 to stop immediately if it goes the wrong way." Chr(10) Chr(10) "Continue?", "NectarX — Spawn to Hive Slot 1", "YesNo Icon!")
if (answer != "Yes")
    ExitApp()

WinActivate("ahk_id " hwnd)
if !WinWaitActive("ahk_id " hwnd, , 3) {
    MsgBox("Could not activate the Roblox window. Click Roblox and try again.", "NectarX", "Icon!")
    ExitApp()
}

if !Countdown(3)
    ExitApp()

; Starter timings only. Edit these durations after observing a run:
; W approaches the hive area, D follows the row toward slot 1 near the ramp,
; then W makes the final approach. Camera orientation changes the result.
if !WalkFor("w", 1400)
    ExitApp()
if !WalkFor("d", 850)
    ExitApp()
if !WalkFor("w", 1000)
    ExitApp()
if !WalkFor("a", 250)
    ExitApp()
if !WalkFor("w", 500)
    ExitApp()

ReleaseMovement()
if !RouteStopped
    MsgBox("Starter route finished. Check whether you reached Hive Slot 1. If not, adjust the timings near the top of hive_slot_1.ahk and test again.", "NectarX", "Iconi")
ExitApp()

Countdown(seconds) {
    global RouteStopped
    Loop seconds {
        if RouteStopped
            return false
        ToolTip("NectarX route starts in " (seconds - A_Index + 1) "…  (F8 = emergency stop)")
        Sleep(1000)
    }
    ToolTip()
    return !RouteStopped
}

WalkFor(key, durationMs) {
    global RouteStopped, RouteHeldKey
    if RouteStopped
        return false
    RouteHeldKey := key
    Send("{" key " down}")
    started := A_TickCount
    while (!RouteStopped && A_TickCount - started < durationMs)
        Sleep(40)
    Send("{" key " up}")
    RouteHeldKey := ""
    Sleep(120)
    return !RouteStopped
}

EmergencyStop(*) {
    global RouteStopped
    RouteStopped := true
    ReleaseMovement()
    ToolTip()
}

ReleaseMovement() {
    global RouteHeldKey
    if (RouteHeldKey != "") {
        Send("{" RouteHeldKey " up}")
        RouteHeldKey := ""
    }
    for key in ["w", "a", "s", "d", "Space"]
        Send("{" key " up}")
}

RouteCleanup(*) {
    ToolTip()
    ReleaseMovement()
}
