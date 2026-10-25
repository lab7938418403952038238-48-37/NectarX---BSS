#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NectarX - original GUI and screen-recognition scaffold.
; Screen matching uses AutoHotkey's built-in ImageSearch with user-provided templates.
; Put PNG templates in "NectarX images". Start remains guarded until the runner is tested.

global PatternDir := A_ScriptDir "\NectarX patterns"
global ImageDir := A_ScriptDir "\NectarX images"
global ConfigFile := A_ScriptDir "\NectarX.ini"
global LogFile := A_ScriptDir "\NectarX.log"
global IsRunning := false
global RobloxHwnd := 0

CoordMode "Pixel", "Screen"
DirCreate(ImageDir)
settings := LoadSettings()

main := Gui("+Resize +MinSize760x570", "NectarX")
main.BackColor := "10151F"
main.SetFont("s10 cEAF0FF", "Segoe UI")
main.OnEvent("Close", (*) => ExitApp())
main.OnEvent("Size", GuiResize)

title := main.AddText("x22 y16 w420 h34 c69E7FF", "NectarX")
title.SetFont("s22 bold", "Segoe UI")
main.AddText("x24 y52 w690 h22 cAAB7D0", "Bee Swarm Simulator macro control center")
main.AddGroupBox("x22 y82 w710 h72", " LIVE STATUS ")
status := main.AddText("x42 y108 w660 h22 cFFC766", "● SETUP - waiting for Roblox")
windowStatus := main.AddText("x42 y132 w660 h18 cAAB7D0", "Screen reader is available for testing. Movement runner is not enabled.")

tabs := main.AddTab3("x22 y166 w710 h330", ["Dashboard", "Patterns", "Screen Reader", "Settings", "Logs"])
tabs.UseTab(1)
main.AddText("x44 y205 w620 h24 c69E7FF", "Welcome to NectarX")
main.AddText("x44 y240 w640 h24", "Choose a pattern, configure movement, and test screen templates.")
main.AddText("x44 y276 w640 h24", "Screen recognition uses PNG templates you provide in NectarX images.")
main.AddText("x44 y312 w640 h40 cAAB7D0", "Safety: Start stays disabled logically until movement helpers and pattern execution are validated.")
main.AddText("x44 y374 w640 h24 cAAB7D0", "Planned modules: Roblox window detection, image matching, runner, logs, and safe stop.")

tabs.UseTab(2)
main.AddText("x44 y205 w170 h22", "Pattern")
patternList := main.AddDropDownList("x44 y231 w300 Choose1", [])
refreshPatternsBtn := main.AddButton("x356 y230 w110 h28", "Refresh list")
refreshPatternsBtn.OnEvent("Click", RefreshPatterns)
main.AddText("x44 y275 w150 h22", "Repetitions")
repsBox := main.AddEdit("x44 y301 w120 h28 Number", settings.reps)
main.AddText("x194 y275 w150 h22", "Movement scale")
sizeBox := main.AddEdit("x194 y301 w120 h28", settings.size)
main.AddText("x44 y352 w630 h50 cAAB7D0", "The pattern files are snippets that expect shared functions and movement-key variables. They are not safe to execute by themselves yet.")
main.AddText("x44 y422 w630 h22 cFFC766", "Runner status: NOT CONNECTED")

tabs.UseTab(3)
main.AddText("x44 y205 w620 h22 c69E7FF", "Image template testing")
main.AddText("x44 y235 w630 h22", "Place a cropped PNG of a recognizable Roblox/BSS UI element in NectarX images.")
main.AddText("x44 y270 w140 h22", "Template")
imageList := main.AddDropDownList("x44 y296 w300 Choose1", [])
refreshImagesBtn := main.AddButton("x356 y295 w110 h28", "Refresh images")
refreshImagesBtn.OnEvent("Click", RefreshImages)
testImageBtn := main.AddButton("x44 y340 w180 h32", "Test selected image")
testImageBtn.OnEvent("Click", TestSelectedImage)
findRobloxBtn := main.AddButton("x236 y340 w180 h32", "Detect Roblox window")
findRobloxBtn.OnEvent("Click", DetectRobloxButton)
imageResult := main.AddEdit("x44 y386 w640 h62 +ReadOnly -Wrap", "No image test run yet.")
main.AddText("x44 y458 w640 h22 cAAB7D0", "Matching is limited to the Roblox client area when its window is detected.")

tabs.UseTab(4)
main.AddText("x44 y205 w180 h22", "Roblox window title")
windowBox := main.AddEdit("x44 y231 w300 h28", settings.windowTitle)
main.AddText("x44 y275 w150 h22", "Default repetitions")
repsSettingBox := main.AddEdit("x44 y301 w120 h28 Number", settings.reps)
main.AddText("x194 y275 w150 h22", "Default scale")
sizeSettingBox := main.AddEdit("x194 y301 w120 h28", settings.size)
main.AddText("x44 y352 w640 h22", "Image match variation (0-255)")
variationBox := main.AddEdit("x44 y378 w120 h28 Number", settings.variation)
main.AddText("x44 y422 w640 h22 cAAB7D0", "Settings save locally to NectarX.ini. Image templates stay in NectarX images.")

tabs.UseTab(5)
logBox := main.AddEdit("x44 y205 w650 h245 +ReadOnly -Wrap", ReadLog())
tabs.UseTab()

startBtn := main.AddButton("x22 y510 w150 h38", "Start (not ready)")
startBtn.OnEvent("Click", StartMacro)
stopBtn := main.AddButton("x184 y510 w150 h38", "Stop")
stopBtn.OnEvent("Click", StopMacro)
saveBtn := main.AddButton("x354 y510 w150 h38", "Save settings")
saveBtn.OnEvent("Click", SaveSettings)
openPatternsBtn := main.AddButton("x514 y510 w218 h38", "Open project folder")
openPatternsBtn.OnEvent("Click", (*) => Run('explorer.exe "' A_ScriptDir '"'))

RefreshPatterns()
RefreshImages()
DetectRoblox()
Log("NectarX initialized. ImageSearch template testing is ready; movement runner remains disabled.")
SetTimer(UpdateStatus, 2000)
main.Show("w760 h570")

RefreshPatterns(*) {
    global patternList, PatternDir
    items := []
    if DirExist(PatternDir) {
        Loop Files, PatternDir "\*.ahk", "F"
            items.Push(RegExReplace(A_LoopFileName, "\.ahk$", ""))
    }
    patternList.Delete()
    patternList.Add(items.Length ? items : ["No .ahk patterns found"])
    patternList.Choose(1)
}

RefreshImages(*) {
    global imageList, ImageDir
    items := []
    if DirExist(ImageDir) {
        Loop Files, ImageDir "\*.png", "F"
            items.Push(A_LoopFileName)
        Loop Files, ImageDir "\*.bmp", "F"
            items.Push(A_LoopFileName)
    }
    imageList.Delete()
    imageList.Add(items.Length ? items : ["No templates found"])
    imageList.Choose(1)
    Log("Image template list refreshed (" items.Length " found).")
}

LoadSettings() {
    global ConfigFile
    return {
        reps: IniRead(ConfigFile, "General", "Repetitions", "3"),
        size: IniRead(ConfigFile, "General", "MovementScale", "1.0"),
        windowTitle: IniRead(ConfigFile, "General", "WindowTitle", "Roblox"),
        variation: IniRead(ConfigFile, "ScreenReader", "Variation", "35")
    }
}

SaveSettings(*) {
    global ConfigFile, repsBox, sizeBox, repsSettingBox, sizeSettingBox
    global windowBox, variationBox
    try reps := Integer(repsSettingBox.Value)
    catch {
        MsgBox("Repetitions must be a whole number.", "NectarX", "Icon!")
        return
    }
    try scale := Number(sizeSettingBox.Value)
    catch {
        MsgBox("Movement scale must be numeric.", "NectarX", "Icon!")
        return
    }
    try variation := Integer(variationBox.Value)
    catch {
        MsgBox("Image variation must be a whole number.", "NectarX", "Icon!")
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
    if variation < 0 || variation > 255 {
        MsgBox("Image variation must be between 0 and 255.", "NectarX", "Icon!")
        return
    }
    IniWrite(reps, ConfigFile, "General", "Repetitions")
    IniWrite(scale, ConfigFile, "General", "MovementScale")
    IniWrite(Trim(windowBox.Value), ConfigFile, "General", "WindowTitle")
    IniWrite(variation, ConfigFile, "ScreenReader", "Variation")
    repsBox.Value := reps
    sizeBox.Value := scale
    Log("Settings saved.")
    MsgBox("Settings saved to NectarX.ini.", "NectarX", "Iconi")
}

DetectRobloxButton(*) {
    global imageResult
    if DetectRoblox()
        imageResult.Value := "Roblox window detected." Chr(13) Chr(10) "Client bounds: " GetClientBoundsText()
    else
        imageResult.Value := "Roblox window not found. Open the Roblox game client first."
}

DetectRoblox() {
    global RobloxHwnd, status, windowStatus
    RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !RobloxHwnd && windowBox.Value != ""
        RobloxHwnd := WinExist(windowBox.Value)
    if RobloxHwnd {
        try title := WinGetTitle("ahk_id " RobloxHwnd)
        catch
            title := "Roblox"
        status.Text := "● READY - Roblox window detected"
        windowStatus.Text := "Window: " title " | image matching targets the client area."
        return true
    }
    status.Text := "● WAITING - Roblox window not found"
    windowStatus.Text := "Open Roblox. Image matching will search only inside the detected client area."
    return false
}

GetClientBoundsText() {
    global RobloxHwnd
    if !RobloxHwnd
        return "unavailable"
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_id " RobloxHwnd)
        return x ", " y ", " w "x" h
    } catch {
        return "unable to read client bounds"
    }
}

TestSelectedImage(*) {
    global imageList, ImageDir, imageResult, RobloxHwnd, variationBox
    if imageList.Text = "" || imageList.Text = "No templates found" {
        imageResult.Value := "No templates found." Chr(13) Chr(10) "Add a cropped PNG/BMP template to: " ImageDir
        return
    }
    if !DetectRoblox() {
        imageResult.Value := "Roblox window not found. Open Roblox before testing image matching."
        return
    }
    imagePath := ImageDir "\" imageList.Text
    if !FileExist(imagePath) {
        imageResult.Value := "Template file missing: " imagePath
        RefreshImages()
        return
    }
    try variation := Integer(variationBox.Value)
    catch {
        imageResult.Value := "Variation must be a number between 0 and 255."
        return
    }
    if variation < 0 || variation > 255 {
        imageResult.Value := "Variation must be between 0 and 255."
        return
    }
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_id " RobloxHwnd)
        if ImageSearch(&fx, &fy, x, y, x+w-1, y+h-1, "*" variation " " imagePath) {
            imageResult.Value := "MATCH FOUND: " imageList.Text Chr(13) Chr(10) "Screen position: " fx ", " fy
            Log("Image matched: " imageList.Text " at " fx "," fy)
        } else {
            imageResult.Value := "No match found for: " imageList.Text Chr(13) Chr(10) "Try a tighter crop or adjust image variation."
            Log("Image not found: " imageList.Text)
        }
    } catch as err {
        imageResult.Value := "No match (or template/search error)." Chr(13) Chr(10) "Template: " imageList.Text Chr(13) Chr(10) err.Message
        Log("Image not matched: " imageList.Text)
    }
}

StartMacro(*) {
    global status
    status.Text := "● BLOCKED - runner not connected"
    MsgBox("Screen-template testing is available, but movement execution is not enabled yet. The pattern snippets need a compatible runner and safe-stop handling before Start can run them.", "NectarX", "Icon!")
}

StopMacro(*) {
    global status
    status.Text := "● IDLE - no automation running"
    Send "{w up}{a up}{s up}{d up}{Shift up}{Space up}"
    Log("Stop pressed; common movement keys released.")
}

UpdateStatus() {
    DetectRoblox()
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
