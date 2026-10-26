#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NectarX hive-claim test
; No mouse movement is performed by this script.
; Select the screenshot of the hive-claim prompt when the script starts.
; When the screenshot is found on screen continuously for 5 seconds, press E once.
; F6 = start/pause monitoring, F7 = reset detection, Esc = exit.

CoordMode "Pixel", "Screen"
SendMode "Input"
SetTitleMatchMode 2

global TargetImage := ""
global Monitoring := false
global SeenSince := 0
global EWasSent := false
global Tolerance := 35

mainGui := Gui("+AlwaysOnTop", "NectarX — Hive Claim Test")
mainGui.SetFont("s10", "Segoe UI")
mainGui.AddText("w390", "Choose the screenshot that shows the hive-claim prompt.")
pathLabel := mainGui.AddText("w390 h36", "No screenshot selected.")
chooseBtn := mainGui.AddButton("w185", "Choose screenshot...")
chooseBtn.OnEvent("Click", ChooseImage)
startBtn := mainGui.AddButton("x+8 w185", "Start monitoring (F6)")
startBtn.OnEvent("Click", ToggleMonitoring)
statusLabel := mainGui.AddText("xm w390 h42", "Status: waiting for screenshot")
mainGui.AddText("w390", "F6: start/pause   F7: reset   Esc: exit")
mainGui.Show()

ChooseImage(*) {
    global TargetImage, pathLabel, statusLabel
    selected := FileSelect(1, A_ScriptDir, "Select hive-claim screenshot", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
    if selected = ""
        return
    TargetImage := selected
    pathLabel.Text := selected
    statusLabel.Text := "Status: screenshot loaded. Start monitoring when ready."
}

ToggleMonitoring(*) {
    global Monitoring, SeenSince, EWasSent, statusLabel, TargetImage, startBtn
    if !Monitoring {
        if TargetImage = "" {
            MsgBox "Choose the hive-claim screenshot first.", "NectarX"
            return
        }
        Monitoring := true
        SeenSince := 0
        EWasSent := false
        statusLabel.Text := "Status: monitoring screen for the claim prompt..."
        startBtn.Text := "Pause monitoring (F6)"
        SetTimer CheckPrompt, 250
    } else {
        Monitoring := false
        SetTimer CheckPrompt, 0
        statusLabel.Text := "Status: paused."
        startBtn.Text := "Start monitoring (F6)"
    }
}

CheckPrompt() {
    global TargetImage, Monitoring, SeenSince, EWasSent, Tolerance, statusLabel
    if !Monitoring || EWasSent
        return
    try {
        ; ImageSearch checks the whole screen. *n allows small visual differences.
        found := ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" Tolerance " " TargetImage)
    } catch as err {
        Monitoring := false
        SetTimer CheckPrompt, 0
        statusLabel.Text := "ImageSearch error: " err.Message
        return
    }

    if found {
        if SeenSince = 0 {
            SeenSince := A_TickCount
            statusLabel.Text := "Status: prompt detected; waiting 5 seconds..."
        } else {
            elapsed := A_TickCount - SeenSince
            statusLabel.Text := "Status: prompt visible for " Round(elapsed / 1000, 1) " / 5 seconds"
            if elapsed >= 5000 {
                Send "{e}"
                EWasSent := true
                statusLabel.Text := "Status: E pressed once. Press F7 to reset detection."
            }
        }
    } else {
        SeenSince := 0
        statusLabel.Text := "Status: prompt not found; scanning..."
    }
}

ResetDetection(*) {
    global SeenSince, EWasSent, statusLabel, Monitoring
    SeenSince := 0
    EWasSent := false
    statusLabel.Text := Monitoring ? "Status: reset; scanning..." : "Status: reset. Start monitoring with F6."
}

F6::ToggleMonitoring()
F7::ResetDetection()
Esc::ExitApp
