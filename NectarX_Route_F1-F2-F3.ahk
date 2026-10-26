#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Event"
SetKeyDelay 25, 25
CoordMode "Pixel", "Screen"

; F1 = start (or resume after pausing)
; F2 = pause / resume
; F3 = stop route immediately
; F4 = exit script
;
; Six cycles: W 4s, D 6s, S 0.75s, A 0.5s, A 2s,
; wait 2s, then search the screen for the selected hive image.
; If found, press E once and stop.

global Running := false
global Paused := false
global StopRequested := false
global RouteBusy := false
global ClaimImage := ""

ClaimImage := FileSelect(1, A_ScriptDir, "Select the hive-claim screenshot", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
if (ClaimImage = "") {
    MsgBox "No screenshot selected. The script will exit."
    ExitApp
}
TrayTip "F1 start/resume | F2 pause | F3 stop | F4 exit", "NectarX Route Runner", 1

F1::StartRoute()
F2::PauseRoute()
F3::StopRoute()
F4::ExitApp()

StartRoute() {
    global Running, Paused, RouteBusy, StopRequested
    if !RouteBusy {
        StopRequested := false
        Running := true
        Paused := false
        RouteBusy := true
        SetTimer RunRoute, -10
    } else if Running && Paused {
        Paused := false
        ToolTip "NectarX: resumed"
        SetTimer () => ToolTip(), -1000
    }
}

PauseRoute() {
    global Running, Paused
    if Running && !Paused {
        Paused := true
        ReleaseMovementKeys()
        ToolTip "NectarX: PAUSED (F1 or F2 to resume; F3 to stop)"
    } else if Running && Paused {
        Paused := false
        ToolTip "NectarX: resumed"
        SetTimer () => ToolTip(), -1000
    }
}

StopRoute() {
    global Running, Paused, StopRequested
    StopRequested := true
    Running := false
    Paused := false
    ReleaseMovementKeys()
    ToolTip "NectarX: STOPPED"
    SetTimer () => ToolTip(), -1500
}

RunRoute() {
    global Running, Paused, StopRequested, RouteBusy, ClaimImage
    try {
        Loop 6 {
            if !WaitUntilRunnable()
                return
            ToolTip "NectarX: cycle " A_Index "/6 — W forward 4s"
            if !HoldKey("w", 4000)
                return
            ToolTip "NectarX: cycle " A_Index "/6 — D right 6s"
            if !HoldKey("d", 6000)
                return
            ToolTip "NectarX: cycle " A_Index "/6 — S backward 0.75s"
            if !HoldKey("s", 750)
                return
            ToolTip "NectarX: cycle " A_Index "/6 — A left 0.5s"
            if !HoldKey("a", 500)
                return
            ToolTip "NectarX: cycle " A_Index "/6 — A left 2s"
            if !HoldKey("a", 2000)
                return
            if !InterruptibleSleep(2000)
                return

            ToolTip "NectarX: cycle " A_Index "/6 — checking image"
            if FindClaimImage(ClaimImage) {
                ReleaseMovementKeys()
                Send "{e}"
                Running := false
                StopRequested := true
                ToolTip "NectarX: image found — E pressed; stopped"
                SetTimer () => ToolTip(), -2500
                return
            }
        }
        if !StopRequested {
            ToolTip "NectarX: completed 6 cycles; image not found"
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
    global StopRequested
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
