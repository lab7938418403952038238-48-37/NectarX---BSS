#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode "Event"
SetKeyDelay 10, 10
CoordMode "Pixel", "Screen"

; NectarX GUI - lightweight AutoHotkey v2 interface
; F1 Start/Resume | F2 Pause/Resume | F3 Stop route | F4 Exit
; Route timings are from the existing TinyTask recording.
; Mouse movement/clicks are intentionally ignored.

Running := false, Paused := false, StopRequested := false, RouteBusy := false
ClaimImage := "", RouteCycles := 6
ConfigFile := A_ScriptDir "\NectarX.ini"
LogControl := ""
try {
    ClaimImage := IniRead(ConfigFile, "Route", "ClaimImage", "")
    RouteCycles := Integer(IniRead(ConfigFile, "Route", "Cycles", "6"))
    if (RouteCycles < 1 || RouteCycles > 20)
        RouteCycles := 6
} catch {
    ClaimImage := ""
    RouteCycles := 6
}
CycleEdit := "", StatusControl := "", CycleStatusControl := "", ImagePathControl := ""
StartButton := "", PauseButton := "", StopButton := "", MainGui := ""

MainGui := Gui("+MinSize760x520", "NectarX | Bee Swarm Simulator Macro")
MainGui.BackColor := "10151D"
MainGui.SetFont("s10 cE8EDF5", "Segoe UI")
MainGui.AddText("x24 y18 w330 h34 c67E8B7 +0x200", "NECTARX")
MainGui.SetFont("s9 c9AA8B8", "Segoe UI")
MainGui.AddText("x150 y26 w500 h24 +0x200", "BEE SWARM SIMULATOR  /  LIGHTWEIGHT MACRO")

tabs := MainGui.AddTab3("x20 y66 w720 h410", ["Dashboard", "Route & Detection", "Settings"])

tabs.UseTab(1)
MainGui.SetFont("s15 bold cE8EDF5", "Segoe UI")
MainGui.AddText("x44 y112 w640 h32", "Macro dashboard")
MainGui.SetFont("s10 c9AA8B8", "Segoe UI")
MainGui.AddText("x44 y148 w650 h24", "Choose your hive screenshot, then start the recorded route.")
MainGui.AddText("x44 y190 w150 h22", "CURRENT STATUS")
StatusControl := MainGui.AddText("x44 y215 w650 h35 cF2C879 +0x200", "Ready — select a hive screenshot")
MainGui.AddText("x44 y267 w150 h22", "ROUTE PROGRESS")
CycleStatusControl := MainGui.AddText("x44 y292 w650 h26 cE8EDF5 +0x200", "Waiting to start")
LogControl := MainGui.AddEdit("x44 y322 w650 h58 ReadOnly -Wrap", "NectarX ready. Choose your screenshot to begin.")
StartButton := MainGui.AddButton("x44 y395 w150 h38", "Start (F1)")
PauseButton := MainGui.AddButton("x210 y395 w150 h38 Disabled", "Pause (F2)")
StopButton := MainGui.AddButton("x376 y395 w150 h38 Disabled", "Stop (F3)")
StartButton.OnEvent("Click", (*) => StartRoute())
PauseButton.OnEvent("Click", (*) => PauseRoute())
StopButton.OnEvent("Click", (*) => StopRoute())

tabs.UseTab(2)
MainGui.SetFont("s15 bold cE8EDF5", "Segoe UI")
MainGui.AddText("x44 y112 w640 h32", "Route & hive detection")
MainGui.SetFont("s10 c9AA8B8", "Segoe UI")
MainGui.AddText("x44 y152 w640 h24", "Route source: recorded TinyTask keyboard timings (W, Space, S, A).")
MainGui.AddText("x44 y188 w640 h22 cE8EDF5", "Hive-claim screenshot")
ImagePathControl := MainGui.AddText("x44 y216 w520 h36 c9AA8B8", "No screenshot selected")
pickButton := MainGui.AddButton("x570 y211 w130 h34", "Choose image...")
pickButton.OnEvent("Click", (*) => ChooseImage())
MainGui.AddText("x44 y265 w250 h24 cE8EDF5", "Route repetitions (1–20)")
CycleEdit := MainGui.AddEdit("x44 y291 w100 h30 Number", String(RouteCycles))
MainGui.AddText("x165 y294 w500 h24 c9AA8B8", "The route checks the screen for your selected image.")
MainGui.AddText("x44 y340 w650 h34 cF2C879", "Note: mouse movement is ignored, so camera-dependent paths may differ.")

tabs.UseTab(3)
MainGui.SetFont("s15 bold cE8EDF5", "Segoe UI")
MainGui.AddText("x44 y112 w640 h32", "Settings & controls")
MainGui.SetFont("s10 cE8EDF5", "Segoe UI")
MainGui.AddText("x44 y160 w640 h24", "F1   Start / resume")
MainGui.AddText("x44 y192 w640 h24", "F2   Pause / resume")
MainGui.AddText("x44 y224 w640 h24", "F3   Stop route and release movement keys")
MainGui.AddText("x44 y256 w640 h24", "F4   Exit NectarX")
MainGui.SetFont("s9 c9AA8B8", "Segoe UI")
MainGui.AddText("x44 y306 w650 h48", "NectarX sends keyboard input and uses screen image matching. It does not change Roblox WalkSpeed. Set your in-game movement speed yourself before starting.")

tabs.UseTab()
MainGui.SetFont("s9 c9AA8B8", "Segoe UI")
MainGui.AddText("x24 y490 w700 h24", "NectarX • Early GUI build • Test in a safe area before leaving unattended.")
MainGui.OnEvent("Close", (*) => ExitApp())
if (ClaimImage != "" && FileExist(ClaimImage)) {
    SplitPath(ClaimImage, &savedImageName)
    ImagePathControl.Text := savedImageName
    StatusControl.Text := "Ready — saved hive screenshot loaded"
}
MainGui.Show("w760 h540")

F1::StartRoute()
F2::PauseRoute()
F3::StopRoute()
F4::ExitApp()

ChooseImage() {
    global ClaimImage, ImagePathControl, StatusControl, ConfigFile
    selected := FileSelect(1, A_ScriptDir, "Choose your hive-claim screenshot", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
    if (selected = "")
        return
    ClaimImage := selected
    SplitPath(selected, &fileName)
    ImagePathControl.Text := fileName
    StatusControl.Text := "Ready — hive screenshot selected"
    IniWrite(ClaimImage, ConfigFile, "Route", "ClaimImage")
    LogStatus("Hive screenshot selected: " fileName)
}

StartRoute() {
    global Running, Paused, RouteBusy, StopRequested, ClaimImage, CycleEdit, RouteCycles, ConfigFile
    global StatusControl, CycleStatusControl, StartButton, PauseButton, StopButton
    if (ClaimImage = "") {
        MsgBox "Please open Route & Detection and choose your hive screenshot first.", "NectarX setup", "Icon!"
        return
    }
    cycles := Integer(CycleEdit.Value)
    if (cycles < 1 || cycles > 20) {
        MsgBox "Route repetitions must be between 1 and 20.", "NectarX setup", "Icon!"
        return
    }
    RouteCycles := cycles
    IniWrite(RouteCycles, ConfigFile, "Route", "Cycles")
    if !RouteBusy {
        StopRequested := false
        Running := true
        Paused := false
        RouteBusy := true
        StatusControl.Text := "Running — focus Roblox"
        LogStatus("Starting route; repetitions: " RouteCycles)
        CycleStatusControl.Text := "Starting route..."
        StartButton.Enabled := false
        PauseButton.Enabled := true
        StopButton.Enabled := true
        SetTimer RunRoute, -10
    } else if Running && Paused {
        Paused := false
        StatusControl.Text := "Running — resumed"
    }
}

PauseRoute() {
    global Running, Paused, StatusControl, PauseButton
    if Running && !Paused {
        Paused := true
        ReleaseMovementKeys()
        StatusControl.Text := "Paused"
        LogStatus("Route paused; movement keys released.")
        PauseButton.Text := "Resume (F2)"
    } else if Running && Paused {
        Paused := false
        StatusControl.Text := "Running — resumed"
        LogStatus("Route resumed.")
        PauseButton.Text := "Pause (F2)"
    }
}

StopRoute() {
    global Running, Paused, StopRequested, StatusControl, CycleStatusControl
    global StartButton, PauseButton, StopButton
    StopRequested := true
    Running := false
    Paused := false
    ReleaseMovementKeys()
    StatusControl.Text := "Stopped"
    LogStatus("Route stopped by user.")
    CycleStatusControl.Text := "Route stopped by user"
    StartButton.Enabled := true
    PauseButton.Enabled := false
    PauseButton.Text := "Pause (F2)"
    StopButton.Enabled := false
}

RunRoute() {
    global Running, Paused, StopRequested, RouteBusy, ClaimImage, RouteCycles
    global StatusControl, CycleStatusControl, StartButton, PauseButton, StopButton
    events := [
        [0, "sc011", true], [4313, "sc011", false],
        [4516, "sc039", true], [7891, "sc039", false],
        [8047, "sc01F", true], [8438, "sc01F", false],
        [8672, "sc01E", true], [9125, "sc01E", false],
        [14972, "sc01E", true], [16081, "sc01E", false],
        [24219, "sc01E", true], [25453, "sc01E", false],
        [31141, "sc01E", true], [32234, "sc01E", false],
        [39438, "sc01E", true], [40391, "sc01E", false],
        [46438, "sc01E", true], [47656, "sc01E", false]
    ]
    try {
        ; Send input to Roblox rather than leaving focus on the GUI.
        if WinExist("ahk_exe RobloxPlayerBeta.exe") {
            WinActivate("ahk_exe RobloxPlayerBeta.exe")
            Sleep 500
        } else {
            StatusControl.Text := "Roblox not detected"
            LogStatus("Roblox window not found. Open the game and try again.")
            MsgBox "Roblox was not detected. Open Bee Swarm Simulator, then press Start again.", "NectarX", "Icon!"
            return
        }
        Loop RouteCycles {
            cycle := A_Index
            if !WaitUntilRunnable()
                break
            StatusControl.Text := "Running — keyboard route active"
            LogStatus("Running route cycle " cycle " of " RouteCycles ".")
            CycleStatusControl.Text := "Cycle " cycle " of " RouteCycles
            cycleStart := A_TickCount
            for event in events {
                if !WaitForRecordingTime(cycleStart, event[1])
                    break
                if event[3]
                    Send "{" event[2] " down}"
                else
                    Send "{" event[2] " up}"
            }
            if StopRequested
                break
            ReleaseMovementKeys()
            if FindClaimImage(ClaimImage) {
                Send "{e}"
                ReleaseMovementKeys()
                StatusControl.Text := "Hive image found — E pressed"
                LogStatus("Hive image matched; E pressed. Exiting.")
                CycleStatusControl.Text := "Detection successful; closing NectarX..."
                Sleep 700
                ExitApp
            }
        }
        if !StopRequested {
            StatusControl.Text := "Finished"
            LogStatus("Route finished; selected image was not found.")
            CycleStatusControl.Text := "Completed " RouteCycles " cycle(s); hive image not found"
        }
    } catch as err {
        ReleaseMovementKeys()
        MsgBox "NectarX route error:" Chr(10) err.Message, "NectarX", "Iconx"
        StatusControl.Text := "Error — see message"
        LogStatus("ERROR: " err.Message)
    } finally {
        ReleaseMovementKeys()
        Running := false
        Paused := false
        RouteBusy := false
        StartButton.Enabled := true
        PauseButton.Enabled := false
        PauseButton.Text := "Pause (F2)"
        StopButton.Enabled := false
    }
}

WaitForRecordingTime(cycleStart, targetMs) {
    global StopRequested, ClaimImage, Paused
    loop {
        ; Freeze the recorded route clock while paused so the timing does not skip ahead.
        if Paused {
            pauseStart := A_TickCount
            if !WaitUntilRunnable()
                return false
            cycleStart += A_TickCount - pauseStart
        }
        if (A_TickCount - cycleStart >= targetMs)
            break
        if !WaitUntilRunnable()
            return false
        if FindClaimImage(ClaimImage) {
            ReleaseMovementKeys()
            Send "{e}"
            ReleaseMovementKeys()
            Sleep 500
            ExitApp
        }
        Sleep 200
    }
    return WaitUntilRunnable()
}

LogStatus(message) {
    global LogControl
    if IsObject(LogControl)
        LogControl.Value := FormatTime(, "HH:mm:ss") "  " message
}

WaitUntilRunnable() {
    global Running, Paused, StopRequested
    while Paused && !StopRequested
        Sleep 50
    return Running && !StopRequested
}

FindClaimImage(imagePath) {
    if (imagePath = "")
        return false
    try {
        return ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*35 " imagePath)
    } catch as err {
        MsgBox "Could not search for the selected image:" Chr(10) err.Message, "NectarX image detection", "Iconx"
        return false
    }
}

ReleaseMovementKeys() {
    Send "{sc011 up}{sc039 up}{sc01F up}{sc01E up}{w up}{a up}{s up}{d up}{e up}"
}
