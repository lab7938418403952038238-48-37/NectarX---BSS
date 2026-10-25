#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NectarX - Bee Swarm Simulator macro GUI scaffold.
; Pattern files are fragments; shared movement helpers still need integration.
global PatternDir := A_ScriptDir "\NectarX patterns"
global ConfigFile := A_ScriptDir "\NectarX.ini"
global LogFile := A_ScriptDir "\NectarX.log"

settings := LoadSettings()
main := Gui("+Resize +MinSize700x500", "NectarX")
main.BackColor := "10151F"
main.SetFont("s10 cEAF0FF", "Segoe UI")
main.OnEvent("Close", (*) => ExitApp())
main.OnEvent("Size", GuiResize)
title := main.AddText("x22 y18 w420 h34 c69E7FF", "NectarX")
title.SetFont("s22 bold", "Segoe UI")
main.AddText("x24 y54 w620 h22 cAAB7D0", "Bee Swarm Simulator - Macro control center")
main.AddGroupBox("x22 y88 w650 h82", " STATUS ")
status := main.AddText("x42 y116 w600 h24 cFFC766", "● SETUP - runner engine not connected")
main.AddText("x42 y140 w600 h18 cAAB7D0", "Configure your pattern library here. Automation will not start yet.")

tabs := main.AddTab3("x22 y185 w650 h245", ["Dashboard", "Patterns", "Settings", "Logs"])
tabs.UseTab(1)
main.AddText("x44 y222 w570 h24 c69E7FF", "Quick start")
main.AddText("x44 y253 w570 h22", "1. Select a pattern on the Patterns tab.")
main.AddText("x44 y278 w570 h22", "2. Set repetitions and movement scale.")
main.AddText("x44 y303 w570 h22", "3. Save settings. The shared movement runner is still needed.")
main.AddText("x44 y350 w570 h22 cAAB7D0", "Start remains guarded until pattern execution is implemented.")
tabs.UseTab(2)
main.AddText("x44 y222 w150 h22", "Available pattern")
patternList := main.AddDropDownList("x44 y248 w270 Choose1", [])
refreshBtn := main.AddButton("x326 y247 w105 h27", "Refresh")
refreshBtn.OnEvent("Click", RefreshPatterns)
main.AddText("x44 y292 w140 h22", "Repetitions")
repsBox := main.AddEdit("x44 y316 w110 h28 Number", settings.reps)
main.AddText("x180 y292 w140 h22", "Movement scale")
sizeBox := main.AddEdit("x180 y316 w110 h28", settings.size)
main.AddText("x44 y360 w575 h34 cAAB7D0", "Patterns call shared helpers such as Walk() and need movement-key variables.")
tabs.UseTab(3)
main.AddText("x44 y222 w160 h22", "Roblox window title")
windowBox := main.AddEdit("x44 y248 w280 h28", settings.windowTitle)
main.AddText("x44 y292 w160 h22", "Start hotkey (planned)")
hotkeyBox := main.AddEdit("x44 y318 w130 h28", settings.startHotkey)
main.AddText("x44 y362 w575 h32 cAAB7D0", "Settings save to NectarX.ini beside this script.")
tabs.UseTab(4)
logBox := main.AddEdit("x44 y222 w600 h185 +ReadOnly -Wrap", ReadLog())
tabs.UseTab()
startBtn := main.AddButton("x22 y448 w150 h38", "Start")
startBtn.OnEvent("Click", StartMacro)
stopBtn := main.AddButton("x184 y448 w150 h38", "Stop")
stopBtn.OnEvent("Click", StopMacro)
saveBtn := main.AddButton("x354 y448 w150 h38", "Save settings")
saveBtn.OnEvent("Click", SaveSettings)
openBtn := main.AddButton("x524 y448 w148 h38", "Open pattern folder")
openBtn.OnEvent("Click", (*) => Run('explorer.exe "' PatternDir '"'))
RefreshPatterns()
Log("NectarX GUI started. Pattern runner integration is pending.")
main.Show("w700 h510")

RefreshPatterns(*) {
    global patternList, PatternDir
    items := []
    if DirExist(PatternDir) {
        Loop Files, PatternDir "\*.ahk", "F"
            items.Push(RegExReplace(A_LoopFileName, "\.ahk$", ""))
    }
    patternList.Delete()
    if items.Length
        patternList.Add(items)
    else
        patternList.Add(["No .ahk patterns found"])
    patternList.Choose(1)
}
LoadSettings() {
    global ConfigFile
    return {
        reps: IniRead(ConfigFile, "General", "Repetitions", "3"),
        size: IniRead(ConfigFile, "General", "MovementScale", "1.0"),
        windowTitle: IniRead(ConfigFile, "General", "WindowTitle", "Roblox"),
        startHotkey: IniRead(ConfigFile, "General", "StartHotkey", "F6")
    }
}
SaveSettings(*) {
    global ConfigFile, repsBox, sizeBox, windowBox, hotkeyBox
    try reps := Integer(repsBox.Value)
    catch {
        MsgBox("Repetitions must be a whole number.", "NectarX", "Icon!")
        return
    }
    try scale := Number(sizeBox.Value)
    catch {
        MsgBox("Movement scale must be numeric.", "NectarX", "Icon!")
        return
    }
    if reps < 1 || reps > 100 {
        MsgBox("Repetitions must be between 1 and 100.", "NectarX", "Icon!")
        return
    }
    if scale <= 0 || scale > 10 {
        MsgBox("Movement scale must be greater than 0 and at most 10.", "NectarX", "Icon!")
        return
    }
    IniWrite(reps, ConfigFile, "General", "Repetitions")
    IniWrite(scale, ConfigFile, "General", "MovementScale")
    IniWrite(Trim(windowBox.Value), ConfigFile, "General", "WindowTitle")
    IniWrite(Trim(hotkeyBox.Value), ConfigFile, "General", "StartHotkey")
    Log("Settings saved.")
    MsgBox("Settings saved to NectarX.ini.", "NectarX", "Iconi")
}
StartMacro(*) {
    global status, patternList
    selected := patternList.Text
    if !selected || selected = "No .ahk patterns found" {
        MsgBox("Choose a pattern first.", "NectarX", "Icon!")
        return
    }
    status.Text := "● BLOCKED - pattern runner not connected"
    MsgBox("The GUI is ready, but this pattern cannot run yet. Uploaded files call helpers such as Walk() and use key variables not defined in a main runner. Start is guarded so it cannot launch a broken macro.", "NectarX - runner required", "Icon!")
}
StopMacro(*) {
    global status
    status.Text := "● IDLE - no automation running"
    Log("Stop pressed. No runner process was active.")
}
GuiResize(guiObj, minMax, width, height) {
    if minMax = -1
        return
}
ReadLog() {
    global LogFile
    return FileExist(LogFile) ? FileRead(LogFile, "UTF-8") : "No log entries yet."
}
Log(message) {
    global LogFile, logBox
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " message Chr(10), LogFile, "UTF-8")
    try logBox.Value := ReadLog()
}
