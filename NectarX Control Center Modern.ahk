#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NectarX Modern Control Center
; Original blue/black UI inspired by common modern macro UX patterns.
; This is still a configuration + UI-preview build. Game movement, live game
; telemetry, automatic planter harvests and sprinkler placement are not connected.
global ConfigFile := A_ScriptDir "\NectarX.ini"
global LogFile := A_ScriptDir "\NectarX.log"
global ImageDir := A_ScriptDir "\NectarX images"
global PatternDir := A_ScriptDir "\NectarX patterns"
global PathDir := A_ScriptDir "\NectarX paths"
global RobloxHwnd := 0
global SessionState := "IDLE"
global SessionElapsed := 0
global SessionStartTick := 0
global ActiveHotkeys := []
global Fields := ["Sunflower","Dandelion","Mushroom","Blue Flower","Clover","Spider","Strawberry","Bamboo","Pine Tree","Stump","Cactus","Pumpkin","Pineapple","Rose","Mountain Top","Pepper","Coconut"]
global NectarNames := ["Comforting","Satisfying","Refreshing","Invigorating","Motivating"]
global SprinklerNames := ["Basic Sprinkler","Silver Soakers","Golden Gushers","Diamond Drenchers","Supreme Saturator"]
global PlanterNames := ["Paper Planter","Plastic Planter","Ticket Planter","Candy Planter","Red Clay Planter","Blue Clay Planter","Tacky Planter","Pesticide Planter","Heat-Treated Planter","Hydroponic Planter","Petal Planter","Planter of Plenty","Festive Planter","Sticker Planter"]
global UiEdits := []
global UiLists := []
global UiChecks := []
global UiButtons := []
global PlanterChecks := Map()
global SprinklerChecks := Map()
global NectarEdits := Map()
global NectarTargetLabels := []
global PlanterFieldBoxes := []
global Cfg := LoadSettings()

CoordMode "Pixel", "Screen"
DirCreate(ImageDir)
DirCreate(PatternDir)
DirCreate(PathDir)

; Main shell
main := Gui("+Resize +MinSize1000x700", "NectarX | Control Center")
main.BackColor := "0B1020"
main.SetFont("s10 cEAF1FF", "Segoe UI")
main.OnEvent("Close", OnClose)
main.OnEvent("Size", GuiResize)

main.AddText("x22 y13 w300 h36 c58B9FF", "NECTARX")
brandText := main["NECTARX"]
; brand is styled using a second large text control to keep the logo crisp.
brandText := main.AddText("x22 y12 w300 h36 c58B9FF", "NECTARX")
brandText.SetFont("s23 bold", "Segoe UI")
main.AddText("x24 y48 w520 h19 c91A8C9", "BEE SWARM SIMULATOR  /  MACRO CONTROL CENTER")
statusPill := main.AddText("x735 y20 w360 h24 Right c66D9FF", "● READY TO CONFIGURE")
statusPill.SetFont("s10 bold", "Segoe UI")
statusDetail := main.AddText("x575 y48 w520 h18 Right c91A8C9", "Runner offline · no game inputs are being sent")

tabs := main.AddTab3("x18 y78 w1124 h622", ["Dashboard","Gather","Sprinklers","Planters & Nectar","Patterns","Status","Screen Reader","Settings"])
try tabs.Opt("Background0B1020")

; DASHBOARD
tabs.UseTab(1)
Card("x36 y115 w338 h124", "SESSION")
dashTimer := main.AddText("x56 y146 w295 h38 c58B9FF", "00:00:00")
dashTimer.SetFont("s24 bold", "Segoe UI")
dashState := main.AddText("x56 y190 w295 h22 cFFC766", "IDLE  ·  ready to configure")
main.AddText("x56 y215 w295 h16 c7187AB", "Preview timer only; farming runner offline")

Card("x394 y115 w338 h124", "GATHER PROFILE")
dashField := main.AddText("x414 y148 w294 h22", "Field: " Cfg.field)
dashPattern := main.AddText("x414 y177 w294 h22", "Pattern: " Cfg.pattern)
dashGatherLimits := main.AddText("x414 y207 w294 h18 c91A8C9", Cfg.gatherMinutes " min  /  " Cfg.backpackLimit "% backpack")

Card("x752 y115 w370 h124", "LIVE GAME TELEMETRY")
dashBackpack := main.AddText("x772 y148 w330 h22 cFFC766", "Backpack  — unavailable")
dashNectar := main.AddText("x772 y177 w330 h22", "Nectar  — awaiting screen reader")
dashPlanters := main.AddText("x772 y207 w330 h18 c91A8C9", "Planters  — no live readings")

Card("x36 y257 w520 h190", "NECTAR TARGETS")
for i, nectarName in NectarNames {
    y := 288 + (i - 1) * 28
    main.AddText("x56 y" y " w172 h22", nectarName)
    target := main.AddText("x230 y" y " w120 h22 c58B9FF", "Target " Cfg[StrReplace(nectarName, " ", "") "Target"] "%")
    actual := main.AddText("x365 y" y " w165 h22 c7187AB", "Actual  —")
    NectarTargetLabels.Push({target:target, actual:actual, name:nectarName})
}
Card("x574 y257 w548 h190", "PLANTER / SPRINKLER OVERVIEW")
dashPlanterOwned := main.AddText("x594 y289 w505 h24", "Owned planters: " CountOwnedPlanters())
dashPlanterTimer := main.AddText("x594 y320 w505 h24", "Harvest interval: " Cfg.harvestInterval " hours")
dashSprinkler := main.AddText("x594 y351 w505 h24", "Selected sprinkler: " Cfg.activeSprinkler)
main.AddText("x594 y384 w505 h45 c7187AB", "Actual growth, nectar levels and placement success will show here once the game reader and runner are integrated.")
Card("x36 y465 w1086 h190", "RECENT ACTIVITY")
dashLog := EditBox("x56 y494 w1046 h132 +ReadOnly -Wrap", ReadLog())
main.AddText("x56 y633 w1040 h17 c7187AB", "Blue status markers are application status, not proof of in-game activity.")

; GATHER
tabs.UseTab(2)
Card("x36 y115 w530 h262", "FIELD + PATTERN")
main.AddText("x56 y149 w195 h20 c91A8C9", "Field")
gatherField := DropBox("x56 y173 w220 Choose1", Fields)
main.AddText("x300 y149 w215 h20 c91A8C9", "Pattern")
gatherPattern := DropBox("x300 y173 w230 Choose1", ["Scanning patterns..."])
main.AddText("x56 y215 w195 h20 c91A8C9", "Pattern size")
patternSize := DropBox("x56 y239 w125 Choose3", ["XS","S","M","L","XL"])
main.AddText("x202 y215 w95 h20 c91A8C9", "Width")
patternWidth := EditBox("x202 y239 w90 h28 Number", Cfg.patternWidth)
main.AddText("x312 y215 w105 h20 c91A8C9", "Repetitions")
gatherReps := EditBox("x312 y239 w92 h28 Number", Cfg.repetitions)
main.AddText("x423 y215 w110 h20 c91A8C9", "Rotate camera")
rotateCamera := DropBox("x423 y239 w105 Choose1", ["Off","90°","180°","270°"])
main.AddText("x56 y286 w195 h20 c91A8C9", "Gather limit (minutes)")
gatherMinutes := EditBox("x56 y310 w125 h28 Number", Cfg.gatherMinutes)
main.AddText("x202 y286 w195 h20 c91A8C9", "Backpack threshold (%)")
backpackLimit := EditBox("x202 y310 w125 h28 Number", Cfg.backpackLimit)
shiftLock := CheckBox("x350 y312 w178 h24", "Gather with Shift Lock")
shiftLock.Value := Cfg.shiftLock ? 1 : 0
Card("x586 y115 w536 h262", "MOVEMENT + HIVE RETURN")
main.AddText("x606 y149 w210 h20 c91A8C9", "Movement method")
moveMethod := DropBox("x606 y173 w220 Choose1", ["Walk","Cannon","Walk + cannon when available"])
main.AddText("x850 y149 w230 h20 c91A8C9", "Return to hive")
returnMethod := DropBox("x850 y173 w240 Choose1", ["Walk","Reset","Cannon then walk","Configured path"])
driftComp := CheckBox("x606 y220 w215 h24", "Drift compensation")
invertForward := CheckBox("x606 y251 w215 h24", "Invert forward / back")
invertLeftRight := CheckBox("x850 y220 w230 h24", "Invert left / right")
driftComp.Value := Cfg.driftComp ? 1 : 0
invertForward.Value := Cfg.invertForward ? 1 : 0
invertLeftRight.Value := Cfg.invertLeftRight ? 1 : 0
main.AddText("x606 y291 w480 h58 c7187AB", "Both timer and backpack limit should eventually trigger a controlled return. These preferences are saved now; the in-game movement runner is not connected.")
Card("x36 y395 w1086 h260", "CONFIGURATION CHECK")
gatherCheck := EditBox("x56 y424 w1046 h178 +ReadOnly -Wrap", "Pattern files have not been scanned yet.")
refreshGather := ButtonBox("x56 y614 w165 h30", "Refresh patterns")
refreshGather.OnEvent("Click", RefreshPatterns)
main.AddText("x238 y620 w845 h20 c7187AB", "Fields and scripts are selectable; this build does not execute farming routines.")

; SPRINKLERS
tabs.UseTab(3)
Card("x36 y115 w475 h290", "SPRINKLER INVENTORY")
main.AddText("x56 y148 w430 h20 c91A8C9", "Check the sprinkler types you actually own.")
for i, sprinklerName in SprinklerNames {
    colX := i <= 3 ? 56 : 276
    row := i <= 3 ? i : i - 3
    cb := CheckBox("x" colX " y" (181 + (row - 1) * 48) " w210 h28", sprinklerName)
    cb.Value := Cfg["OwnsSprinkler" i] ? 1 : 0
    SprinklerChecks[sprinklerName] := cb
}
Card("x531 y115 w591 h290", "PLACEMENT PROFILE")
main.AddText("x551 y148 w205 h20 c91A8C9", "Active sprinkler")
activeSprinkler := DropBox("x551 y173 w230 Choose1", SprinklerNames)
main.AddText("x806 y148 w265 h20 c91A8C9", "Field to configure")
sprinklerField := DropBox("x806 y173 w280 Choose1", Fields)
sprinklerField.OnEvent("Change", LoadSprinklerField)
main.AddText("x551 y220 w205 h20 c91A8C9", "Placement preset")
sprinklerPlacement := DropBox("x551 y245 w230 Choose1", ["Center","Near entrance","North edge","East edge","South edge","West edge","Custom offsets"])
main.AddText("x806 y220 w95 h20 c91A8C9", "Offset X")
sprinklerOffsetX := EditBox("x806 y245 w90 h28 Number", Cfg.sprinklerOffsetX)
main.AddText("x918 y220 w95 h20 c91A8C9", "Offset Y")
sprinklerOffsetY := EditBox("x918 y245 w90 h28 Number", Cfg.sprinklerOffsetY)
autoSprinkler := CheckBox("x551 y293 w255 h24", "Auto-place on field entry")
autoSprinkler.Value := Cfg.autoSprinkler ? 1 : 0
Card("x36 y423 w1086 h232", "PLACEMENT STATUS")
sprinklerResult := EditBox("x56 y453 w1046 h142 +ReadOnly -Wrap", "No placement attempted. Select a field, choose a placement preset and save the setup.")
saveSprinkler := ButtonBox("x56 y607 w185 h30", "Save field placement")
saveSprinkler.OnEvent("Click", SaveSprinklerField)
main.AddText("x260 y614 w820 h20 c7187AB", "Field positions are stored independently. Successful in-game placement needs the movement runner and visual confirmation.")

; PLANTERS + NECTAR
tabs.UseTab(4)
Card("x36 y115 w470 h365", "PLANTERS YOU OWN")
main.AddText("x56 y148 w420 h20 c91A8C9", "Select your inventory. Unchecked planters are not available.")
for i, planterName in PlanterNames {
    colX := i <= 7 ? 56 : 273
    row := i <= 7 ? i : i - 7
    cb := CheckBox("x" colX " y" (179 + (row - 1) * 35) " w215 h25", planterName)
    cb.Value := Cfg["OwnsPlanter" i] ? 1 : 0
    PlanterChecks[planterName] := cb
}
Card("x526 y115 w596 h214", "NECTAR PRIORITIES")
main.AddText("x546 y148 w260 h20 c91A8C9", "Target % (0 disables a target)")
for i, nectarName in NectarNames {
    y := 178 + (i - 1) * 28
    main.AddText("x548 y" y " w190 h21", nectarName)
    NectarEdits[nectarName] := EditBox("x753 y" y " w80 h24 Number", Cfg[StrReplace(nectarName, " ", "") "Target"])
    main.AddText("x850 y" y " w245 h21 c7187AB", "Current level: unavailable")
}
Card("x526 y347 w596 h133", "HARVEST RULE")
main.AddText("x546 y378 w190 h20 c91A8C9", "Harvest when")
harvestMode := DropBox("x546 y402 w220 Choose1", ["Time interval","When mature","Manual only"])
main.AddText("x790 y378 w185 h20 c91A8C9", "Interval (hours)")
harvestInterval := EditBox("x790 y402 w105 h28 Number", Cfg.harvestInterval)
main.AddText("x546 y443 w540 h25 c7187AB", "Actual nectar and planter maturity need reliable screen recognition.")
Card("x36 y497 w1086 h158", "PLANTER SCHEDULE  /  ASSIGNMENTS")
main.AddText("x56 y527 w160 h20 c91A8C9", "Planter slot")
main.AddText("x226 y527 w180 h20 c91A8C9", "Field")
main.AddText("x432 y527 w150 h20 c91A8C9", "Harvest")
main.AddText("x612 y527 w440 h20 c91A8C9", "24-hour schedule overview")
planterFieldBoxes.Push(DropBox("x56 y551 w160 Choose1", ["Slot 1"] PlanterNames))
planterFieldBoxes.Push(DropBox("x226 y551 w180 Choose1", ["None"] Fields))
planterFieldBoxes.Push(DropBox("x432 y551 w150 Choose1", ["Interval","Mature","Manual"]))
main.AddText("x612 y553 w445 h24 c58B9FF", "00h ━━━ 06h ━━━ 12h ━━━ 18h ━━━ 24h")
planterFieldBoxes[1].ChooseString("Slot 1")
planterFieldBoxes[2].ChooseString(Cfg.planterField1)
planterFieldBoxes[3].ChooseString(Cfg.planterRule1)

; PATTERNS
tabs.UseTab(5)
Card("x36 y115 w520 h520", "GATHERING PATTERNS")
patternList := ListBox("x56 y148 w480 h385", [])
refreshPatternsBtn := ButtonBox("x56 y546 w155 h32", "Refresh lists")
refreshPatternsBtn.OnEvent("Click", RefreshPatterns)
openPatternBtn := ButtonBox("x227 y546 w155 h32", "Open selected")
openPatternBtn.OnEvent("Click", OpenSelectedPattern)
main.AddText("x56 y589 w475 h27 c7187AB", "Reads .ahk files from NectarX patterns/. Scripts are catalogued, not executed.")
Card("x576 y115 w546 h520", "FIELD PATHS")
pathList := ListBox("x596 y148 w506 h385", [])
openPathBtn := ButtonBox("x596 y546 w180 h32", "Open selected path")
openPathBtn.OnEvent("Click", OpenSelectedPath)
main.AddText("x596 y589 w500 h27 c7187AB", "Reads .ahk files from NectarX paths/.")
main.AddText("x56 y615 w1030 h18 cFFC766", "RUNNER OFFLINE  ·  Patterns and paths must be integrated with tested movement helpers before use.")

; STATUS
tabs.UseTab(6)
Card("x36 y115 w340 h125", "SESSION")
statusTimer := main.AddText("x56 y148 w300 h35 c58B9FF", "00:00:00")
statusTimer.SetFont("s23 bold", "Segoe UI")
statusState := main.AddText("x56 y194 w300 h23 cFFC766", "IDLE")
Card("x394 y115 w340 h125", "GATHERING STATE")
statusCurrentField := main.AddText("x414 y148 w300 h22", "Field: " Cfg.field)
statusCurrentPattern := main.AddText("x414 y177 w300 h22", "Pattern: " Cfg.pattern)
statusCurrentLimits := main.AddText("x414 y207 w300 h18 c91A8C9", "Time " Cfg.gatherMinutes " min | " Cfg.backpackLimit "% bag")
Card("x752 y115 w370 h125", "RECOGNITION")
statusWindow := main.AddText("x772 y148 w330 h22 c91A8C9", "Roblox window: not checked")
statusImage := main.AddText("x772 y177 w330 h22 c91A8C9", "Image templates: not scanned")
statusRunner := main.AddText("x772 y207 w330 h18 cFFC766", "Movement runner: offline")
Card("x36 y257 w1086 h398", "ACTIVITY LOG")
logBox := EditBox("x56 y286 w1046 h315 +ReadOnly -Wrap", ReadLog())
refreshLogBtn := ButtonBox("x56 y612 w145 h30", "Refresh log")
refreshLogBtn.OnEvent("Click", RefreshLog)
clearLogBtn := ButtonBox("x218 y612 w145 h30", "Clear log")
clearLogBtn.OnEvent("Click", ClearLog)
main.AddText("x390 y619 w700 h17 c7187AB", "Logged: config changes, preview control actions, and screen-reader test results.")

; SCREEN READER
tabs.UseTab(7)
Card("x36 y115 w1086 h210", "IMAGE TEMPLATE TESTER")
main.AddText("x56 y148 w190 h20 c91A8C9", "Template")
imageList := DropBox("x56 y173 w360 Choose1", ["No templates found"])
refreshImagesBtn := ButtonBox("x432 y172 w150 h30", "Refresh images")
refreshImagesBtn.OnEvent("Click", RefreshImages)
testImageBtn := ButtonBox("x596 y172 w190 h30", "Test selected image")
testImageBtn.OnEvent("Click", TestSelectedImage)
detectWindowBtn := ButtonBox("x800 y172 w285 h30", "Detect Roblox window")
detectWindowBtn.OnEvent("Click", DetectRobloxButton)
main.AddText("x56 y220 w185 h20 c91A8C9", "Image variation (0–255)")
variationBox := EditBox("x56 y245 w100 h28 Number", Cfg.variation)
windowTitleBox := EditBox("x183 y245 w260 h28", Cfg.windowTitle)
main.AddText("x458 y249 w600 h20 c7187AB", "Window-title fallback")
Card("x36 y345 w1086 h310", "RECOGNITION RESULT")
imageResult := EditBox("x56 y374 w1046 h218 +ReadOnly -Wrap", "No image test run yet.")
main.AddText("x56 y607 w1040 h23 c7187AB", "Add your own tightly cropped PNG/BMP templates to NectarX images/. Live backpack/nectar detection is not implemented.")

; SETTINGS
tabs.UseTab(8)
Card("x36 y115 w520 h230", "GENERAL")
main.AddText("x56 y148 w210 h20 c91A8C9", "Roblox window title")
settingsWindowTitle := EditBox("x56 y172 w275 h28", Cfg.windowTitle)
main.AddText("x56 y218 w210 h20 c91A8C9", "Default repetitions")
settingsReps := EditBox("x56 y242 w100 h28 Number", Cfg.repetitions)
main.AddText("x183 y218 w210 h20 c91A8C9", "Default pattern width")
settingsWidth := EditBox("x183 y242 w100 h28 Number", Cfg.patternWidth)
main.AddText("x56 y292 w465 h22 c7187AB", "Settings are saved locally to NectarX.ini.")
Card("x576 y115 w546 h230", "HOTKEYS")
main.AddText("x596 y148 w130 h20 c91A8C9", "Start / Preview")
hotkeyStart := EditBox("x730 y144 w95 h28", Cfg.hotkeyStart)
main.AddText("x840 y148 w65 h20 c91A8C9", "Pause")
hotkeyPause := EditBox("x908 y144 w95 h28", Cfg.hotkeyPause)
main.AddText("x596 y196 w130 h20 c91A8C9", "Stop")
hotkeyStop := EditBox("x730 y192 w95 h28", Cfg.hotkeyStop)
applyHotkeysBtn := ButtonBox("x840 y191 w164 h30", "Apply hotkeys")
applyHotkeysBtn.OnEvent("Click", ApplyHotkeys)
main.AddText("x596 y242 w485 h65 c7187AB", "Defaults: F6 starts a UI preview, F7 pauses/resumes, F8 stops the preview. These do not control Roblox movement.")
Card("x36 y365 w1086 h270", "PROFILES")
main.AddText("x56 y398 w160 h20 c91A8C9", "Profile name")
profileName := EditBox("x56 y422 w285 h28", "Default")
saveProfileBtn := ButtonBox("x365 y421 w150 h30", "Save profile")
saveProfileBtn.OnEvent("Click", SaveProfile)
loadProfileBtn := ButtonBox("x532 y421 w150 h30", "Load profile")
loadProfileBtn.OnEvent("Click", LoadProfile)
main.AddText("x56 y471 w1030 h62 c7187AB", "Named profiles store field/pattern choices, movement preferences, backpack/time limits, sprinkler and planter ownership, nectar target percentages, harvest schedule and hotkeys.")
main.AddText("x56 y574 w1030 h22 c58B9FF", "NECTARX  /  ORIGINAL BLUE THEME  /  SAFE CONFIGURATION PREVIEW")

tabs.UseTab()

; Persistent bottom action strip
main.AddText("x18 y710 w1124 h54 Background111A2B", "")
startBtn := ButtonBox("x32 y720 w160 h34", "▶  Start / Preview")
startBtn.OnEvent("Click", StartPreview)
pauseBtn := ButtonBox("x205 y720 w145 h34", "Ⅱ  Pause")
pauseBtn.OnEvent("Click", PauseResume)
stopBtn := ButtonBox("x363 y720 w130 h34", "■  Stop")
stopBtn.OnEvent("Click", StopSession)
saveBtn := ButtonBox("x506 y720 w160 h34", "Save settings")
saveBtn.OnEvent("Click", SaveSettings)
openFolderBtn := ButtonBox("x679 y720 w185 h34", "Open project folder")
openFolderBtn.OnEvent("Click", (*) => Run('explorer.exe "' A_ScriptDir '"'))
footerStatus := main.AddText("x882 y725 w235 h23 Right c58B9FF", "● RUNNER OFFLINE")

ApplySettingsToControls()
RefreshPatterns()
RefreshImages()
LoadSprinklerField()
UpdateDashboard()
BindHotkeys(false)
Log("Modern NectarX Control Center loaded. Game-action runner remains offline.")
SetTimer(UpdateDashboard, 1000)
main.Show("w1160 h790")

; ---------- Shared visual constructors ----------
Card(options, caption) {
    global main
    c := main.AddGroupBox(options " c58B9FF", "  " caption "  ")
    return c
}
EditBox(options, value := "") {
    global main, UiEdits
    c := main.AddEdit(options, value)
    try c.Opt("Background111A2B cEAF1FF")
    c.SetFont("s10", "Segoe UI")
    UiEdits.Push(c)
    return c
}
DropBox(options, items) {
    global main, UiLists
    c := main.AddDropDownList(options, items)
    try c.Opt("Background111A2B cEAF1FF")
    c.SetFont("s10", "Segoe UI")
    UiLists.Push(c)
    return c
}
ListBox(options, items) {
    global main, UiLists
    c := main.AddListBox(options, items)
    try c.Opt("Background111A2B cEAF1FF")
    c.SetFont("s10", "Segoe UI")
    UiLists.Push(c)
    return c
}
CheckBox(options, label) {
    global main, UiChecks
    c := main.AddCheckBox(options " cEAF1FF", label)
    try c.Opt("Background0B1020 cEAF1FF")
    c.SetFont("s10", "Segoe UI")
    UiChecks.Push(c)
    return c
}
ButtonBox(options, label) {
    global main, UiButtons
    c := main.AddButton(options, label)
    try c.Opt("Background193A64 cFFFFFF")
    c.SetFont("s10 bold", "Segoe UI")
    UiButtons.Push(c)
    return c
}

LoadSettings() {
    global ConfigFile, SprinklerNames, PlanterNames, NectarNames
    s := {}
    s.field := IniRead(ConfigFile, "Gather", "Field", "Pine Tree")
    s.pattern := IniRead(ConfigFile, "Gather", "Pattern", "")
    s.patternSize := IniRead(ConfigFile, "Gather", "PatternSize", "M")
    s.patternWidth := IniRead(ConfigFile, "Gather", "PatternWidth", "10")
    s.repetitions := IniRead(ConfigFile, "Gather", "Repetitions", "3")
    s.gatherMinutes := IniRead(ConfigFile, "Gather", "Minutes", "25")
    s.backpackLimit := IniRead(ConfigFile, "Gather", "BackpackLimit", "95")
    s.shiftLock := IniRead(ConfigFile, "Gather", "ShiftLock", "1") = "1"
    s.driftComp := IniRead(ConfigFile, "Gather", "DriftComp", "1") = "1"
    s.invertForward := IniRead(ConfigFile, "Gather", "InvertForward", "0") = "1"
    s.invertLeftRight := IniRead(ConfigFile, "Gather", "InvertLeftRight", "0") = "1"
    s.moveMethod := IniRead(ConfigFile, "Gather", "MoveMethod", "Walk")
    s.returnMethod := IniRead(ConfigFile, "Gather", "ReturnMethod", "Walk")
    s.rotateCamera := IniRead(ConfigFile, "Gather", "RotateCamera", "Off")
    s.activeSprinkler := IniRead(ConfigFile, "Sprinklers", "Active", "Basic Sprinkler")
    s.sprinklerPlacement := IniRead(ConfigFile, "Sprinklers", "Placement", "Center")
    s.sprinklerOffsetX := IniRead(ConfigFile, "Sprinklers", "OffsetX", "0")
    s.sprinklerOffsetY := IniRead(ConfigFile, "Sprinklers", "OffsetY", "0")
    s.autoSprinkler := IniRead(ConfigFile, "Sprinklers", "AutoPlace", "0") = "1"
    for i, name in SprinklerNames
        s["OwnsSprinkler" i] := IniRead(ConfigFile, "Sprinklers", "Owns" i, i = 1 ? "1" : "0") = "1"
    s.harvestMode := IniRead(ConfigFile, "Planters", "HarvestMode", "Time interval")
    s.harvestInterval := IniRead(ConfigFile, "Planters", "HarvestInterval", "2")
    s.planterField1 := IniRead(ConfigFile, "Planters", "Field1", "Pine Tree")
    s.planterField2 := IniRead(ConfigFile, "Planters", "Field2", "Strawberry")
    s.planterField3 := IniRead(ConfigFile, "Planters", "Field3", "None")
    s.planterRule1 := IniRead(ConfigFile, "Planters", "Rule1", "Interval")
    for i, name in PlanterNames
        s["OwnsPlanter" i] := IniRead(ConfigFile, "Planters", "Owns" i, "0") = "1"
    for i, name in NectarNames
        s[StrReplace(name, " ", "") "Target"] := IniRead(ConfigFile, "Nectar", StrReplace(name, " ", "") "Target", "50")
    s.windowTitle := IniRead(ConfigFile, "ScreenReader", "WindowTitle", "Roblox")
    s.variation := IniRead(ConfigFile, "ScreenReader", "Variation", "35")
    s.hotkeyStart := IniRead(ConfigFile, "Hotkeys", "Start", "F6")
    s.hotkeyPause := IniRead(ConfigFile, "Hotkeys", "Pause", "F7")
    s.hotkeyStop := IniRead(ConfigFile, "Hotkeys", "Stop", "F8")
    return s
}

ApplySettingsToControls() {
    global Cfg, gatherField, gatherPattern, patternSize, patternWidth, gatherReps, gatherMinutes
    global backpackLimit, shiftLock, moveMethod, returnMethod, driftComp, invertForward, invertLeftRight
    global rotateCamera, activeSprinkler, sprinklerField, sprinklerPlacement, sprinklerOffsetX, sprinklerOffsetY
    global autoSprinkler, SprinklerChecks, PlanterChecks, NectarEdits, harvestMode, harvestInterval
    global planterFieldBoxes, settingsWindowTitle, settingsReps, settingsWidth, windowTitleBox, variationBox
    global hotkeyStart, hotkeyPause, hotkeyStop, fields, SprinklerNames, PlanterNames, NectarNames
    gatherField.ChooseString(Cfg.field)
    patternSize.ChooseString(Cfg.patternSize)
    patternWidth.Value := Cfg.patternWidth
    gatherReps.Value := Cfg.repetitions
    gatherMinutes.Value := Cfg.gatherMinutes
    backpackLimit.Value := Cfg.backpackLimit
    shiftLock.Value := Cfg.shiftLock ? 1 : 0
    moveMethod.ChooseString(Cfg.moveMethod)
    returnMethod.ChooseString(Cfg.returnMethod)
    driftComp.Value := Cfg.driftComp ? 1 : 0
    invertForward.Value := Cfg.invertForward ? 1 : 0
    invertLeftRight.Value := Cfg.invertLeftRight ? 1 : 0
    rotateCamera.ChooseString(Cfg.rotateCamera)
    activeSprinkler.ChooseString(Cfg.activeSprinkler)
    sprinklerField.ChooseString(Cfg.field)
    sprinklerPlacement.ChooseString(Cfg.sprinklerPlacement)
    sprinklerOffsetX.Value := Cfg.sprinklerOffsetX
    sprinklerOffsetY.Value := Cfg.sprinklerOffsetY
    autoSprinkler.Value := Cfg.autoSprinkler ? 1 : 0
    for i, name in SprinklerNames
        SprinklerChecks[name].Value := Cfg["OwnsSprinkler" i] ? 1 : 0
    for i, name in PlanterNames
        PlanterChecks[name].Value := Cfg["OwnsPlanter" i] ? 1 : 0
    for name in NectarNames
        NectarEdits[name].Value := Cfg[StrReplace(name, " ", "") "Target"]
    harvestMode.ChooseString(Cfg.harvestMode)
    harvestInterval.Value := Cfg.harvestInterval
    planterFieldBoxes[2].ChooseString(Cfg.planterField1)
    planterFieldBoxes[3].ChooseString(Cfg.planterRule1)
    settingsWindowTitle.Value := Cfg.windowTitle
    windowTitleBox.Value := Cfg.windowTitle
    settingsReps.Value := Cfg.repetitions
    settingsWidth.Value := Cfg.patternWidth
    variationBox.Value := Cfg.variation
    hotkeyStart.Value := Cfg.hotkeyStart
    hotkeyPause.Value := Cfg.hotkeyPause
    hotkeyStop.Value := Cfg.hotkeyStop
    UpdateDashboard()
}

SaveSettings(*) {
    if SaveSettingsCore() {
        Log("Settings saved.")
        MsgBox("Settings saved to NectarX.ini.", "NectarX", "Iconi")
    }
}

SaveSettingsCore() {
    global Cfg, ConfigFile, gatherField, gatherPattern, patternSize, patternWidth, gatherReps
    global gatherMinutes, backpackLimit, shiftLock, moveMethod, returnMethod, driftComp
    global invertForward, invertLeftRight, rotateCamera, activeSprinkler, sprinklerField, sprinklerPlacement
    global sprinklerOffsetX, sprinklerOffsetY, autoSprinkler, SprinklerChecks, PlanterChecks, NectarEdits
    global harvestMode, harvestInterval, planterFieldBoxes, settingsWindowTitle, settingsReps, settingsWidth
    global windowTitleBox, variationBox, hotkeyStart, hotkeyPause, hotkeyStop, SprinklerNames, PlanterNames, NectarNames
    try {
        mins := Integer(gatherMinutes.Value)
        pack := Integer(backpackLimit.Value)
        width := Integer(patternWidth.Value)
        reps := Integer(gatherReps.Value)
        hours := Number(harvestInterval.Value)
        xOff := Integer(sprinklerOffsetX.Value)
        yOff := Integer(sprinklerOffsetY.Value)
        variation := Integer(variationBox.Value)
        defaultReps := Integer(settingsReps.Value)
        defaultWidth := Integer(settingsWidth.Value)
    } catch {
        MsgBox("One or more numeric fields contain invalid values.", "NectarX", "Icon!")
        return false
    }
    if mins < 1 || mins > 720 || pack < 10 || pack > 100 || width < 1 || width > 100 || reps < 1 || reps > 100 || hours <= 0 || hours > 168 || variation < 0 || variation > 255 || defaultReps < 1 || defaultReps > 100 || defaultWidth < 1 || defaultWidth > 100 {
        MsgBox("Check numeric ranges: minutes 1-720, backpack 10-100%, width/repetitions 1-100, harvest hours >0-168, variation 0-255.", "NectarX", "Icon!")
        return false
    }
    for name, edit in NectarEdits {
        try pct := Integer(edit.Value)
        catch {
            MsgBox("Nectar target percentages must be whole numbers.", "NectarX", "Icon!")
            return false
        }
        if pct < 0 || pct > 100 {
            MsgBox("Nectar targets must be between 0 and 100%.", "NectarX", "Icon!")
            return false
        }
    }
    if Trim(hotkeyStart.Value) = "" || Trim(hotkeyPause.Value) = "" || Trim(hotkeyStop.Value) = "" {
        MsgBox("Hotkeys cannot be blank.", "NectarX", "Icon!")
        return false
    }
    Cfg.field := gatherField.Text
    Cfg.pattern := gatherPattern.Text = "No patterns found" ? "" : gatherPattern.Text
    Cfg.patternSize := patternSize.Text
    Cfg.patternWidth := width
    Cfg.repetitions := reps
    Cfg.gatherMinutes := mins
    Cfg.backpackLimit := pack
    Cfg.shiftLock := shiftLock.Value = 1
    Cfg.moveMethod := moveMethod.Text
    Cfg.returnMethod := returnMethod.Text
    Cfg.driftComp := driftComp.Value = 1
    Cfg.invertForward := invertForward.Value = 1
    Cfg.invertLeftRight := invertLeftRight.Value = 1
    Cfg.rotateCamera := rotateCamera.Text
    Cfg.activeSprinkler := activeSprinkler.Text
    Cfg.sprinklerPlacement := sprinklerPlacement.Text
    Cfg.sprinklerOffsetX := xOff
    Cfg.sprinklerOffsetY := yOff
    Cfg.autoSprinkler := autoSprinkler.Value = 1
    Cfg.harvestMode := harvestMode.Text
    Cfg.harvestInterval := hours
    Cfg.planterField1 := planterFieldBoxes[2].Text
    Cfg.planterRule1 := planterFieldBoxes[3].Text
    Cfg.windowTitle := Trim(settingsWindowTitle.Value)
    Cfg.variation := variation
    Cfg.hotkeyStart := Trim(hotkeyStart.Value)
    Cfg.hotkeyPause := Trim(hotkeyPause.Value)
    Cfg.hotkeyStop := Trim(hotkeyStop.Value)
    for i, name in SprinklerNames
        Cfg["OwnsSprinkler" i] := SprinklerChecks[name].Value = 1
    for i, name in PlanterNames
        Cfg["OwnsPlanter" i] := PlanterChecks[name].Value = 1
    for name, edit in NectarEdits
        Cfg[StrReplace(name, " ", "") "Target"] := Integer(edit.Value)

    IniWrite(Cfg.field, ConfigFile, "Gather", "Field")
    IniWrite(Cfg.pattern, ConfigFile, "Gather", "Pattern")
    IniWrite(Cfg.patternSize, ConfigFile, "Gather", "PatternSize")
    IniWrite(Cfg.patternWidth, ConfigFile, "Gather", "PatternWidth")
    IniWrite(Cfg.repetitions, ConfigFile, "Gather", "Repetitions")
    IniWrite(Cfg.gatherMinutes, ConfigFile, "Gather", "Minutes")
    IniWrite(Cfg.backpackLimit, ConfigFile, "Gather", "BackpackLimit")
    IniWrite(Cfg.shiftLock ? 1 : 0, ConfigFile, "Gather", "ShiftLock")
    IniWrite(Cfg.moveMethod, ConfigFile, "Gather", "MoveMethod")
    IniWrite(Cfg.returnMethod, ConfigFile, "Gather", "ReturnMethod")
    IniWrite(Cfg.driftComp ? 1 : 0, ConfigFile, "Gather", "DriftComp")
    IniWrite(Cfg.invertForward ? 1 : 0, ConfigFile, "Gather", "InvertForward")
    IniWrite(Cfg.invertLeftRight ? 1 : 0, ConfigFile, "Gather", "InvertLeftRight")
    IniWrite(Cfg.rotateCamera, ConfigFile, "Gather", "RotateCamera")
    IniWrite(Cfg.activeSprinkler, ConfigFile, "Sprinklers", "Active")
    IniWrite(Cfg.sprinklerPlacement, ConfigFile, "Sprinklers", "Placement")
    IniWrite(Cfg.sprinklerOffsetX, ConfigFile, "Sprinklers", "OffsetX")
    IniWrite(Cfg.sprinklerOffsetY, ConfigFile, "Sprinklers", "OffsetY")
    IniWrite(Cfg.autoSprinkler ? 1 : 0, ConfigFile, "Sprinklers", "AutoPlace")
    for i, name in SprinklerNames
        IniWrite(Cfg["OwnsSprinkler" i] ? 1 : 0, ConfigFile, "Sprinklers", "Owns" i)
    IniWrite(Cfg.harvestMode, ConfigFile, "Planters", "HarvestMode")
    IniWrite(Cfg.harvestInterval, ConfigFile, "Planters", "HarvestInterval")
    IniWrite(Cfg.planterField1, ConfigFile, "Planters", "Field1")
    IniWrite(Cfg.planterField2, ConfigFile, "Planters", "Field2")
    IniWrite(Cfg.planterField3, ConfigFile, "Planters", "Field3")
    IniWrite(Cfg.planterRule1, ConfigFile, "Planters", "Rule1")
    for i, name in PlanterNames
        IniWrite(Cfg["OwnsPlanter" i] ? 1 : 0, ConfigFile, "Planters", "Owns" i)
    for name in NectarNames
        IniWrite(Cfg[StrReplace(name, " ", "") "Target"], ConfigFile, "Nectar", StrReplace(name, " ", "") "Target")
    IniWrite(Cfg.windowTitle, ConfigFile, "ScreenReader", "WindowTitle")
    IniWrite(Cfg.variation, ConfigFile, "ScreenReader", "Variation")
    IniWrite(Cfg.hotkeyStart, ConfigFile, "Hotkeys", "Start")
    IniWrite(Cfg.hotkeyPause, ConfigFile, "Hotkeys", "Pause")
    IniWrite(Cfg.hotkeyStop, ConfigFile, "Hotkeys", "Stop")
    SaveSprinklerField(false)
    UpdateDashboard()
    return true
}

SaveProfile(*) {
    global ConfigFile, profileName, Cfg
    if !SaveSettingsCore()
        return
    name := RegExReplace(Trim(profileName.Value), "[^\w -]", "")
    if name = "" {
        MsgBox("Enter a profile name.", "NectarX", "Icon!")
        return
    }
    sec := "Profile_" name
    for pair in ProfileKeyPairs()
        IniWrite(IniRead(ConfigFile, pair[1], pair[2], ""), ConfigFile, sec, pair[1] "_" pair[2])
    Log("Profile saved: " name)
    MsgBox("Profile saved: " name, "NectarX", "Iconi")
}

LoadProfile(*) {
    global ConfigFile, profileName, Cfg
    name := RegExReplace(Trim(profileName.Value), "[^\w -]", "")
    if name = "" {
        MsgBox("Enter a profile name.", "NectarX", "Icon!")
        return
    }
    sec := "Profile_" name
    if IniRead(ConfigFile, sec, "Gather_Field", "__MISSING__") = "__MISSING__" {
        MsgBox("Profile not found: " name, "NectarX", "Icon!")
        return
    }
    for pair in ProfileKeyPairs() {
        value := IniRead(ConfigFile, sec, pair[1] "_" pair[2], "")
        if value != ""
            IniWrite(value, ConfigFile, pair[1], pair[2])
    }
    Cfg := LoadSettings()
    ApplySettingsToControls()
    RefreshPatterns()
    BindHotkeys(false)
    Log("Profile loaded: " name)
    MsgBox("Profile loaded: " name, "NectarX", "Iconi")
}

ProfileKeyPairs() {
    global SprinklerNames, PlanterNames, NectarNames
    keys := []
    for k in ["Field","Pattern","PatternSize","PatternWidth","Repetitions","Minutes","BackpackLimit","ShiftLock","MoveMethod","ReturnMethod","DriftComp","InvertForward","InvertLeftRight","RotateCamera"]
        keys.Push(["Gather", k])
    for k in ["Active","Placement","OffsetX","OffsetY","AutoPlace"]
        keys.Push(["Sprinklers", k])
    for k in ["HarvestMode","HarvestInterval","Field1","Field2","Field3","Rule1"]
        keys.Push(["Planters", k])
    for k in ["WindowTitle","Variation"]
        keys.Push(["ScreenReader", k])
    for k in ["Start","Pause","Stop"]
        keys.Push(["Hotkeys", k])
    for i, name in SprinklerNames
        keys.Push(["Sprinklers", "Owns" i])
    for i, name in PlanterNames
        keys.Push(["Planters", "Owns" i])
    for name in NectarNames
        keys.Push(["Nectar", StrReplace(name, " ", "") "Target"])
    return keys
}

StartPreview(*) {
    global SessionState, SessionElapsed, SessionStartTick, statusPill, statusDetail, dashState, statusState, pauseBtn
    if !SaveSettingsCore()
        return
    if SessionState = "PREVIEW" {
        MsgBox("Preview is already running.", "NectarX", "Iconi")
        return
    }
    if SessionState = "PAUSED" {
        SessionState := "PREVIEW"
        SessionStartTick := A_TickCount
        statusPill.Text := "● PREVIEW  ·  UI TIMER ONLY"
        statusDetail.Text := "Preview resumed · runner offline"
        pauseBtn.Text := "Ⅱ  Pause"
        Log("Preview resumed.")
        SetTimer(UpdateDashboard, 1000)
        return
    }
    SessionElapsed := 0
    SessionStartTick := A_TickCount
    SessionState := "PREVIEW"
    statusPill.Text := "● PREVIEW  ·  UI TIMER ONLY"
    statusDetail.Text := "Preview started · no movement is sent to Roblox"
    dashState.Text := "PREVIEW  ·  timer running"
    statusState.Text := "PREVIEW"
    pauseBtn.Text := "Ⅱ  Pause"
    Log("UI preview started. In-game farming is not connected.")
    SetTimer(UpdateDashboard, 1000)
}

PauseResume(*) {
    global SessionState, SessionElapsed, SessionStartTick, statusPill, statusDetail, dashState, statusState, pauseBtn
    if SessionState = "PREVIEW" {
        SessionElapsed += A_TickCount - SessionStartTick
        SessionState := "PAUSED"
        SetTimer(UpdateDashboard, 0)
        statusPill.Text := "● PAUSED"
        statusDetail.Text := "Preview timer paused · runner offline"
        dashState.Text := "PAUSED  ·  timer stopped"
        statusState.Text := "PAUSED"
        pauseBtn.Text := "▶  Resume"
        Log("Preview paused.")
    } else if SessionState = "PAUSED" {
        SessionState := "PREVIEW"
        SessionStartTick := A_TickCount
        SetTimer(UpdateDashboard, 1000)
        statusPill.Text := "● PREVIEW  ·  UI TIMER ONLY"
        statusDetail.Text := "Preview resumed · no game movement"
        dashState.Text := "PREVIEW  ·  timer running"
        statusState.Text := "PREVIEW"
        pauseBtn.Text := "Ⅱ  Pause"
        Log("Preview resumed.")
    } else {
        MsgBox("Nothing is running. Start / Preview runs the GUI timer only until the farming runner is integrated.", "NectarX", "Iconi")
    }
}

StopSession(*) {
    global SessionState, SessionElapsed, SessionStartTick, statusPill, statusDetail, dashState, statusState, pauseBtn
    if SessionState = "PREVIEW"
        SessionElapsed += A_TickCount - SessionStartTick
    SessionState := "IDLE"
    SetTimer(UpdateDashboard, 0)
    Send "{w up}{a up}{s up}{d up}{Shift up}{Space up}"
    statusPill.Text := "● IDLE  ·  RUNNER OFFLINE"
    statusDetail.Text := "Stopped · NectarX is not sending farming movement"
    dashState.Text := "IDLE  ·  ready to configure"
    statusState.Text := "IDLE"
    pauseBtn.Text := "Ⅱ  Pause"
    UpdateDashboard()
    Log("Stopped preview and released common movement keys.")
}

UpdateDashboard(*) {
    global Cfg, SessionState, SessionElapsed, SessionStartTick, dashTimer, statusTimer
    global dashField, dashPattern, dashGatherLimits, dashBackpack, dashNectar, dashPlanters
    global dashPlanterOwned, dashPlanterTimer, dashSprinkler, statusCurrentField, statusCurrentPattern
    global statusCurrentLimits, statusWindow, statusImage, statusRunner, NectarTargetLabels, dashLog, logBox
    elapsed := SessionElapsed
    if SessionState = "PREVIEW"
        elapsed += A_TickCount - SessionStartTick
    secs := Floor(elapsed / 1000)
    label := Format("{:02}:{:02}:{:02}", Floor(secs / 3600), Mod(Floor(secs / 60), 60), Mod(secs, 60))
    dashTimer.Text := label
    statusTimer.Text := label
    dashField.Text := "Field: " Cfg.field
    dashPattern.Text := "Pattern: " (Cfg.pattern = "" ? "not selected" : Cfg.pattern)
    dashGatherLimits.Text := Cfg.gatherMinutes " min  /  " Cfg.backpackLimit "% backpack"
    dashBackpack.Text := "Backpack  — unavailable"
    dashNectar.Text := "Nectar  — actual levels unavailable"
    dashPlanters.Text := "Planters  — timer reader pending"
    dashPlanterOwned.Text := "Owned planters: " CountOwnedPlanters()
    dashPlanterTimer.Text := "Harvest interval: " Cfg.harvestInterval " hours"
    dashSprinkler.Text := "Selected sprinkler: " Cfg.activeSprinkler
    statusCurrentField.Text := "Field: " Cfg.field
    statusCurrentPattern.Text := "Pattern: " (Cfg.pattern = "" ? "not selected" : Cfg.pattern)
    statusCurrentLimits.Text := "Time " Cfg.gatherMinutes " min | " Cfg.backpackLimit "% bag"
    statusRunner.Text := "Movement runner: offline"
    statusImage.Text := "Image templates: " CountImages() " found"
    for row in NectarTargetLabels {
        row.target.Text := "Target " Cfg[StrReplace(row.name, " ", "") "Target"] "%"
        row.actual.Text := "Actual  —"
    }
    if SessionState = "PREVIEW" {
        dashState.Text := "PREVIEW  ·  timer running"
        statusState.Text := "PREVIEW"
        footerStatus.Text := "● PREVIEW ONLY"
    } else if SessionState = "PAUSED" {
        dashState.Text := "PAUSED  ·  timer stopped"
        statusState.Text := "PAUSED"
        footerStatus.Text := "● PAUSED"
    } else {
        dashState.Text := "IDLE  ·  ready to configure"
        statusState.Text := "IDLE"
        footerStatus.Text := "● RUNNER OFFLINE"
    }
    try dashLog.Value := ReadLog()
    try logBox.Value := ReadLog()
}

CountOwnedPlanters() {
    global PlanterChecks
    n := 0
    for name, cb in PlanterChecks
        if cb.Value = 1
            n += 1
    return n
}

CountImages() {
    global ImageDir
    n := 0
    if DirExist(ImageDir) {
        Loop Files, ImageDir "\*.png", "F"
            n += 1
        Loop Files, ImageDir "\*.bmp", "F"
            n += 1
    }
    return n
}

RefreshPatterns(*) {
    global PatternDir, PathDir, patternList, pathList, gatherPattern, gatherCheck
    global Cfg, statusImage
    patterns := []
    paths := []
    if DirExist(PatternDir)
        Loop Files, PatternDir "\*.ahk", "F"
            patterns.Push(A_LoopFileName)
    if DirExist(PathDir)
        Loop Files, PathDir "\*.ahk", "F"
            paths.Push(A_LoopFileName)
    patternList.Delete()
    patternList.Add(patterns.Length ? patterns : ["No pattern files found"])
    patternList.Choose(1)
    pathList.Delete()
    pathList.Add(paths.Length ? paths : ["No path files found"])
    pathList.Choose(1)
    gatherPattern.Delete()
    if patterns.Length {
        names := []
        for f in patterns
            names.Push(RegExReplace(f, "\.ahk$", ""))
        gatherPattern.Add(names)
        idx := 1
        for i, n in names
            if n = Cfg.pattern
                idx := i
        gatherPattern.Choose(idx)
    } else {
        gatherPattern.Add(["No patterns found"])
        gatherPattern.Choose(1)
    }
    gatherCheck.Value := "Patterns found: " patterns.Length Chr(13) Chr(10) "Paths found: " paths.Length Chr(13) Chr(10) Chr(13) Chr(10) "This page only lists scripts. Existing patterns may depend on shared variables/helpers and are not run by the current build."
    statusImage.Text := "Pattern files: " patterns.Length " · path files: " paths.Length
    Log("Refreshed patterns and paths.")
}

OpenSelectedPattern(*) {
    global PatternDir, patternList
    path := PatternDir "\" patternList.Text
    if !FileExist(path) {
        MsgBox("Select a valid pattern file.", "NectarX", "Icon!")
        return
    }
    Run('notepad.exe "' path '"')
}

OpenSelectedPath(*) {
    global PathDir, pathList
    path := PathDir "\" pathList.Text
    if !FileExist(path) {
        MsgBox("Select a valid path file.", "NectarX", "Icon!")
        return
    }
    Run('notepad.exe "' path '"')
}

RefreshImages(*) {
    global ImageDir, imageList, statusImage
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
    statusImage.Text := "Image templates: " items.Length " found"
    Log("Refreshed image templates (" items.Length ").")
}

DetectRobloxButton(*) {
    global imageResult, statusWindow
    if DetectRoblox() {
        imageResult.Value := "Roblox window detected." Chr(13) Chr(10) "Client bounds: " ClientBoundsText()
        statusWindow.Text := "Roblox window: detected"
    } else {
        imageResult.Value := "Roblox window not found. Open the Roblox client or change the title fallback."
        statusWindow.Text := "Roblox window: not found"
    }
}

DetectRoblox() {
    global RobloxHwnd, windowTitleBox, statusDetail
    RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !RobloxHwnd {
        try {
            title := Trim(windowTitleBox.Value)
            if title != ""
                RobloxHwnd := WinExist(title)
        }
    }
    if RobloxHwnd {
        try titleNow := WinGetTitle("ahk_id " RobloxHwnd)
        catch
            titleNow := "Roblox"
        statusDetail.Text := "Detected: " titleNow " · game reader is test-only"
        return true
    }
    statusDetail.Text := "Roblox not detected · settings can still be edited"
    return false
}

ClientBoundsText() {
    global RobloxHwnd
    if !RobloxHwnd
        return "unavailable"
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_id " RobloxHwnd)
        return x ", " y ", " w "x" h
    } catch {
        return "unable to read client area"
    }
}

TestSelectedImage(*) {
    global imageList, ImageDir, imageResult, RobloxHwnd, variationBox
    if imageList.Text = "" || imageList.Text = "No templates found" {
        imageResult.Value := "No templates found." Chr(13) Chr(10) "Add an original PNG/BMP crop to " ImageDir
        return
    }
    if !DetectRoblox() {
        imageResult.Value := "Roblox window not found. Start Roblox before testing image matching."
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
        imageResult.Value := "Variation must be a whole number from 0 to 255."
        return
    }
    if variation < 0 || variation > 255 {
        imageResult.Value := "Variation must be from 0 to 255."
        return
    }
    try {
        WinGetClientPos(&x, &y, &w, &h, "ahk_id " RobloxHwnd)
        if ImageSearch(&fx, &fy, x, y, x+w-1, y+h-1, "*" variation " " path) {
            imageResult.Value := "MATCH FOUND: " imageList.Text Chr(13) Chr(10) "Position: " fx ", " fy
            Log("Image matched: " imageList.Text " at " fx "," fy)
        } else {
            imageResult.Value := "No match found: " imageList.Text Chr(13) Chr(10) "Try a closer crop or another variation value."
            Log("Image not found: " imageList.Text)
        }
    } catch as err {
        imageResult.Value := "Image test failed: " err.Message
        Log("Image test error: " err.Message)
    }
}

LoadSprinklerField(*) {
    global ConfigFile, sprinklerField, sprinklerPlacement, sprinklerOffsetX, sprinklerOffsetY
    field := sprinklerField.Text
    sprinklerPlacement.ChooseString(IniRead(ConfigFile, "SprinklerFields", field "_Placement", "Center"))
    sprinklerOffsetX.Value := IniRead(ConfigFile, "SprinklerFields", field "_OffsetX", "0")
    sprinklerOffsetY.Value := IniRead(ConfigFile, "SprinklerFields", field "_OffsetY", "0")
}

SaveSprinklerField(showMessage := true) {
    global ConfigFile, sprinklerField, sprinklerPlacement, sprinklerOffsetX, sprinklerOffsetY, sprinklerResult
    field := sprinklerField.Text
    try {
        xOff := Integer(sprinklerOffsetX.Value)
        yOff := Integer(sprinklerOffsetY.Value)
    } catch {
        MsgBox("Sprinkler offsets must be whole numbers.", "NectarX", "Icon!")
        return false
    }
    IniWrite(sprinklerPlacement.Text, ConfigFile, "SprinklerFields", field "_Placement")
    IniWrite(xOff, ConfigFile, "SprinklerFields", field "_OffsetX")
    IniWrite(yOff, ConfigFile, "SprinklerFields", field "_OffsetY")
    sprinklerResult.Value := "Saved placement for " field ": " sprinklerPlacement.Text " (offset " xOff ", " yOff ")." Chr(13) Chr(10) "This is a saved preference, not confirmation of in-game placement."
    Log("Saved sprinkler placement profile for " field ".")
    if showMessage
        MsgBox("Placement preferences saved for " field ".", "NectarX", "Iconi")
    return true
}

ApplyHotkeys(*) {
    if BindHotkeys(true)
        MsgBox("Hotkeys applied. They operate the preview controls only.", "NectarX", "Iconi")
}

BindHotkeys(showError := false) {
    global hotkeyStart, hotkeyPause, hotkeyStop, ActiveHotkeys
    keys := [Trim(hotkeyStart.Value), Trim(hotkeyPause.Value), Trim(hotkeyStop.Value)]
    if keys[1] = "" || keys[2] = "" || keys[3] = "" || keys[1] = keys[2] || keys[1] = keys[3] || keys[2] = keys[3] {
        if showError
            MsgBox("Choose three different non-empty hotkeys.", "NectarX", "Icon!")
        return false
    }
    try {
        for key in ActiveHotkeys
            Hotkey(key, "Off")
        Hotkey(keys[1], StartPreview, "On")
        Hotkey(keys[2], PauseResume, "On")
        Hotkey(keys[3], StopSession, "On")
        ActiveHotkeys := keys
        return true
    } catch as err {
        if showError
            MsgBox("Unable to apply hotkeys. Check AutoHotkey key names." Chr(13) Chr(10) err.Message, "NectarX", "Icon!")
        return false
    }
}

ReadLog() {
    global LogFile
    return FileExist(LogFile) ? FileRead(LogFile, "UTF-8") : "No log entries yet."
}

Log(message) {
    global LogFile, logBox, dashLog
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " message Chr(13) Chr(10), LogFile, "UTF-8")
    try logBox.Value := ReadLog()
    try dashLog.Value := ReadLog()
}

RefreshLog(*) {
    global logBox
    logBox.Value := ReadLog()
}

ClearLog(*) {
    global LogFile, logBox, dashLog
    if MsgBox("Clear the NectarX log?", "NectarX", "YesNo Icon?") != "Yes"
        return
    if FileExist(LogFile)
        FileDelete(LogFile)
    logBox.Value := "Log cleared."
    dashLog.Value := "Log cleared."
    Log("Log cleared by user.")
}

GuiResize(guiObj, minMax, width, height) {
    global tabs, statusPill, statusDetail, startBtn, pauseBtn, stopBtn, saveBtn, openFolderBtn, footerStatus
    if minMax = -1
        return
    tabs.Move(, , width - 36, height - 168)
    statusPill.Move(width - 425, 20, 360, 24)
    statusDetail.Move(width - 585, 48, 520, 18)
    startBtn.Move(32, height - 70)
    pauseBtn.Move(205, height - 70)
    stopBtn.Move(363, height - 70)
    saveBtn.Move(506, height - 70)
    openFolderBtn.Move(679, height - 70)
    footerStatus.Move(width - 278, height - 65, 235, 23)
}

OnClose(*) {
    StopSession()
    ExitApp()
}
