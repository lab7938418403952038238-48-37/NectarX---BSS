#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NectarX Control Center - original blue/black multi-page GUI.
; IMPORTANT: this is a configuration/control-center build. It does not yet
; execute Bee Swarm farming routines or claim live game telemetry.
global ConfigFile := A_ScriptDir "\NectarX.ini"
global LogFile := A_ScriptDir "\NectarX.log"
global ImageDir := A_ScriptDir "\NectarX images"
global PatternDir := A_ScriptDir "\NectarX patterns"
global PathDir := A_ScriptDir "\NectarX paths"
global RobloxHwnd := 0
global sessionState := "IDLE"
global sessionElapsedMs := 0
global sessionSegmentStart := 0
global activeHotkeys := []
global fields := ["Sunflower","Dandelion","Mushroom","Blue Flower","Clover","Spider","Strawberry","Bamboo","Pine Tree","Stump","Cactus","Pumpkin","Pineapple","Rose","Mountain Top","Pepper","Coconut"]
global nectars := ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
global sprinklers := ["Basic Sprinkler","Silver Soakers","Golden Gushers","Diamond Drenchers","Supreme Saturator"]
global planters := ["Paper Planter","Plastic Planter","Ticket Planter","Candy Planter","Red Clay Planter","Blue Clay Planter","Tacky Planter","Pesticide Planter","Heat-Treated Planter","Hydroponic Planter","Petal Planter","Planter of Plenty","Festive Planter","Sticker Planter"]
global cfg := LoadSettings()
global planterChecks := Map()
global sprinklerChecks := Map()
global nectarEdits := Map()
global nectarStatusRows := []
global planterFieldBoxes := []

CoordMode "Pixel", "Screen"
DirCreate(ImageDir)
DirCreate(PatternDir)
DirCreate(PathDir)

main := Gui("+Resize +MinSize980x720", "NectarX | Control Center")
main.BackColor := "0A1020"
main.SetFont("s10 cE8F0FF", "Segoe UI")
main.OnEvent("Close", OnClose)
main.OnEvent("Size", GuiResize)

brand := main.AddText("x22 y14 w360 h34 c55B7FF", "NECTARX")
brand.SetFont("s23 bold", "Segoe UI")
main.AddText("x24 y49 w560 h20 c91A8C9", "BEE SWARM SIMULATOR  /  CONTROL CENTER")
statusLabel := main.AddText("x720 y22 w370 h24 cFFC766 Right", "● IDLE  |  RUNNER NOT CONNECTED")
statusLabel.SetFont("s10 bold", "Segoe UI")
statusDetail := main.AddText("x520 y49 w570 h20 c91A8C9 Right", "Settings mode — no game inputs are being sent.")
tabs := main.AddTab3("x18 y80 w1094 h608", ["Dashboard","Gather","Sprinklers","Planters & Nectar","Patterns","Screen Reader","Settings","Logs"])

; Dashboard
tabs.UseTab(1)
main.AddGroupBox("x38 y118 w330 h118", " SESSION STATUS ")
dashSession := main.AddText("x58 y151 w282 h27 c55B7FF", "00:00:00")
dashSession.SetFont("s22 bold", "Segoe UI")
dashState := main.AddText("x58 y187 w282 h22 cFFC766", "IDLE — ready to configure")
main.AddGroupBox("x385 y118 w330 h118", " GATHER CONFIGURATION ")
dashField := main.AddText("x405 y151 w286 h23", "Field: " cfg.field)
dashPattern := main.AddText("x405 y181 w286 h23", "Pattern: " cfg.pattern)
dashLimit := main.AddText("x405 y207 w286 h20 c91A8C9", "Time " cfg.gatherMinutes " min  |  Pack " cfg.backpackLimit "%")
main.AddGroupBox("x732 y118 w340 h118", " LIVE TELEMETRY ")
dashBackpack := main.AddText("x752 y151 w300 h22 cFFC766", "Backpack: unavailable")
dashActivity := main.AddText("x752 y181 w300 h22", "Activity: configuration only")
dashTelemetry := main.AddText("x752 y207 w300 h20 c91A8C9", "Game reader / runner not connected")
main.AddGroupBox("x38 y254 w510 h190", " NECTAR TARGETS  /  ACTUAL LEVELS REQUIRE GAME READING ")
for i, nectarName in nectars {
    y := 283 + (i - 1) * 29
    main.AddText("x58 y" y " w160 h22", nectarName)
    targetTxt := main.AddText("x224 y" y " w110 h22 c55B7FF", "Target: " cfg[StrReplace(nectarName, " ", "") "Target"] "%")
    actualTxt := main.AddText("x350 y" y " w175 h22 c91A8C9", "Actual: unavailable")
    nectarStatusRows.Push({target:targetTxt, actual:actualTxt, name:nectarName})
}
main.AddGroupBox("x568 y254 w504 h190", " PLANTER TRACKER ")
dashPlanterSummary := main.AddText("x590 y284 w460 h46", "Owned planters: " CountOwnedPlanters() "  |  Harvest interval: " cfg.harvestInterval " h")
dashPlanterStatus := main.AddText("x590 y334 w460 h48 c91A8C9", "Growth timers and maturity detection need a game reader.")
dashSprinklerStatus := main.AddText("x590 y389 w460 h25", "Selected sprinkler: " cfg.activeSprinkler)
main.AddGroupBox("x38 y460 w1034 h190", " ACTIVITY / SESSION LOG ")
dashboardLog := main.AddEdit("x58 y488 w994 h142 +ReadOnly -Wrap", ReadLog())
main.AddText("x58 y636 w990 h18 c7187AB", "Preview session controls work. They do not yet control movement inside Roblox.")

; Gather
tabs.UseTab(2)
main.AddGroupBox("x38 y118 w500 h250", " FIELD AND PATTERN ")
main.AddText("x58 y151 w190 h22", "Gather field")
gatherFieldBox := main.AddDropDownList("x58 y177 w210 Choose1", fields)
main.AddText("x290 y151 w210 h22", "Pattern")
gatherPatternBox := main.AddDropDownList("x290 y177 w220 Choose1", ["Scanning patterns..."])
main.AddText("x58 y224 w190 h22", "Pattern size")
patternSizeBox := main.AddDropDownList("x58 y250 w125 Choose3", ["XS","S","M","L","XL"])
main.AddText("x203 y224 w190 h22", "Pattern width")
patternWidthBox := main.AddEdit("x203 y250 w125 h28 Number", cfg.patternWidth)
main.AddText("x350 y224 w140 h22", "Repetitions")
repsBox := main.AddEdit("x350 y250 w125 h28 Number", cfg.repetitions)
main.AddText("x58 y298 w190 h22", "Gather until (minutes)")
gatherMinutesBox := main.AddEdit("x58 y324 w125 h28 Number", cfg.gatherMinutes)
main.AddText("x203 y298 w190 h22", "Backpack limit (%)")
backpackLimitBox := main.AddEdit("x203 y324 w125 h28 Number", cfg.backpackLimit)
shiftLockBox := main.AddCheckBox("x350 y326 w160 h24", "Gather with Shift Lock")
shiftLockBox.Value := cfg.shiftLock ? 1 : 0
main.AddGroupBox("x558 y118 w514 h250", " MOVEMENT AND RETURN ")
main.AddText("x580 y151 w190 h22", "Movement method")
moveMethodBox := main.AddDropDownList("x580 y177 w210 Choose1", ["Walk","Cannon","Walk + cannon when available"])
main.AddText("x812 y151 w210 h22", "Return to hive")
returnMethodBox := main.AddDropDownList("x812 y177 w220 Choose1", ["Walk","Reset","Cannon then walk","Configured path"])
driftCheckBox := main.AddCheckBox("x580 y224 w210 h24", "Enable drift check")
driftCheckBox.Value := cfg.driftCheck ? 1 : 0
invertFBBox := main.AddCheckBox("x580 y258 w210 h24", "Invert forward/back")
invertLRBox := main.AddCheckBox("x812 y258 w210 h24", "Invert left/right")
invertFBBox.Value := cfg.invertFB ? 1 : 0
invertLRBox.Value := cfg.invertLR ? 1 : 0
main.AddText("x580 y303 w445 h42 c91A8C9", "Time and backpack limits should both be safe-stop conditions in the future runner.")
main.AddGroupBox("x38 y390 w1034 h250", " CONFIGURATION CHECK ")
gatherConfigStatus := main.AddEdit("x58 y420 w994 h160 +ReadOnly -Wrap", "Pattern scan has not run yet.")
refreshGatherPatternsBtn := main.AddButton("x58 y592 w160 h30", "Refresh patterns")
refreshGatherPatternsBtn.OnEvent("Click", RefreshPatterns)
main.AddText("x242 y598 w800 h22 c91A8C9", "This page saves configuration now; automated movement is not connected.")

; Sprinklers
tabs.UseTab(3)
main.AddGroupBox("x38 y118 w490 h245", " SPRINKLER OWNERSHIP ")
main.AddText("x58 y149 w420 h22 c91A8C9", "Check each sprinkler tier you own.")
for i, sprinklerName in sprinklers {
    colX := i <= 3 ? 58 : 278
    row := i <= 3 ? i : i - 3
    y := 180 + (row - 1) * 40
    cb := main.AddCheckBox("x" colX " y" y " w210 h26", sprinklerName)
    cb.Value := cfg["OwnsSprinkler" i] ? 1 : 0
    sprinklerChecks[sprinklerName] := cb
}
main.AddGroupBox("x548 y118 w524 h245", " PLACEMENT CONFIGURATION ")
main.AddText("x570 y149 w200 h22", "Active sprinkler")
activeSprinklerBox := main.AddDropDownList("x570 y175 w220 Choose1", sprinklers)
main.AddText("x812 y149 w210 h22", "Field to configure")
sprinklerFieldBox := main.AddDropDownList("x812 y175 w220 Choose1", fields)
sprinklerFieldBox.OnEvent("Change", LoadSprinklerFieldSettings)
main.AddText("x570 y222 w200 h22", "Placement preset")
sprinklerPlacementBox := main.AddDropDownList("x570 y248 w220 Choose1", ["Center","Near entrance","North edge","East edge","South edge","West edge","Custom offsets"])
main.AddText("x812 y222 w100 h22", "Offset X")
sprinklerOffsetXBox := main.AddEdit("x812 y248 w80 h28 Number", cfg.sprinklerOffsetX)
main.AddText("x918 y222 w100 h22", "Offset Y")
sprinklerOffsetYBox := main.AddEdit("x918 y248 w80 h28 Number", cfg.sprinklerOffsetY)
autoSprinklerBox := main.AddCheckBox("x570 y293 w220 h24", "Auto-place on field entry")
autoSprinklerBox.Value := cfg.autoSprinkler ? 1 : 0
main.AddText("x812 y289 w230 h38 c91A8C9", "Last placement: not detected")
main.AddGroupBox("x38 y388 w1034 h252", " SPRINKLER STATUS ")
sprinklerStatusBox := main.AddEdit("x58 y418 w994 h154 +ReadOnly -Wrap", "No placement has been attempted. Saved placement requires a runner for in-game use.")
saveSprinklerFieldBtn := main.AddButton("x58 y588 w190 h30", "Save field placement")
saveSprinklerFieldBtn.OnEvent("Click", SaveSprinklerFieldSettings)
main.AddText("x270 y594 w770 h22 c91A8C9", "Live placement confirmation requires game recognition and movement integration.")

; Planters and nectar
tabs.UseTab(4)
main.AddGroupBox("x38 y118 w490 h420", " PLANTERS YOU OWN ")
main.AddText("x58 y149 w430 h22 c91A8C9", "Choose the planter inventory available on your account.")
for i, planterName in planters {
    colX := i <= 7 ? 58 : 280
    row := i <= 7 ? i : i - 7
    y := 178 + (row - 1) * 32
    cb := main.AddCheckBox("x" colX " y" y " w220 h24", planterName)
    cb.Value := cfg["OwnsPlanter" i] ? 1 : 0
    planterChecks[planterName] := cb
}
main.AddGroupBox("x548 y118 w524 h205", " NECTAR TARGETS ")
main.AddText("x568 y148 w230 h22 c91A8C9", "Target %  (0 disables target)")
for i, nectarName in nectars {
    y := 178 + (i - 1) * 27
    main.AddText("x570 y" y " w190 h22", nectarName)
    edit := main.AddEdit("x790 y" y " w74 h24 Number", cfg[StrReplace(nectarName, " ", "") "Target"])
    nectarEdits[nectarName] := edit
    main.AddText("x878 y" y " w150 h22 c91A8C9", "Actual: unavailable")
}
main.AddGroupBox("x548 y340 w524 h198", " HARVEST SCHEDULE ")
main.AddText("x568 y371 w200 h22", "Harvest rule")
harvestModeBox := main.AddDropDownList("x568 y397 w220 Choose1", ["Time interval","When mature","Manual only"])
main.AddText("x810 y371 w210 h22", "Interval (hours)")
harvestIntervalBox := main.AddEdit("x810 y397 w100 h28 Number", cfg.harvestInterval)
main.AddText("x568 y438 w440 h60 c91A8C9", "Planter field assignments and harvesting actions require a runner. Nectar targets are goals, not live readings.")
main.AddGroupBox("x38 y552 w1034 h88", " PLANTER FIELD ASSIGNMENTS ")
main.AddText("x58 y576 w165 h22", "Planter slot 1")
planterFieldBoxes.Push(main.AddDropDownList("x180 y572 w190 Choose1", ["None", "Sunflower", "Dandelion", "Mushroom", "Blue Flower", "Clover", "Spider", "Strawberry", "Bamboo", "Pine Tree", "Stump", "Cactus", "Pumpkin", "Pineapple", "Rose", "Mountain Top", "Pepper", "Coconut"]))
main.AddText("x405 y576 w165 h22", "Planter slot 2")
planterFieldBoxes.Push(main.AddDropDownList("x528 y572 w190 Choose1", ["None", "Sunflower", "Dandelion", "Mushroom", "Blue Flower", "Clover", "Spider", "Strawberry", "Bamboo", "Pine Tree", "Stump", "Cactus", "Pumpkin", "Pineapple", "Rose", "Mountain Top", "Pepper", "Coconut"]))
main.AddText("x750 y576 w100 h22", "Slot 3")
planterFieldBoxes.Push(main.AddDropDownList("x810 y572 w190 Choose1", ["None", "Sunflower", "Dandelion", "Mushroom", "Blue Flower", "Clover", "Spider", "Strawberry", "Bamboo", "Pine Tree", "Stump", "Cactus", "Pumpkin", "Pineapple", "Rose", "Mountain Top", "Pepper", "Coconut"]))

; Patterns / paths
tabs.UseTab(5)
main.AddGroupBox("x38 y118 w500 h475", " AVAILABLE PATTERNS ")
patternFilesList := main.AddListBox("x58 y151 w450 h340", [])
refreshFilesBtn := main.AddButton("x58 y510 w150 h32", "Refresh lists")
refreshFilesBtn.OnEvent("Click", RefreshPatterns)
openPatternFileBtn := main.AddButton("x224 y510 w150 h32", "Open selected")
openPatternFileBtn.OnEvent("Click", OpenSelectedPattern)
main.AddText("x58 y554 w450 h25 c91A8C9", "Scripts are listed from NectarX patterns/.")
main.AddGroupBox("x558 y118 w514 h475", " AVAILABLE PATHS ")
pathFilesList := main.AddListBox("x578 y151 w470 h340", [])
openPathFileBtn := main.AddButton("x578 y510 w160 h32", "Open selected path")
openPathFileBtn.OnEvent("Click", OpenSelectedPath)
main.AddText("x578 y554 w470 h25 c91A8C9", "Scripts are listed from NectarX paths/.")
main.AddGroupBox("x38 y608 w1034 h40", " RUNNER STATUS ")
main.AddText("x58 y620 w990 h22 cFFC766", "NOT CONNECTED — scripts are catalogued but not executed.")

; Screen reader
tabs.UseTab(6)
main.AddGroupBox("x38 y118 w1034 h195", " IMAGE TEMPLATE TESTER ")
main.AddText("x58 y151 w200 h22", "Image template")
imageList := main.AddDropDownList("x58 y177 w350 Choose1", ["No templates found"])
refreshImagesBtn := main.AddButton("x428 y176 w150 h30", "Refresh images")
refreshImagesBtn.OnEvent("Click", RefreshImages)
testImageBtn := main.AddButton("x592 y176 w175 h30", "Test selected image")
testImageBtn.OnEvent("Click", TestSelectedImage)
detectRobloxBtn := main.AddButton("x781 y176 w250 h30", "Detect Roblox window")
detectRobloxBtn.OnEvent("Click", DetectRobloxButton)
main.AddText("x58 y223 w210 h22", "Image variation (0–255)")
variationBox := main.AddEdit("x58 y249 w100 h28 Number", cfg.variation)
windowTitleBox := main.AddEdit("x190 y249 w260 h28", cfg.windowTitle)
main.AddText("x464 y252 w500 h22 c91A8C9", "Window-title fallback for detection")
main.AddGroupBox("x38 y330 w1034 h250", " DETECTION RESULT ")
imageResult := main.AddEdit("x58 y359 w994 h190 +ReadOnly -Wrap", "No image test run yet.")
main.AddText("x58 y558 w990 h22 c91A8C9", "Uses built-in AutoHotkey ImageSearch against the Roblox client area.")
main.AddText("x58 y613 w990 h22 cFFC766", "Live backpack, nectar, planter growth and game-state detection are not implemented yet.")

; Settings
tabs.UseTab(7)
main.AddGroupBox("x38 y118 w500 h230", " APPLICATION SETTINGS ")
main.AddText("x58 y151 w200 h22", "Roblox window title")
settingsWindowTitleBox := main.AddEdit("x58 y177 w280 h28", cfg.windowTitle)
main.AddText("x58 y221 w200 h22", "Default gather repetitions")
settingsRepsBox := main.AddEdit("x58 y247 w110 h28 Number", cfg.repetitions)
main.AddText("x194 y221 w200 h22", "Default pattern width")
settingsWidthBox := main.AddEdit("x194 y247 w110 h28 Number", cfg.patternWidth)
main.AddText("x58 y298 w440 h22 c91A8C9", "Settings are stored locally in NectarX.ini.")
main.AddGroupBox("x558 y118 w514 h230", " HOTKEYS ")
main.AddText("x578 y151 w130 h22", "Start / preview")
hotkeyStartBox := main.AddEdit("x710 y147 w100 h28", cfg.hotkeyStart)
main.AddText("x828 y151 w70 h22", "Pause")
hotkeyPauseBox := main.AddEdit("x902 y147 w100 h28", cfg.hotkeyPause)
main.AddText("x578 y197 w130 h22", "Stop")
hotkeyStopBox := main.AddEdit("x710 y193 w100 h28", cfg.hotkeyStop)
applyHotkeysBtn := main.AddButton("x828 y192 w174 h30", "Apply hotkeys")
applyHotkeysBtn.OnEvent("Click", ApplyHotkeys)
main.AddText("x578 y246 w455 h62 c91A8C9", "Default hotkeys: F6 starts preview, F7 pauses/resumes, F8 stops. They control the UI only.")
main.AddGroupBox("x38 y370 w1034 h220", " PROFILES ")
main.AddText("x58 y402 w150 h22", "Profile name")
profileNameBox := main.AddEdit("x58 y428 w300 h28", "Default")
saveProfileBtn := main.AddButton("x382 y427 w150 h30", "Save profile")
saveProfileBtn.OnEvent("Click", SaveProfile)
loadProfileBtn := main.AddButton("x548 y427 w150 h30", "Load profile")
loadProfileBtn.OnEvent("Click", LoadProfile)
main.AddText("x58 y474 w970 h55 c91A8C9", "Profiles copy gather settings, sprinkler/planter ownership, nectar goals, harvest rules and hotkeys. Image templates remain in NectarX images/.")
main.AddGroupBox("x38 y608 w1034 h40", " CONFIGURATION ")
main.AddText("x58 y620 w990 h22 c55B7FF", "Blue / black theme • local settings • profile support • safe preview controls")

; Logs
tabs.UseTab(8)
main.AddGroupBox("x38 y118 w1034 h478", " SESSION LOG ")
logBox := main.AddEdit("x58 y149 w994 h412 +ReadOnly -Wrap", ReadLog())
clearLogBtn := main.AddButton("x58 y574 w150 h30", "Clear log")
clearLogBtn.OnEvent("Click", ClearLog)
refreshLogBtn := main.AddButton("x224 y574 w150 h30", "Refresh log")
refreshLogBtn.OnEvent("Click", RefreshLog)
main.AddText("x398 y580 w640 h22 c91A8C9", "Logs record UI state, settings changes and detection tests.")

tabs.UseTab()
startBtn := main.AddButton("x20 y704 w170 h38", "Start / Preview")
startBtn.OnEvent("Click", StartMacro)
pauseBtn := main.AddButton("x202 y704 w150 h38", "Pause")
pauseBtn.OnEvent("Click", PauseResume)
stopBtn := main.AddButton("x364 y704 w150 h38", "Stop")
stopBtn.OnEvent("Click", StopMacro)
saveBtn := main.AddButton("x536 y704 w170 h38", "Save settings")
saveBtn.OnEvent("Click", SaveSettings)
openFolderBtn := main.AddButton("x728 y704 w180 h38", "Open project folder")
openFolderBtn.OnEvent("Click", (*) => Run('explorer.exe "' A_ScriptDir '"'))
main.AddText("x925 y713 w180 h22 c55B7FF Right", "NECTARX  /  BLUE")

ApplySettingsToControls()
RefreshPatterns()
RefreshImages()
LoadSprinklerFieldSettings()
UpdateDashboard()
BindHotkeysFromControls(false)
Log("NectarX Control Center loaded. Preview available; game-action runner is not connected.")
SetTimer(UpdateDashboard, 1000)
main.Show("w1130 h760")

LoadSettings() {
    global ConfigFile, sprinklers, planters, nectars
    s := {}
    s.field := IniRead(ConfigFile, "Gather", "Field", "Pine Tree")
    s.pattern := IniRead(ConfigFile, "Gather", "Pattern", "")
    s.patternSize := IniRead(ConfigFile, "Gather", "PatternSize", "M")
    s.patternWidth := IniRead(ConfigFile, "Gather", "PatternWidth", "10")
    s.repetitions := IniRead(ConfigFile, "Gather", "Repetitions", "3")
    s.gatherMinutes := IniRead(ConfigFile, "Gather", "Minutes", "25")
    s.backpackLimit := IniRead(ConfigFile, "Gather", "BackpackLimit", "95")
    s.shiftLock := IniRead(ConfigFile, "Gather", "ShiftLock", "1") = "1"
    s.driftCheck := IniRead(ConfigFile, "Gather", "DriftCheck", "1") = "1"
    s.invertFB := IniRead(ConfigFile, "Gather", "InvertFB", "0") = "1"
    s.invertLR := IniRead(ConfigFile, "Gather", "InvertLR", "0") = "1"
    s.moveMethod := IniRead(ConfigFile, "Gather", "MoveMethod", "Walk")
    s.returnMethod := IniRead(ConfigFile, "Gather", "ReturnMethod", "Walk")
    s.activeSprinkler := IniRead(ConfigFile, "Sprinklers", "Active", "Basic Sprinkler")
    s.sprinklerPlacement := IniRead(ConfigFile, "Sprinklers", "Placement", "Center")
    s.sprinklerOffsetX := IniRead(ConfigFile, "Sprinklers", "OffsetX", "0")
    s.sprinklerOffsetY := IniRead(ConfigFile, "Sprinklers", "OffsetY", "0")
    s.autoSprinkler := IniRead(ConfigFile, "Sprinklers", "AutoPlace", "0") = "1"
    for i, name in sprinklers
        s["OwnsSprinkler" i] := IniRead(ConfigFile, "Sprinklers", "Owns" i, i = 1 ? "1" : "0") = "1"
    s.harvestMode := IniRead(ConfigFile, "Planters", "HarvestMode", "Time interval")
    s.harvestInterval := IniRead(ConfigFile, "Planters", "HarvestInterval", "2")
    s.planterField1 := IniRead(ConfigFile, "Planters", "Field1", "Pine Tree")
    s.planterField2 := IniRead(ConfigFile, "Planters", "Field2", "Strawberry")
    s.planterField3 := IniRead(ConfigFile, "Planters", "Field3", "None")
    for i, name in planters
        s["OwnsPlanter" i] := IniRead(ConfigFile, "Planters", "Owns" i, "0") = "1"
    for i, name in nectars
        s[StrReplace(name, " ", "") "Target"] := IniRead(ConfigFile, "Nectar", StrReplace(name, " ", "") "Target", "50")
    s.windowTitle := IniRead(ConfigFile, "ScreenReader", "WindowTitle", "Roblox")
    s.variation := IniRead(ConfigFile, "ScreenReader", "Variation", "35")
    s.hotkeyStart := IniRead(ConfigFile, "Hotkeys", "Start", "F6")
    s.hotkeyPause := IniRead(ConfigFile, "Hotkeys", "Pause", "F7")
    s.hotkeyStop := IniRead(ConfigFile, "Hotkeys", "Stop", "F8")
    return s
}

ApplySettingsToControls() {
    global cfg, gatherFieldBox, gatherPatternBox, patternSizeBox, patternWidthBox, repsBox
    global gatherMinutesBox, backpackLimitBox, shiftLockBox, driftCheckBox, invertFBBox, invertLRBox
    global moveMethodBox, returnMethodBox, sprinklerChecks, activeSprinklerBox, sprinklerFieldBox
    global sprinklerPlacementBox, sprinklerOffsetXBox, sprinklerOffsetYBox, autoSprinklerBox
    global planterChecks, nectarEdits, harvestModeBox, harvestIntervalBox, planterFieldBoxes
    global windowTitleBox, settingsWindowTitleBox, settingsRepsBox, settingsWidthBox, variationBox
    global hotkeyStartBox, hotkeyPauseBox, hotkeyStopBox
    gatherFieldBox.ChooseString(cfg.field)
    patternSizeBox.ChooseString(cfg.patternSize)
    patternWidthBox.Value := cfg.patternWidth
    repsBox.Value := cfg.repetitions
    gatherMinutesBox.Value := cfg.gatherMinutes
    backpackLimitBox.Value := cfg.backpackLimit
    shiftLockBox.Value := cfg.shiftLock ? 1 : 0
    driftCheckBox.Value := cfg.driftCheck ? 1 : 0
    invertFBBox.Value := cfg.invertFB ? 1 : 0
    invertLRBox.Value := cfg.invertLR ? 1 : 0
    moveMethodBox.ChooseString(cfg.moveMethod)
    returnMethodBox.ChooseString(cfg.returnMethod)
    activeSprinklerBox.ChooseString(cfg.activeSprinkler)
    sprinklerFieldBox.ChooseString(cfg.field)
    sprinklerPlacementBox.ChooseString(cfg.sprinklerPlacement)
    sprinklerOffsetXBox.Value := cfg.sprinklerOffsetX
    sprinklerOffsetYBox.Value := cfg.sprinklerOffsetY
    autoSprinklerBox.Value := cfg.autoSprinkler ? 1 : 0
    for i, name in ["Basic Sprinkler","Silver Soakers","Golden Gushers","Diamond Drenchers","Supreme Saturator"]
        sprinklerChecks[name].Value := cfg["OwnsSprinkler" i] ? 1 : 0
    for i, name in ["Paper Planter","Plastic Planter","Ticket Planter","Candy Planter","Red Clay Planter","Blue Clay Planter","Tacky Planter","Pesticide Planter","Heat-Treated Planter","Hydroponic Planter","Petal Planter","Planter of Plenty","Festive Planter","Sticker Planter"]
        planterChecks[name].Value := cfg["OwnsPlanter" i] ? 1 : 0
    for name in ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
        nectarEdits[name].Value := cfg[StrReplace(name, " ", "") "Target"]
    harvestModeBox.ChooseString(cfg.harvestMode)
    harvestIntervalBox.Value := cfg.harvestInterval
    planterFieldBoxes[1].ChooseString(cfg.planterField1)
    planterFieldBoxes[2].ChooseString(cfg.planterField2)
    planterFieldBoxes[3].ChooseString(cfg.planterField3)
    windowTitleBox.Value := cfg.windowTitle
    settingsWindowTitleBox.Value := cfg.windowTitle
    variationBox.Value := cfg.variation
    settingsRepsBox.Value := cfg.repetitions
    settingsWidthBox.Value := cfg.patternWidth
    hotkeyStartBox.Value := cfg.hotkeyStart
    hotkeyPauseBox.Value := cfg.hotkeyPause
    hotkeyStopBox.Value := cfg.hotkeyStop
    UpdateDashboard()
}

SaveSettings(*) {
    if !SaveSettingsCore()
        return
    Log("Settings saved.")
    MsgBox("Settings saved to NectarX.ini.", "NectarX", "Iconi")
}

SaveSettingsCore() {
    global ConfigFile, cfg, gatherFieldBox, gatherPatternBox, patternSizeBox, patternWidthBox
    global repsBox, gatherMinutesBox, backpackLimitBox, shiftLockBox, driftCheckBox, invertFBBox
    global invertLRBox, moveMethodBox, returnMethodBox, sprinklerChecks, activeSprinklerBox
    global sprinklerPlacementBox, sprinklerOffsetXBox, sprinklerOffsetYBox, autoSprinklerBox
    global planterChecks, nectarEdits, harvestModeBox, harvestIntervalBox, planterFieldBoxes
    global settingsWindowTitleBox, settingsRepsBox, settingsWidthBox, variationBox
    global hotkeyStartBox, hotkeyPauseBox, hotkeyStopBox, sprinklerFieldBox
    try {
        minutes := Integer(gatherMinutesBox.Value)
        pack := Integer(backpackLimitBox.Value)
        width := Integer(patternWidthBox.Value)
        reps := Integer(repsBox.Value)
        hours := Number(harvestIntervalBox.Value)
        offX := Integer(sprinklerOffsetXBox.Value)
        offY := Integer(sprinklerOffsetYBox.Value)
        variation := Integer(variationBox.Value)
        settingsReps := Integer(settingsRepsBox.Value)
        settingsWidth := Integer(settingsWidthBox.Value)
    } catch {
        MsgBox("Numeric setting is invalid. Check gather minutes, pack %, width, repetitions, offsets, harvest interval and image variation.", "NectarX", "Icon!")
        return false
    }
    if minutes < 1 || minutes > 720 || pack < 10 || pack > 100 || width < 1 || width > 100 || settingsWidth < 1 || settingsWidth > 100 || reps < 1 || reps > 100 || settingsReps < 1 || settingsReps > 100 || hours <= 0 || hours > 168 || variation < 0 || variation > 255 {
        MsgBox("A number is outside its allowed range. Minutes: 1–720, pack: 10–100, width: 1–100, repetitions: 1–100, harvest hours: greater than 0–168, image variation: 0–255.", "NectarX", "Icon!")
        return false
    }
    for name, edit in nectarEdits {
        try pct := Integer(edit.Value)
        catch {
            MsgBox("Nectar targets must be whole-number percentages.", "NectarX", "Icon!")
            return false
        }
        if pct < 0 || pct > 100 {
            MsgBox("Each nectar target must be between 0 and 100%.", "NectarX", "Icon!")
            return false
        }
    }
    if Trim(hotkeyStartBox.Value) = "" || Trim(hotkeyPauseBox.Value) = "" || Trim(hotkeyStopBox.Value) = "" {
        MsgBox("Hotkeys cannot be blank.", "NectarX", "Icon!")
        return false
    }
    cfg.field := gatherFieldBox.Text
    cfg.pattern := gatherPatternBox.Text
    cfg.patternSize := patternSizeBox.Text
    cfg.patternWidth := width
    cfg.repetitions := reps
    cfg.gatherMinutes := minutes
    cfg.backpackLimit := pack
    cfg.shiftLock := shiftLockBox.Value = 1
    cfg.driftCheck := driftCheckBox.Value = 1
    cfg.invertFB := invertFBBox.Value = 1
    cfg.invertLR := invertLRBox.Value = 1
    cfg.moveMethod := moveMethodBox.Text
    cfg.returnMethod := returnMethodBox.Text
    cfg.activeSprinkler := activeSprinklerBox.Text
    cfg.sprinklerPlacement := sprinklerPlacementBox.Text
    cfg.sprinklerOffsetX := offX
    cfg.sprinklerOffsetY := offY
    cfg.autoSprinkler := autoSprinklerBox.Value = 1
    cfg.harvestMode := harvestModeBox.Text
    cfg.harvestInterval := hours
    cfg.planterField1 := planterFieldBoxes[1].Text
    cfg.planterField2 := planterFieldBoxes[2].Text
    cfg.planterField3 := planterFieldBoxes[3].Text
    cfg.windowTitle := Trim(settingsWindowTitleBox.Value)
    cfg.variation := variation
    cfg.hotkeyStart := Trim(hotkeyStartBox.Value)
    cfg.hotkeyPause := Trim(hotkeyPauseBox.Value)
    cfg.hotkeyStop := Trim(hotkeyStopBox.Value)
    for i, name in ["Basic Sprinkler","Silver Soakers","Golden Gushers","Diamond Drenchers","Supreme Saturator"]
        cfg["OwnsSprinkler" i] := sprinklerChecks[name].Value = 1
    for i, name in ["Paper Planter","Plastic Planter","Ticket Planter","Candy Planter","Red Clay Planter","Blue Clay Planter","Tacky Planter","Pesticide Planter","Heat-Treated Planter","Hydroponic Planter","Petal Planter","Planter of Plenty","Festive Planter","Sticker Planter"]
        cfg["OwnsPlanter" i] := planterChecks[name].Value = 1
    for name, edit in nectarEdits
        cfg[StrReplace(name, " ", "") "Target"] := Integer(edit.Value)
    IniWrite(cfg.field, ConfigFile, "Gather", "Field")
    IniWrite(cfg.pattern, ConfigFile, "Gather", "Pattern")
    IniWrite(cfg.patternSize, ConfigFile, "Gather", "PatternSize")
    IniWrite(cfg.patternWidth, ConfigFile, "Gather", "PatternWidth")
    IniWrite(cfg.repetitions, ConfigFile, "Gather", "Repetitions")
    IniWrite(cfg.gatherMinutes, ConfigFile, "Gather", "Minutes")
    IniWrite(cfg.backpackLimit, ConfigFile, "Gather", "BackpackLimit")
    IniWrite(cfg.shiftLock ? 1 : 0, ConfigFile, "Gather", "ShiftLock")
    IniWrite(cfg.driftCheck ? 1 : 0, ConfigFile, "Gather", "DriftCheck")
    IniWrite(cfg.invertFB ? 1 : 0, ConfigFile, "Gather", "InvertFB")
    IniWrite(cfg.invertLR ? 1 : 0, ConfigFile, "Gather", "InvertLR")
    IniWrite(cfg.moveMethod, ConfigFile, "Gather", "MoveMethod")
    IniWrite(cfg.returnMethod, ConfigFile, "Gather", "ReturnMethod")
    IniWrite(cfg.activeSprinkler, ConfigFile, "Sprinklers", "Active")
    IniWrite(cfg.sprinklerPlacement, ConfigFile, "Sprinklers", "Placement")
    IniWrite(cfg.sprinklerOffsetX, ConfigFile, "Sprinklers", "OffsetX")
    IniWrite(cfg.sprinklerOffsetY, ConfigFile, "Sprinklers", "OffsetY")
    IniWrite(cfg.autoSprinkler ? 1 : 0, ConfigFile, "Sprinklers", "AutoPlace")
    for i, name in ["Basic Sprinkler","Silver Soakers","Golden Gushers","Diamond Drenchers","Supreme Saturator"]
        IniWrite(cfg["OwnsSprinkler" i] ? 1 : 0, ConfigFile, "Sprinklers", "Owns" i)
    IniWrite(cfg.harvestMode, ConfigFile, "Planters", "HarvestMode")
    IniWrite(cfg.harvestInterval, ConfigFile, "Planters", "HarvestInterval")
    IniWrite(cfg.planterField1, ConfigFile, "Planters", "Field1")
    IniWrite(cfg.planterField2, ConfigFile, "Planters", "Field2")
    IniWrite(cfg.planterField3, ConfigFile, "Planters", "Field3")
    for i, name in ["Paper Planter","Plastic Planter","Ticket Planter","Candy Planter","Red Clay Planter","Blue Clay Planter","Tacky Planter","Pesticide Planter","Heat-Treated Planter","Hydroponic Planter","Petal Planter","Planter of Plenty","Festive Planter","Sticker Planter"]
        IniWrite(cfg["OwnsPlanter" i] ? 1 : 0, ConfigFile, "Planters", "Owns" i)
    for name in ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
        IniWrite(cfg[StrReplace(name, " ", "") "Target"], ConfigFile, "Nectar", StrReplace(name, " ", "") "Target")
    IniWrite(cfg.windowTitle, ConfigFile, "ScreenReader", "WindowTitle")
    IniWrite(cfg.variation, ConfigFile, "ScreenReader", "Variation")
    IniWrite(cfg.hotkeyStart, ConfigFile, "Hotkeys", "Start")
    IniWrite(cfg.hotkeyPause, ConfigFile, "Hotkeys", "Pause")
    IniWrite(cfg.hotkeyStop, ConfigFile, "Hotkeys", "Stop")
    IniWrite(cfg.repetitions, ConfigFile, "General", "Repetitions")
    IniWrite(cfg.patternWidth, ConfigFile, "General", "MovementScale")
    IniWrite(cfg.windowTitle, ConfigFile, "General", "WindowTitle")
    IniWrite(cfg.variation, ConfigFile, "General", "Variation")
    SaveSprinklerFieldSettings(false)
    UpdateDashboard()
    return true
}

SaveProfile(*) {
    global ConfigFile, profileNameBox
    if !SaveSettingsCore()
        return
    name := RegExReplace(Trim(profileNameBox.Value), "[^\w -]", "")
    if name = "" {
        MsgBox("Enter a profile name using letters, numbers, spaces or hyphens.", "NectarX", "Icon!")
        return
    }
    section := "Profile_" name
    keys := [["Gather","Field"],["Gather","Pattern"],["Gather","PatternSize"],["Gather","PatternWidth"],["Gather","Repetitions"],["Gather","Minutes"],["Gather","BackpackLimit"],["Gather","ShiftLock"],["Gather","DriftCheck"],["Gather","InvertFB"],["Gather","InvertLR"],["Gather","MoveMethod"],["Gather","ReturnMethod"],["Sprinklers","Active"],["Sprinklers","Placement"],["Sprinklers","OffsetX"],["Sprinklers","OffsetY"],["Sprinklers","AutoPlace"],["Planters","HarvestMode"],["Planters","HarvestInterval"],["Planters","Field1"],["Planters","Field2"],["Planters","Field3"],["ScreenReader","WindowTitle"],["ScreenReader","Variation"],["Hotkeys","Start"],["Hotkeys","Pause"],["Hotkeys","Stop"],["General","Repetitions"],["General","MovementScale"],["General","WindowTitle"],["General","Variation"]]
    Loop 5
        keys.Push(["Sprinklers", "Owns" A_Index])
    Loop 14
        keys.Push(["Planters", "Owns" A_Index])
    for nm in ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
        keys.Push(["Nectar", nm "Target"])
    for pair in keys
        IniWrite(IniRead(ConfigFile, pair[1], pair[2], ""), ConfigFile, section, pair[1] "_" pair[2])
    Log("Profile saved: " name)
    MsgBox("Profile '" name "' saved.", "NectarX", "Iconi")
}

LoadProfile(*) {
    global ConfigFile, profileNameBox, cfg
    name := RegExReplace(Trim(profileNameBox.Value), "[^\w -]", "")
    if name = "" {
        MsgBox("Enter a profile name first.", "NectarX", "Icon!")
        return
    }
    section := "Profile_" name
    if IniRead(ConfigFile, section, "Gather_Field", "__MISSING__") = "__MISSING__" {
        MsgBox("Profile not found: " name, "NectarX", "Icon!")
        return
    }
    keys := [["Gather","Field"],["Gather","Pattern"],["Gather","PatternSize"],["Gather","PatternWidth"],["Gather","Repetitions"],["Gather","Minutes"],["Gather","BackpackLimit"],["Gather","ShiftLock"],["Gather","DriftCheck"],["Gather","InvertFB"],["Gather","InvertLR"],["Gather","MoveMethod"],["Gather","ReturnMethod"],["Sprinklers","Active"],["Sprinklers","Placement"],["Sprinklers","OffsetX"],["Sprinklers","OffsetY"],["Sprinklers","AutoPlace"],["Planters","HarvestMode"],["Planters","HarvestInterval"],["Planters","Field1"],["Planters","Field2"],["Planters","Field3"],["ScreenReader","WindowTitle"],["ScreenReader","Variation"],["Hotkeys","Start"],["Hotkeys","Pause"],["Hotkeys","Stop"],["General","Repetitions"],["General","MovementScale"],["General","WindowTitle"],["General","Variation"]]
    Loop 5
        keys.Push(["Sprinklers", "Owns" A_Index])
    Loop 14
        keys.Push(["Planters", "Owns" A_Index])
    for nm in ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
        keys.Push(["Nectar", nm "Target"])
    for pair in keys {
        val := IniRead(ConfigFile, section, pair[1] "_" pair[2], "")
        if val != ""
            IniWrite(val, ConfigFile, pair[1], pair[2])
    }
    cfg := LoadSettings()
    ApplySettingsToControls()
    RefreshPatterns()
    ApplyHotkeys()
    Log("Profile loaded: " name)
    MsgBox("Profile '" name "' loaded.", "NectarX", "Iconi")
}

StartMacro(*) {
    global sessionState, sessionElapsedMs, sessionSegmentStart, statusLabel, statusDetail
    global dashState, dashActivity, pauseBtn
    if !SaveSettingsCore()
        return
    if sessionState = "PREVIEW" {
        MsgBox("A preview session is already running.", "NectarX", "Iconi")
        return
    }
    if sessionState = "PAUSED" {
        sessionState := "PREVIEW"
        sessionSegmentStart := A_TickCount
        SetTimer(UpdateDashboard, 1000)
        statusLabel.Text := "● PREVIEW  |  NO GAME INPUT"
        dashState.Text := "PREVIEW — timer running"
        dashActivity.Text := "Configuration preview only"
        statusDetail.Text := "No movement is sent to Roblox; runner is not connected."
        pauseBtn.Text := "Pause"
        Log("Preview session resumed.")
        return
    }
    sessionElapsedMs := 0
    sessionSegmentStart := A_TickCount
    sessionState := "PREVIEW"
    statusLabel.Text := "● PREVIEW  |  NO GAME INPUT"
    dashState.Text := "PREVIEW — timer running"
    dashActivity.Text := "Configuration preview only"
    statusDetail.Text := "Preview timer active. No movement is sent to Roblox."
    pauseBtn.Text := "Pause"
    SetTimer(UpdateDashboard, 1000)
    Log("Preview session started. Farming runner remains disabled.")
}

PauseResume(*) {
    global sessionState, sessionElapsedMs, sessionSegmentStart, statusLabel, statusDetail
    global dashState, dashActivity, pauseBtn
    if sessionState = "PREVIEW" {
        sessionElapsedMs += A_TickCount - sessionSegmentStart
        sessionState := "PAUSED"
        SetTimer(UpdateDashboard, 0)
        statusLabel.Text := "● PAUSED  |  PREVIEW"
        statusDetail.Text := "Timer paused. No game inputs have been sent."
        dashState.Text := "PAUSED — timer stopped"
        dashActivity.Text := "Preview paused"
        pauseBtn.Text := "Resume"
        Log("Preview session paused.")
    } else if sessionState = "PAUSED" {
        sessionState := "PREVIEW"
        sessionSegmentStart := A_TickCount
        SetTimer(UpdateDashboard, 1000)
        statusLabel.Text := "● PREVIEW  |  NO GAME INPUT"
        statusDetail.Text := "Preview timer active. No movement is sent to Roblox."
        dashState.Text := "PREVIEW — timer running"
        dashActivity.Text := "Configuration preview only"
        pauseBtn.Text := "Pause"
        Log("Preview session resumed.")
    } else {
        MsgBox("No active preview to pause. Start / Preview runs the UI timer only; game automation is not connected yet.", "NectarX", "Iconi")
    }
}

StopMacro(*) {
    global sessionState, sessionElapsedMs, sessionSegmentStart, statusLabel, statusDetail
    global dashState, dashActivity, pauseBtn
    if sessionState = "PREVIEW"
        sessionElapsedMs += A_TickCount - sessionSegmentStart
    sessionState := "IDLE"
    SetTimer(UpdateDashboard, 0)
    Send "{w up}{a up}{s up}{d up}{Shift up}{Space up}"
    statusLabel.Text := "● IDLE  |  RUNNER NOT CONNECTED"
    statusDetail.Text := "Stopped. NectarX has not sent farming movement inputs."
    dashState.Text := "IDLE — ready to configure"
    dashActivity.Text := "Activity: none"
    pauseBtn.Text := "Pause"
    UpdateDashboard()
    Log("Stop pressed; preview stopped and common movement keys released.")
}

UpdateDashboard(*) {
    global cfg, sessionState, sessionElapsedMs, sessionSegmentStart, dashSession, dashField
    global dashPattern, dashLimit, dashBackpack, dashTelemetry, dashPlanterSummary, dashSprinklerStatus
    global nectarStatusRows, dashState, dashboardLog
    elapsed := sessionElapsedMs
    if sessionState = "PREVIEW"
        elapsed += A_TickCount - sessionSegmentStart
    secs := Floor(elapsed / 1000)
    dashSession.Text := Format("{:02}:{:02}:{:02}", Floor(secs/3600), Mod(Floor(secs/60),60), Mod(secs,60))
    dashField.Text := "Field: " cfg.field
    dashPattern.Text := "Pattern: " (cfg.pattern = "" ? "not selected" : cfg.pattern)
    dashLimit.Text := "Time " cfg.gatherMinutes " min  |  Pack " cfg.backpackLimit "%"
    dashBackpack.Text := "Backpack: unavailable (reader pending)"
    dashTelemetry.Text := "Runner / game telemetry not connected"
    dashPlanterSummary.Text := "Owned planters: " CountOwnedPlanters() "  |  Harvest interval: " cfg.harvestInterval " h"
    dashSprinklerStatus.Text := "Selected sprinkler: " cfg.activeSprinkler
    for row in nectarStatusRows {
        row.target.Text := "Target: " cfg[StrReplace(row.name, " ", "") "Target"] "%"
        row.actual.Text := "Actual: unavailable"
    }
    if sessionState = "IDLE"
        dashState.Text := "IDLE — ready to configure"
    else if sessionState = "PAUSED"
        dashState.Text := "PAUSED — timer stopped"
    try dashboardLog.Value := ReadLog()
}

CountOwnedPlanters() {
    global planterChecks
    count := 0
    for name, cb in planterChecks
        if cb.Value = 1
            count += 1
    return count
}

RefreshPatterns(*) {
    global PatternDir, PathDir, patternFilesList, pathFilesList, gatherPatternBox, gatherConfigStatus, cfg
    p := []
    q := []
    if DirExist(PatternDir)
        Loop Files, PatternDir "\*.ahk", "F"
            p.Push(A_LoopFileName)
    if DirExist(PathDir)
        Loop Files, PathDir "\*.ahk", "F"
            q.Push(A_LoopFileName)
    patternFilesList.Delete()
    patternFilesList.Add(p.Length ? p : ["No pattern files found"])
    patternFilesList.Choose(1)
    pathFilesList.Delete()
    pathFilesList.Add(q.Length ? q : ["No path files found"])
    pathFilesList.Choose(1)
    gatherPatternBox.Delete()
    if p.Length {
        names := []
        for item in p
            names.Push(RegExReplace(item, "\.ahk$", ""))
        gatherPatternBox.Add(names)
        exists := false
        for item in names
            if item = cfg.pattern
                exists := true
        gatherPatternBox.Choose(exists ? ArrayIndexOf(names, cfg.pattern) : 1)
    } else {
        gatherPatternBox.Add(["No patterns found"])
        gatherPatternBox.Choose(1)
    }
    gatherConfigStatus.Value := "Patterns found: " p.Length Chr(13) Chr(10) "Paths found: " q.Length Chr(13) Chr(10) Chr(13) Chr(10) "Scripts are catalogued only. They may depend on shared variables/movement helpers and are not executed by this build."
    Log("Refreshed pattern/path lists (" p.Length " patterns, " q.Length " paths).")
}

ArrayIndexOf(arr, value) {
    for i, item in arr
        if item = value
            return i
    return 1
}

OpenSelectedPattern(*) {
    global PatternDir, patternFilesList
    path := PatternDir "\" patternFilesList.Text
    if !FileExist(path) {
        MsgBox("Select an existing pattern file first.", "NectarX", "Icon!")
        return
    }
    Run('notepad.exe "' path '"')
}

OpenSelectedPath(*) {
    global PathDir, pathFilesList
    path := PathDir "\" pathFilesList.Text
    if !FileExist(path) {
        MsgBox("Select an existing path file first.", "NectarX", "Icon!")
        return
    }
    Run('notepad.exe "' path '"')
}

RefreshImages(*) {
    global ImageDir, imageList
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

DetectRobloxButton(*) {
    global imageResult
    if DetectRoblox()
        imageResult.Value := "Roblox window detected." Chr(13) Chr(10) "Client bounds: " GetClientBoundsText()
    else
        imageResult.Value := "Roblox window not found. Open Roblox or adjust the title fallback in Settings."
}

DetectRoblox() {
    global RobloxHwnd, statusDetail, windowTitleBox
    RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !RobloxHwnd && IsSet(windowTitleBox) && Trim(windowTitleBox.Value) != ""
        RobloxHwnd := WinExist(Trim(windowTitleBox.Value))
    if RobloxHwnd {
        try title := WinGetTitle("ahk_id " RobloxHwnd)
        catch
            title := "Roblox"
        statusDetail.Text := "Window detected: " title " | image matching can be tested."
        return true
    }
    statusDetail.Text := "Roblox window not detected. UI preview still works."
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
        imageResult.Value := "No image templates found." Chr(13) Chr(10) "Add an original cropped PNG/BMP to:" Chr(13) Chr(10) ImageDir
        return
    }
    if !DetectRoblox() {
        imageResult.Value := "Roblox window not found. Open the Roblox client before testing image matching."
        return
    }
    path := ImageDir "\" imageList.Text
    if !FileExist(path) {
        imageResult.Value := "Template file missing: " path
        RefreshImages()
        return
    }
    try variation := Integer(variationBox.Value)
    catch {
        imageResult.Value := "Variation must be between 0 and 255."
        return
    }
    if variation < 0 || variation > 255 {
        imageResult.Value := "Variation must be between 0 and 255."
        return
    }
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_id " RobloxHwnd)
        if ImageSearch(&fx, &fy, x, y, x+w-1, y+h-1, "*" variation " " path) {
            imageResult.Value := "MATCH FOUND: " imageList.Text Chr(13) Chr(10) "Screen position: " fx ", " fy
            Log("Image matched: " imageList.Text " at " fx "," fy)
        } else {
            imageResult.Value := "No match found for: " imageList.Text Chr(13) Chr(10) "Try a tighter crop or adjust variation."
            Log("Image not found: " imageList.Text)
        }
    } catch as err {
        imageResult.Value := "Image test failed: " err.Message
        Log("Image test error: " err.Message)
    }
}

LoadSprinklerFieldSettings(*) {
    global ConfigFile, sprinklerFieldBox, sprinklerPlacementBox, sprinklerOffsetXBox, sprinklerOffsetYBox
    field := sprinklerFieldBox.Text
    sprinklerPlacementBox.ChooseString(IniRead(ConfigFile, "SprinklerFields", field "_Placement", "Center"))
    sprinklerOffsetXBox.Value := IniRead(ConfigFile, "SprinklerFields", field "_OffsetX", "0")
    sprinklerOffsetYBox.Value := IniRead(ConfigFile, "SprinklerFields", field "_OffsetY", "0")
}

SaveSprinklerFieldSettings(showMessage := true) {
    global ConfigFile, sprinklerFieldBox, sprinklerPlacementBox, sprinklerOffsetXBox, sprinklerOffsetYBox, sprinklerStatusBox
    field := sprinklerFieldBox.Text
    try {
        offX := Integer(sprinklerOffsetXBox.Value)
        offY := Integer(sprinklerOffsetYBox.Value)
    } catch {
        MsgBox("Sprinkler offsets must be whole numbers.", "NectarX", "Icon!")
        return false
    }
    IniWrite(sprinklerPlacementBox.Text, ConfigFile, "SprinklerFields", field "_Placement")
    IniWrite(offX, ConfigFile, "SprinklerFields", field "_OffsetX")
    IniWrite(offY, ConfigFile, "SprinklerFields", field "_OffsetY")
    sprinklerStatusBox.Value := "Saved placement for " field ": " sprinklerPlacementBox.Text " (offset " offX ", " offY ")." Chr(13) Chr(10) "Live placement status requires a game-action runner."
    if showMessage
        MsgBox("Sprinkler settings saved for " field ".", "NectarX", "Iconi")
    Log("Sprinkler placement saved for " field ".")
    return true
}

ApplyHotkeys(*) {
    if BindHotkeysFromControls(true)
        MsgBox("Hotkeys applied. They control the NectarX preview UI only.", "NectarX", "Iconi")
}

BindHotkeysFromControls(showErrors := false) {
    global hotkeyStartBox, hotkeyPauseBox, hotkeyStopBox, activeHotkeys
    keys := [Trim(hotkeyStartBox.Value), Trim(hotkeyPauseBox.Value), Trim(hotkeyStopBox.Value)]
    if keys[1] = "" || keys[2] = "" || keys[3] = "" || keys[1] = keys[2] || keys[1] = keys[3] || keys[2] = keys[3] {
        if showErrors
            MsgBox("Choose three different non-empty hotkeys.", "NectarX", "Icon!")
        return false
    }
    try {
        for key in activeHotkeys
            Hotkey(key, "Off")
        Hotkey(keys[1], StartMacro, "On")
        Hotkey(keys[2], PauseResume, "On")
        Hotkey(keys[3], StopMacro, "On")
        activeHotkeys := keys
        Log("Hotkeys applied: " keys[1] " / " keys[2] " / " keys[3])
        return true
    } catch as err {
        if showErrors
            MsgBox("Could not apply hotkeys. Check the key names." Chr(13) Chr(10) err.Message, "NectarX", "Icon!")
        return false
    }
}

ReadLog() {
    global LogFile
    return FileExist(LogFile) ? FileRead(LogFile, "UTF-8") : "No log entries yet."
}

Log(message) {
    global LogFile, logBox, dashboardLog
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " message Chr(13) Chr(10), LogFile, "UTF-8")
    try logBox.Value := ReadLog()
    try dashboardLog.Value := ReadLog()
}

RefreshLog(*) {
    global logBox
    logBox.Value := ReadLog()
}

ClearLog(*) {
    global LogFile, logBox, dashboardLog
    if MsgBox("Clear the NectarX log file?", "NectarX", "YesNo Icon?") != "Yes"
        return
    if FileExist(LogFile)
        FileDelete(LogFile)
    logBox.Value := "Log cleared."
    dashboardLog.Value := "Log cleared."
    Log("Log cleared by user.")
}

GuiResize(guiObj, minMax, width, height) {
    global tabs, statusLabel, statusDetail, startBtn, pauseBtn, stopBtn, saveBtn, openFolderBtn
    if minMax = -1
        return
    tabs.Move(, , width - 36, height - 150)
    statusLabel.Move(width - 410, 22, 370, 24)
    statusDetail.Move(width - 610, 49, 570, 20)
    startBtn.Move(20, height - 56)
    pauseBtn.Move(202, height - 56)
    stopBtn.Move(364, height - 56)
    saveBtn.Move(536, height - 56)
    openFolderBtn.Move(728, height - 56)
}

OnClose(*) {
    StopMacro()
    ExitApp()
}
