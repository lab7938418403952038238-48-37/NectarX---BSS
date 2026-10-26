#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Event")
SetKeyDelay(20, 20)

; NectarX timed route: BSS global spawn platform -> Hive Slot 1 (near red cannon ramp).
; Timings are starter estimates, not visually calibrated. Camera angle, FPS, collisions,
; and movement buffs affect the result. Test while watching the character.
; F8 is emergency stop; NectarX GUI F2 pauses and F3 stops through nectarx_route.ini.
global RouteStopped := false
global RouteHeldKey := ""
global RoutePausedMs := 0
global ConfigPath := A_ScriptDir "\nectarx_route.ini"
global BaseSpeed := IniRead(ConfigPath, "Movement", "BaseSpeed", "32.2") + 0
global ReferenceSpeed := IniRead(ConfigPath, "Movement", "ReferenceSpeed", "32.2") + 0
if (BaseSpeed <= 0)
    BaseSpeed := 32.2
if (ReferenceSpeed <= 0)
    ReferenceSpeed := 32.2
global TimeScale := ReferenceSpeed / BaseSpeed

Hotkey("F8", EmergencyStop)
OnExit(RouteCleanup)

hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
if !hwnd
    hwnd := WinExist("Roblox")
if !hwnd {
    MsgBox("Open Bee Swarm Simulator in Roblox first, then start NectarX again.", "NectarX — Hive Slot 1", "Icon!")
    ExitApp()
}
WinActivate("ahk_id " hwnd)
if !WinWaitActive("ahk_id " hwnd, , 3) {
    MsgBox("Could not activate Roblox. Click Roblox and press F1 again.", "NectarX", "Icon!")
    ExitApp()
}
if !Countdown(3)
    ExitApp()

if !WalkFor("w", 1400)
    ExitApp()
if !WalkFor("d", 650)
    ExitApp()
if !WalkFor("w", 1000)
    ExitApp()
if !WalkFor("a", 250)
    ExitApp()
if !WalkFor("w", 500)
    ExitApp()

ReleaseMovement()
if !RouteStopped
    TrayTip("NectarX", "Hive Slot 1 route finished. Check your position; timings may need calibration.", 3)
ExitApp()

Countdown(seconds) {
    global RouteStopped
    Loop seconds {
        if !CheckControl()
            return false
        ToolTip("NectarX: heading to Hive Slot 1 in " (seconds - A_Index + 1) "…  (F8 emergency stop)")
        Sleep(1000)
    }
    ToolTip()
    return !RouteStopped
}
WalkFor(key, baseDurationMs) {
    global RouteStopped, RouteHeldKey, TimeScale, RoutePausedMs
    durationMs := Round(baseDurationMs * TimeScale)
    RouteHeldKey := key
    Send("{" key " down}")
    started := A_TickCount
    pausedAtStart := RoutePausedMs
    while (!RouteStopped && A_TickCount - started - (RoutePausedMs - pausedAtStart) < durationMs) {
        if !CheckControl() {
            Send("{" key " up}")
            RouteHeldKey := ""
            return false
        }
        Sleep(35)
    }
    Send("{" key " up}")
    RouteHeldKey := ""
    Sleep(120)
    return !RouteStopped
}
CheckControl() {
    global RouteStopped, ConfigPath, RoutePausedMs
    if (IniRead(ConfigPath, "Control", "Stop", "0") = "1") {
        RouteStopped := true
        ReleaseMovement()
        ToolTip()
        return false
    }
    pauseStarted := 0
    if (IniRead(ConfigPath, "Control", "Paused", "0") = "1")
        pauseStarted := A_TickCount
    while (IniRead(ConfigPath, "Control", "Paused", "0") = "1" && !RouteStopped) {
        ReleaseMovement()
        ToolTip("NectarX paused — F2 to resume, F3 to stop")
        if (IniRead(ConfigPath, "Control", "Stop", "0") = "1") {
            RouteStopped := true
            ToolTip()
            return false
        }
        Sleep(100)
    }
    if (pauseStarted)
        RoutePausedMs += A_TickCount - pauseStarted
    ToolTip()
    return !RouteStopped
}
EmergencyStop(*) {
    global RouteStopped, ConfigPath
    RouteStopped := true
    IniWrite("1", ConfigPath, "Control", "Stop")
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
