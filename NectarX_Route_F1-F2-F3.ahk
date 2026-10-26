#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Event"
SetKeyDelay 25, 25
SetMouseDelay 0
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

; NectarX route runner — AutoHotkey v2
; F1 = start / pause / resume
; F2 = stop route and release all movement keys
; F3 = exit this script
;
; Route cycle (repeat up to 6 times):
; W 4.00s -> D 6.00s -> S 0.75s -> A 0.50s -> A 2.00s
; wait 2.00s -> search for the hive-claim image.
; If the image is found, press E once and stop the route.
;
; IMPORTANT:
; - Run Roblox in windowed/borderless mode and keep it in the foreground.
; - Select the hive-claim screenshot when prompted.
; - This script does not set Roblox WalkSpeed. Set 32.2 in your own
;   authorized test environment first; AHK input alone cannot change it.
; - Mouse movement is intentionally not replayed.
; - Test in a safe area first. Route timing depends on camera direction,
;   game state, lag, and whether WalkSpeed is actually 32.2.

global Running := false
global Paused := false
global StopRequested := false
global RouteBusy := false
global ClaimImage := ""
global CycleNumber := 0

ClaimImage := FileSelect(1, A_ScriptDir, "Select the hive-claim screenshot", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
if (ClaimImage = "") {
    MsgBox "No screenshot selected. The script will exit."
    ExitApp
}

TrayTip "F1 start/pause | F2 stop | F3 exit", "NectarX Route Runner", 1

F1::ToggleRoute()
F2::StopRoute()
F3::ExitApp()

ToggleRoute() {
    global Running, Paused, RouteBusy, StopRequested
    if !RouteBusy {
        StopRequested := false
        Running := true
        Paused := false
        RouteBusy := true
        ToolTip "NectarX: starting route"
        SetTimer () => ToolTip(), -1200
        SetTimer RunRoute, -10
        return
    }

    if Running && !Paused {
        Paused := true
        ReleaseMovementKeys()
        ToolTip "NectarX: PAUSED (F1 resume, F2 stop)"
    } else if Running && Paused {
        Paused := false
        ToolTip "NectarX: RESUMED"
        SetTimer () => ToolTip(), -1000
    }
}

StopRoute() {
    global Running, Paused, StopRequested
    StopRequested := true
    Running := false
    Paused := false
    ReleaseMovementKeys()
    ToolTip "NectarX: STOPPED (press F1 to start again)"
    SetTimer () => ToolTip(), -1800
}

RunRoute() {
    global Running, Paused, StopRequested, RouteBusy, CycleNumber, ClaimImage
    try {
        Loop 6 {
            CycleNumber := A_Index
            if !WaitUntilRunnable()
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — W forward 4s"
            if !HoldKey("w", 4000)
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — D right 6s"
            if !HoldKey("d", 6000)
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — S backward 0.75s"
            if !HoldKey("s", 750)
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — A left 0.5s"
            if !HoldKey("a", 500)
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — A left 2s"
            if !HoldKey("a", 2000)
                return

            if !InterruptibleSleep(2000)
                return

            ToolTip "NectarX: cycle " CycleNumber "/6 — checking hive image"
            if FindClaimImage(ClaimImage) {
                ReleaseMovementKeys()
                Send "{e}"
                Running := false
                Paused := false
                StopRequested := true
                ToolTip "NectarX: hive image found — E pressed, route stopped"
                SetTimer () => ToolTip(), -2500
                return
            }
        }

        if !StopRequested {
            ToolTip "NectarX: completed all 6 cycles (image not found)"
            SetTimer () => ToolTip(), -2500
        }
    } catch as err {
        ReleaseMovementKeys()
        MsgBox "NectarX route error:" Chr(10) err.Message, "NectarX", "Iconx"
    } finally {
        ReleaseMovementKeys()
        Running := false
        Paused := false
        RouteBusy := false
    }
}

HoldKey(key, durationMs) {
    if !WaitUntilRunnable()
        return false

    Send "{" key " down}"
    startTime := A_TickCount
    try {
        while (A_TickCount - startTime < durationMs) {
            if !WaitUntilRunnable()
                return false
            Sleep 20
        }
    } finally {
        Send "{" key " up}"
    }
    return !StopRequested
}

InterruptibleSleep(durationMs) {
    global StopRequested
    startTime := A_TickCount
    while (A_TickCount - startTime < durationMs) {
        if !WaitUntilRunnable()
            return false
        Sleep 20
    }
    return !StopRequested
}

WaitUntilRunnable() {
    global Running, Paused, StopRequested
    while Paused && !StopRequested
        Sleep 50
    return Running && !StopRequested
}

FindClaimImage(imagePath) {
    ; Search the full primary screen. *35 allows modest pixel variation.
    try {
        return ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*35 " imagePath)
    } catch as err {
        MsgBox "Could not search for the selected image:" Chr(10) err.Message
        return false
    }
}

ReleaseMovementKeys() {
    Send "{w up}{a up}{s up}{d up}{e up}"
}
