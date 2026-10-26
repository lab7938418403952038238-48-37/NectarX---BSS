#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Event"
SetKeyDelay 10, 10
CoordMode "Pixel", "Screen"

; NectarX TinyTask-timed route player (AutoHotkey v2)
; F1 = start / resume
; F2 = pause / resume
; F3 = stop route and release keys
; F4 = exit
;
; Timings are read from the keyboard events in:
; "to hive from spawn ( NectarX ).rec"
; Mouse movement and mouse clicks are intentionally ignored.
;
; IMPORTANT: the recording contains W, Space, S and A keyboard events.
; It contains NO D/right-key event. Do not assume this route matches a
; camera-dependent Roblox path when mouse movement is disabled.
; This sends inputs only; it cannot set Roblox WalkSpeed to 32.2.

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
TrayTip "F1 start/resume | F2 pause | F3 stop | F4 exit", "NectarX TinyTask Route", 1

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
    ; Each row is [milliseconds since first recorded key event, scan code, down/up].
    ; These offsets are derived from the actual timestamps in the .rec file.
    events := [
        [0,     "sc011", true],   ; W down
        [4313,  "sc011", false],  ; W up
        [4516,  "sc039", true],   ; Space down
        [7891,  "sc039", false],  ; Space up
        [8047,  "sc01F", true],   ; S down
        [8438,  "sc01F", false],  ; S up
        [8672,  "sc01E", true],   ; A down
        [9125,  "sc01E", false],  ; A up
        [14972, "sc01E", true],   ; A down
        [16081, "sc01E", false],  ; A up
        [24219, "sc01E", true],   ; A down
        [25453, "sc01E", false],  ; A up
        [31141, "sc01E", true],   ; A down
        [32234, "sc01E", false],  ; A up
        [39438, "sc01E", true],   ; A down
        [40391, "sc01E", false],  ; A up
        [46438, "sc01E", true],   ; A down
        [47656, "sc01E", false]   ; A up
    ]

    try {
        Loop 6 {
            cycle := A_Index
            if !WaitUntilRunnable()
                return
            ToolTip "NectarX: replaying recorded keyboard timings — cycle " cycle "/6"
            cycleStart := A_TickCount

            for event in events {
                if !WaitForRecordingTime(cycleStart, event[1])
                    return
                if event[3]
                    Send "{" event[2] " down}"
                else
                    Send "{" event[2] " up}"
            }

            ReleaseMovementKeys()
            ToolTip "NectarX: cycle " cycle "/6 — checking hive image"
            if FindClaimImage(ClaimImage) {
                Send "{e}"
                Running := false
                StopRequested := true
                ToolTip "NectarX: hive image found — E pressed; stopped"
                SetTimer () => ToolTip(), -2500
                return
            }
        }
        if !StopRequested {
            ToolTip "NectarX: completed 6 recordings; image not found"
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

WaitForRecordingTime(cycleStart, targetMs) {
    global StopRequested, ClaimImage
    while (A_TickCount - cycleStart < targetMs) {
        if !WaitUntilRunnable()
            return false
        ; Check the claim image during the recorded pauses, not only at cycle end.
        if FindClaimImage(ClaimImage) {
            ReleaseMovementKeys()
            Send "{e}"
            StopRoute()
            return false
        }
        Sleep 200
    }
    return WaitUntilRunnable()
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
    Send "{sc011 up}{sc039 up}{sc01F up}{sc01E up}{w up}{a up}{s up}{d up}{e up}"
}
