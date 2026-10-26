#Requires AutoHotkey v2.0
#SingleInstance Force

global RootDir := A_ScriptDir
global ImageRoot := RootDir "\NectarX images"
global ManifestPath := ImageRoot "\image_manifest.json"
global TempPath := A_Temp "\nectarx_capture.png"
global Categories := ["fields_landmarks", "tokens_flowers", "backpack_pollen", "hive_conversion", "movement_travel", "npcs_quests", "bees_abilities", "planters", "menus_ui", "other"]
global CurrentImage := ""
global ActivityLog := "NectarX started."
global WebhookPath := RootDir "\nectarx_webhook.txt"
global WebhookUrl := ""
global HoneySession := 0
global SessionStartTick := A_TickCount
global HoneyHistory := []
global TokenLineImage := ""
global HasteImageFolder := ""
global VisionRunning := false
global LastVisionState := ""
global LastHasteStacks := -1
global AIGatherRunning := false
global AITokenFolder := ""
global AIHeldKeys := []
global AILeftHeld := false
global RouteScriptsFolder := ""

main := Gui("+Resize", "NectarX")
main.BackColor := "55585D"
main.SetFont("s10", "Segoe UI")
main.MarginX := 0, main.MarginY := 0
logo := main.AddText("x16 y12 w46 h46 Center 0x200 cF0F0F0", "⬡")
logo.SetFont("s28", "Segoe UI Symbol")
sidebar := main.AddText("x0 y66 w64 h470 Background:44474B", "")
toggleBtn := main.AddButton("x15 y74 w34 h30", "‹")
gatherTab := main.AddButton("x9 y119 w46 h44", "◈")
settingsTab := main.AddButton("x9 y173 w46 h44", "⚙")
imagesTab := main.AddButton("x9 y227 w46 h44", "▧")
statusTab := main.AddButton("x9 y281 w46 h44", "◷")
visionTab := main.AddButton("x9 y335 w46 h44", "◎")
routesTab := main.AddButton("x9 y389 w46 h44", "⌂")
gatherTab.ToolTip := "Gather", settingsTab.ToolTip := "Settings", imagesTab.ToolTip := "Images", statusTab.ToolTip := "Status", visionTab.ToolTip := "Screen reader", routesTab.ToolTip := "Hive & routes"

; Gather tab
gatherPage := main.AddGroupBox("x82 y72 w550 h450", "")
gatherTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "◈")
gatherTitle.SetFont("s16 Bold", "Segoe UI")
fieldLabel := main.AddText("x105 y137 w150 h24 cEEEEEE", "Field")
fieldBox := main.AddDropDownList("x270 y132 w320 Choose1", ["Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field", "Clover Field", "Spider Field", "Bamboo Field", "Strawberry Field", "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch", "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Pepper Patch", "Coconut Field"])
patternLabel := main.AddText("x105 y181 w150 h24 cEEEEEE", "Gather pattern")
patternBox := main.AddDropDownList("x270 y176 w320 Choose1", ["Normal", "Corner-to-corner", "Zigzag", "Spiral", "Circular"])
durationLabel := main.AddText("x105 y225 w150 h24 cEEEEEE", "Gather duration (min)")
durationBox := main.AddEdit("x270 y220 w120 Number", "10")
repeatLabel := main.AddText("x105 y269 w150 h24 cEEEEEE", "Pattern repeats")
repeatBox := main.AddEdit("x270 y264 w120 Number", "3")
startBtn := main.AddButton("x105 y330 w220 h46", "▶")
stopBtn := main.AddButton("x345 y330 w220 h46", "■")
gatherStatus := main.AddText("x105 y395 w470 h45 cEEEEEE", "Ready")
startBtn.ToolTip := "Start gathering", stopBtn.ToolTip := "Stop gathering"

; Settings tab
settingsPage := main.AddGroupBox("x82 y72 w550 h450", "")
settingsTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "⚙")
settingsTitle.SetFont("s16 Bold", "Segoe UI")
speedLabel := main.AddText("x105 y137 w155 h24 cEEEEEE", "Player move speed")
speedBox := main.AddEdit("x270 y132 w120", "1.0")
speedHint := main.AddText("x400 y136 w185 h24 cD0D0D0", "1.0 = default scale")
gameLabel := main.AddText("x105 y181 w155 h24 cEEEEEE", "Game")
gameBox := main.AddDropDownList("x270 y176 w320 Choose1", ["Roblox - Bee Swarm Simulator"])
detectLabel := main.AddText("x105 y225 w155 h24 cEEEEEE", "Game detection")
detectBox := main.AddDropDownList("x270 y220 w320 Choose1", ["Auto-detect Roblox", "Manual window selection"])
cameraLabel := main.AddText("x105 y269 w155 h24 cEEEEEE", "Camera style")
cameraBox := main.AddDropDownList("x270 y264 w320 Choose1", ["Default", "More zoomed out", "More zoomed in"])
scanRateLabel := main.AddText("x105 y310 w155 h24 cEEEEEE", "Screen reads / sec")
scanRateBox := main.AddDropDownList("x270 y305 w120 Choose2", ["1", "2", "3", "4", "5", "10"])
scanRateHint := main.AddText("x400 y309 w190 h24 cD0D0D0", "Higher = more CPU use")
saveSettingsBtn := main.AddButton("x105 y355 w220 h42", "✓")
resetSettingsBtn := main.AddButton("x345 y355 w220 h42", "↺")
settingsStatus := main.AddText("x105 y410 w470 h40 cEEEEEE", "")
saveSettingsBtn.ToolTip := "Save settings", resetSettingsBtn.ToolTip := "Reset settings"

; Screen reader tab: template matching is limited to the visible Roblox client window.
visionPage := main.AddGroupBox("x82 y72 w550 h450", "")
visionTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "◎  Vision & AI gathering")
visionTitle.SetFont("s16 Bold", "Segoe UI")
tokenImageLabel := main.AddText("x105 y133 w470 h22 cEEEEEE", "Token-line template image")
tokenImageBox := main.AddEdit("x105 y157 w365 h26 ReadOnly")
tokenImageBtn := main.AddButton("x480 y156 w95 h28", "Choose")
hasteFolderLabel := main.AddText("x105 y197 w470 h22 cEEEEEE", "Haste stack templates folder")
hasteFolderBox := main.AddEdit("x105 y221 w365 h26 ReadOnly")
hasteFolderBtn := main.AddButton("x480 y220 w95 h28", "Choose")
visionStartBtn := main.AddButton("x105 y260 w220 h34", "Start screen reader")
visionStopBtn := main.AddButton("x345 y260 w220 h34", "Stop reader")
visionStatus := main.AddText("x105 y296 w470 h24 cEEEEEE", "Reader stopped.")
visionRuleText := main.AddText("x105 y321 w470 h35 cD0D0D0", "Haste templates: haste_1.png to haste_10.png. Haste adjusts movement timing.")
aiGatherTitle := main.AddText("x105 y359 w470 h22 cFFFFFF", "AI Gathering — token templates")
aiGatherTitle.SetFont("s11 Bold", "Segoe UI")
aiTokenFolderLabel := main.AddText("x105 y383 w130 h22 cEEEEEE", "Token images folder")
aiTokenFolderBox := main.AddEdit("x235 y380 w235 h25 ReadOnly")
aiTokenFolderBtn := main.AddButton("x480 y379 w95 h27", "Choose")
aiGatherStartBtn := main.AddButton("x105 y412 w220 h34", "Start AI gathering")
aiGatherStopBtn := main.AddButton("x345 y412 w220 h34", "Stop AI")
aiGatherStatus := main.AddText("x105 y448 w470 h22 cEEEEEE", "Stopped. Choose token templates. Press F8 to stop safely.")

; Hive & Routes tab: launches user-supplied route scripts from a selected folder.
 routesPage := main.AddGroupBox("x82 y72 w550 h450", "")
 routesTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "⌂  Hive & Routes")
 routesTitle.SetFont("s16 Bold", "Segoe UI")
 routesFolderLabel := main.AddText("x105 y127 w470 h22 cEEEEEE", "Folder containing your route .ahk scripts")
 routesFolderBox := main.AddEdit("x105 y150 w365 h26 ReadOnly")
 routesFolderBtn := main.AddButton("x480 y149 w95 h28", "Choose")
 routesInfo := main.AddText("x105 y183 w470 h42 cD0D0D0", "Name scripts exactly as listed. These buttons launch scripts you create; NectarX does not guess map coordinates.")
 routeButtons := []
 routeSpecs := [["hive_slot_1.ahk", "Hive slot 1 — by red cannon ramp"], ["hive_slot_2.ahk", "Hive slot 2"], ["hive_slot_3.ahk", "Hive slot 3"], ["hive_slot_4.ahk", "Hive slot 4"], ["hive_slot_5.ahk", "Hive slot 5"], ["hive_slot_6.ahk", "Hive slot 6 — by Noob Shop"], ["field_to_hive.ahk", "Field → Hive"], ["hive_to_red_cannon.ahk", "Hive → Red Cannon"], ["hive_to_field.ahk", "Hive → Field"], ["custom_route.ahk", "Other / custom route"]]
 for i, spec in routeSpecs {
     col := i <= 5 ? 0 : 1
     row := Mod(i - 1, 5)
     x := col = 0 ? 105 : 350
     y := 235 + row * 42
     label := main.AddText("x" x " y" (y+5) " w165 h28 cEEEEEE", spec[2])
     btn := main.AddButton("x" (x+170) " y" y " w70 h30", "Run")
     btn.OnEvent("Click", RunRouteScript.Bind(spec[1]))
     routeButtons.Push(label), routeButtons.Push(btn)
 }
 routesStatus := main.AddText("x105 y448 w470 h22 cD0D0D0", "Idle. F8 stops AI gathering; it does not stop separate route scripts.")

; Status tab: current activity, event history, and Discord notification settings.
statusPage := main.AddGroupBox("x82 y72 w550 h450", "")
statusTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "◷")
statusTitle.SetFont("s16 Bold", "Segoe UI")
activityLabel := main.AddText("x105 y128 w470 h22 cEEEEEE", "Current activity")
activityText := main.AddText("x105 y151 w470 h30 cFFFFFF", "Ready")
logLabel := main.AddText("x105 y188 w470 h22 cEEEEEE", "Recent activity")
activityBox := main.AddEdit("x105 y211 w470 h72 ReadOnly -Wrap")
honeyLabel := main.AddText("x105 y289 w165 h22 cEEEEEE", "Honey made this session")
honeyBox := main.AddEdit("x270 y286 w135 h26 Number", "0")
updateHoneyBtn := main.AddButton("x420 y285 w155 h28", "Update stats")
honeyStatsText := main.AddText("x105 y316 w470 h24 c8CCBFF", "0 honey/s  |  0 honey/min  |  0 honey/hour")
webhookLabel := main.AddText("x105 y343 w470 h22 cEEEEEE", "Discord webhook URL")
webhookBox := main.AddEdit("x105 y365 w470 h26 Password")
webhookEnable := main.AddCheckbox("x105 y394 w280 h24", "Send activity updates to Discord")
saveWebhookBtn := main.AddButton("x105 y424 w135 h32", "Save")
testWebhookBtn := main.AddButton("x255 y424 w135 h32", "Test")
webhookStatus := main.AddText("x400 y430 w175 h24 cEEEEEE", "")
webhookBox.ToolTip := "Paste a Discord webhook URL. Keep it private."
; Images tab retains the screenshot/template collector.
imagesPage := main.AddGroupBox("x82 y72 w550 h450", "")
imagesTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "▧")
imagesTitle.SetFont("s16 Bold", "Segoe UI")
categoryBox := main.AddDropDownList("x105 y132 w470 Choose1", Categories)
nameBox := main.AddEdit("x105 y174 w470")
captureBtn := main.AddButton("x105 y220 w105 h40", "◉")
chooseBtn := main.AddButton("x225 y220 w105 h40", "▧")
clipBtn := main.AddButton("x345 y220 w105 h40", "▣")
saveBtn := main.AddButton("x465 y220 w110 h40 Default", "↓")
statusText := main.AddText("x105 y278 w470 h80 cEEEEEE", "")
categoryBox.ToolTip := "Image category", nameBox.ToolTip := "Image name"
captureBtn.ToolTip := "Capture screen", chooseBtn.ToolTip := "Choose image"
clipBtn.ToolTip := "Use clipboard image", saveBtn.ToolTip := "Save image"

captureBtn.OnEvent("Click", CaptureScreen)
chooseBtn.OnEvent("Click", ChooseImage)
clipBtn.OnEvent("Click", SaveClipboardImage)
saveBtn.OnEvent("Click", SaveImage)
gatherTab.OnEvent("Click", (*) => ShowPage("gather"))
settingsTab.OnEvent("Click", (*) => ShowPage("settings"))
imagesTab.OnEvent("Click", (*) => ShowPage("images"))
statusTab.OnEvent("Click", (*) => ShowPage("status"))
visionTab.OnEvent("Click", (*) => ShowPage("vision"))
routesTab.OnEvent("Click", (*) => ShowPage("routes"))
routesFolderBtn.OnEvent("Click", ChooseRouteScriptsFolder)
toggleBtn.OnEvent("Click", ToggleSidebar)
startBtn.OnEvent("Click", StartGather)
stopBtn.OnEvent("Click", StopGather)
saveSettingsBtn.OnEvent("Click", SaveSettings)
resetSettingsBtn.OnEvent("Click", ResetSettings)
tokenImageBtn.OnEvent("Click", ChooseTokenImage)
hasteFolderBtn.OnEvent("Click", ChooseHasteFolder)
visionStartBtn.OnEvent("Click", StartVision)
visionStopBtn.OnEvent("Click", StopVision)
aiTokenFolderBtn.OnEvent("Click", ChooseAITokenFolder)
aiGatherStartBtn.OnEvent("Click", StartAIGather)
aiGatherStopBtn.OnEvent("Click", StopAIGather)
saveWebhookBtn.OnEvent("Click", SaveWebhook)
testWebhookBtn.OnEvent("Click", TestWebhook)
updateHoneyBtn.OnEvent("Click", UpdateHoneyStats)
main.OnEvent("Close", ShutdownNectarX)
Hotkey("F8", StopAIGather)
LoadSettings()
LoadWebhook()
LogActivity("NectarX ready. AI gathering uses visible image templates and approximate screen-relative movement.")
ShowPage("gather")
main.Show("w650 h550")

ShowPage(page) {
    global gatherPage, gatherTitle, fieldLabel, fieldBox, patternLabel, patternBox, durationLabel, durationBox, repeatLabel, repeatBox, startBtn, stopBtn, gatherStatus
    global settingsPage, settingsTitle, speedLabel, speedBox, speedHint, gameLabel, gameBox, detectLabel, detectBox, cameraLabel, cameraBox, scanRateLabel, scanRateBox, scanRateHint, saveSettingsBtn, resetSettingsBtn, settingsStatus
    global imagesPage, imagesTitle, categoryBox, nameBox, captureBtn, chooseBtn, clipBtn, saveBtn, statusText
    global visionPage, visionTitle, tokenImageLabel, tokenImageBox, tokenImageBtn, hasteFolderLabel, hasteFolderBox, hasteFolderBtn, visionStartBtn, visionStopBtn, visionStatus, visionRuleText, aiGatherTitle, aiTokenFolderLabel, aiTokenFolderBox, aiTokenFolderBtn, aiGatherStartBtn, aiGatherStopBtn, aiGatherStatus
    global statusPage, statusTitle, activityLabel, activityText, logLabel, activityBox, honeyLabel, honeyBox, updateHoneyBtn, honeyStatsText, webhookLabel, webhookBox, webhookEnable, saveWebhookBtn, testWebhookBtn, webhookStatus
    global routesPage, routesTitle, routesFolderLabel, routesFolderBox, routesFolderBtn, routesInfo, routesStatus, routeButtons
    for c in [gatherPage,gatherTitle,fieldLabel,fieldBox,patternLabel,patternBox,durationLabel,durationBox,repeatLabel,repeatBox,startBtn,stopBtn,gatherStatus]
        c.Visible := page = "gather"
    for c in [settingsPage,settingsTitle,speedLabel,speedBox,speedHint,gameLabel,gameBox,detectLabel,detectBox,cameraLabel,cameraBox,scanRateLabel,scanRateBox,scanRateHint,saveSettingsBtn,resetSettingsBtn,settingsStatus]
        c.Visible := page = "settings"
    for c in [visionPage,visionTitle,tokenImageLabel,tokenImageBox,tokenImageBtn,hasteFolderLabel,hasteFolderBox,hasteFolderBtn,visionStartBtn,visionStopBtn,visionStatus,visionRuleText,aiGatherTitle,aiTokenFolderLabel,aiTokenFolderBox,aiTokenFolderBtn,aiGatherStartBtn,aiGatherStopBtn,aiGatherStatus]
        c.Visible := page = "vision"
    routesPage.Visible := page = "routes"
    routesTitle.Visible := page = "routes", routesFolderLabel.Visible := page = "routes", routesFolderBox.Visible := page = "routes", routesFolderBtn.Visible := page = "routes", routesInfo.Visible := page = "routes", routesStatus.Visible := page = "routes"
    for c in routeButtons
        c.Visible := page = "routes"
    for c in [imagesPage,imagesTitle,categoryBox,nameBox,captureBtn,chooseBtn,clipBtn,saveBtn,statusText]
        c.Visible := page = "images"
    for c in [statusPage,statusTitle,activityLabel,activityText,logLabel,activityBox,honeyLabel,honeyBox,updateHoneyBtn,honeyStatsText,webhookLabel,webhookBox,webhookEnable,saveWebhookBtn,testWebhookBtn,webhookStatus]
        c.Visible := page = "status"
    if (page = "status")
        RefreshActivity()
}
ToggleSidebar(*) {
    global main, sidebar, toggleBtn, gatherTab, settingsTab, imagesTab, statusTab, visionTab
    static expanded := false
    expanded := !expanded
    if expanded {
        sidebar.Move(0,66,150,470), toggleBtn.Move(105,74,34,30)
        gatherTab.Move(12,119,126,44), settingsTab.Move(12,173,126,44), imagesTab.Move(12,227,126,44), statusTab.Move(12,281,126,44), visionTab.Move(12,335,126,44)
        gatherTab.Text := "◈  Gather", settingsTab.Text := "⚙  Settings", imagesTab.Text := "▧  Images", statusTab.Text := "◷  Status", visionTab.Text := "◎  Vision"
        toggleBtn.Text := "‹", main.Show("w740")
    } else {
        sidebar.Move(0,66,64,470), toggleBtn.Move(15,74,34,30)
        gatherTab.Move(9,119,46,44), settingsTab.Move(9,173,46,44), imagesTab.Move(9,227,46,44), statusTab.Move(9,281,46,44), visionTab.Move(9,335,46,44)
        gatherTab.Text := "◈", settingsTab.Text := "⚙", imagesTab.Text := "▧", statusTab.Text := "◷", visionTab.Text := "◎"
        toggleBtn.Text := "›", main.Show("w650")
    }
}
StartGather(*) {
    global gatherStatus, durationBox, repeatBox, fieldBox, patternBox
    if (Trim(durationBox.Value) = "" || !IsNumber(durationBox.Value) || durationBox.Value <= 0) {
        MsgBox("Enter a gather duration greater than zero.", "NectarX", "Icon!")
        return
    }
    if (Trim(repeatBox.Value) = "" || !IsNumber(repeatBox.Value) || repeatBox.Value <= 0) {
        MsgBox("Enter pattern repeats greater than zero.", "NectarX", "Icon!")
        return
    }
    gatherStatus.Text := "Gather options are set; automation runner is not connected yet."
    LogActivity("Gather requested for " fieldBox.Text " using " patternBox.Text ". Runner is not connected.")
    MsgBox("The Gather interface is ready, but the movement automation is not connected yet.", "NectarX", "Iconi")
}
StopGather(*) {
    global gatherStatus
    gatherStatus.Text := "No active gather runner."
    LogActivity("Stop requested. No gather runner was active.")
}
SaveSettings(*) {
    global RootDir, speedBox, gameBox, detectBox, cameraBox, scanRateBox, tokenImageBox, hasteFolderBox, aiTokenFolderBox, routesFolderBox, settingsStatus
    speed := Trim(speedBox.Value)
    if (speed = "" || !IsNumber(speed) || speed <= 0 || speed > 5) {
        MsgBox("Move speed must be greater than 0 and no more than 5.", "NectarX", "Icon!")
        return
    }
    data := "move_speed=" speed "`n" . "game=" gameBox.Text "`n" . "game_detection=" detectBox.Text "`n" . "camera=" cameraBox.Text "`n" . "screen_reads_per_sec=" scanRateBox.Text "`n" . "token_line_image=" tokenImageBox.Value "`n" . "haste_image_folder=" hasteFolderBox.Value "`n" . "ai_token_folder=" aiTokenFolderBox.Value "`n" . "route_scripts_folder=" routesFolderBox.Value "`n"
    path := RootDir "\nectarx_settings.ini"
    try {
        if FileExist(path)
            FileDelete(path)
        FileAppend(data, path, "UTF-8")
        settingsStatus.Text := "✓"
        LogActivity("Settings saved locally.")
    } catch as err {
        MsgBox("Could not save settings: " err.Message, "NectarX", "Iconx")
    }
}
LoadSettings() {
    global RootDir, speedBox, gameBox, detectBox, cameraBox, scanRateBox, tokenImageBox, hasteFolderBox, aiTokenFolderBox, routesFolderBox
    path := RootDir "\nectarx_settings.ini"
    if !FileExist(path)
        return
    try {
        for line in StrSplit(FileRead(path, "UTF-8"), "`n") {
            parts := StrSplit(Trim(line), "=")
            if (parts.Length < 2)
                continue
            if (parts[1] = "move_speed")
                speedBox.Value := parts[2]
            else if (parts[1] = "game")
                gameBox.Text := parts[2]
            else if (parts[1] = "game_detection")
                detectBox.Text := parts[2]
            else if (parts[1] = "camera")
                cameraBox.Text := parts[2]
            else if (parts[1] = "screen_reads_per_sec")
                scanRateBox.Text := parts[2]
            else if (parts[1] = "token_line_image")
                tokenImageBox.Value := SubStr(line, StrLen("token_line_image=") + 1)
            else if (parts[1] = "haste_image_folder")
                hasteFolderBox.Value := SubStr(line, StrLen("haste_image_folder=") + 1)
            else if (parts[1] = "ai_token_folder")
                aiTokenFolderBox.Value := SubStr(line, StrLen("ai_token_folder=") + 1)
            else if (parts[1] = "route_scripts_folder")
                routesFolderBox.Value := SubStr(line, StrLen("route_scripts_folder=") + 1)
        }
    }
}
ResetSettings(*) {
    global speedBox, gameBox, detectBox, cameraBox, scanRateBox, settingsStatus
    speedBox.Value := "1.0", gameBox.Choose(1), detectBox.Choose(1), cameraBox.Choose(1), scanRateBox.Choose(2)
    settingsStatus.Text := ""
}


ChooseTokenImage(*) {
    global TokenLineImage, tokenImageBox
    file := FileSelect(1, , "Choose cropped token-line template", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
    if (file = "")
        return
    TokenLineImage := file
    tokenImageBox.Value := file
}
ChooseHasteFolder(*) {
    global HasteImageFolder, hasteFolderBox
    folder := DirSelect(, 1, "Choose folder containing haste_1.png through haste_10.png")
    if (folder = "")
        return
    HasteImageFolder := folder
    hasteFolderBox.Value := folder
}
StartVision(*) {
    global VisionRunning, scanRateBox, TokenLineImage, HasteImageFolder, tokenImageBox, hasteFolderBox, visionStatus
    TokenLineImage := Trim(tokenImageBox.Value)
    HasteImageFolder := Trim(hasteFolderBox.Value)
    if (TokenLineImage = "" || !FileExist(TokenLineImage)) {
        MsgBox("Choose a valid token-line template image first.", "NectarX", "Icon!")
        return
    }
    if (HasteImageFolder = "" || !DirExist(HasteImageFolder)) {
        MsgBox("Choose the folder containing haste_1.png through haste_10.png.", "NectarX", "Icon!")
        return
    }
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") && !WinExist("Roblox") {
        MsgBox("Roblox was not detected. Open Bee Swarm Simulator and try again.", "NectarX", "Icon!")
        return
    }
    VisionRunning := true
    visionStatus.Text := "Reading Roblox screen…"
    rate := scanRateBox.Text + 0
    SetTimer(ScanRobloxScreen, Max(100, Round(1000 / rate)))
    LogActivity("Roblox screen reader started at " rate " reads/sec.")
    ScanRobloxScreen()
}
StopVision(*) {
    global VisionRunning, visionStatus
    VisionRunning := false
    SetTimer(ScanRobloxScreen, 0)
    visionStatus.Text := "Stopped."
    LogActivity("Roblox screen reader stopped.")
}
ScanRobloxScreen() {
    global VisionRunning, TokenLineImage, HasteImageFolder, visionStatus, LastVisionState, LastHasteStacks
    if !VisionRunning
        return
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        hwnd := WinExist("Roblox")
    if !hwnd {
        visionStatus.Text := "Roblox window not found. Reader paused."
        return
    }
    try {
        WinGetClientPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
        if (ww < 20 || wh < 20)
            return
        tokenFound := FindTemplate(TokenLineImage, wx, wy, wx + ww - 1, wy + wh - 1)
        hasteStacks := 0
        Loop 10 {
            n := 11 - A_Index
            template := HasteImageFolder "\haste_" n ".png"
            if FileExist(template) && FindTemplate(template, wx, wy, wx + ww - 1, wy + wh - 1) {
                hasteStacks := n
                break
            }
        }
        state := "Token line: " (tokenFound ? "FOUND" : "not found") " | Haste stacks: " hasteStacks
        visionStatus.Text := state
        if (state != LastVisionState) {
            LogActivity("Screen reader: " state ".")
            LastVisionState := state
        }
        LastHasteStacks := hasteStacks
    } catch as err {
        visionStatus.Text := "Screen read error: " err.Message
    }
}
ChooseAITokenFolder(*) {
    global AITokenFolder, aiTokenFolderBox
    folder := DirSelect(, 1, "Choose folder containing cropped token images")
    if (folder = "")
        return
    AITokenFolder := folder
    aiTokenFolderBox.Value := folder
}
ChooseRouteScriptsFolder(*) {
    global RouteScriptsFolder, routesFolderBox, routesStatus
    folder := DirSelect(, 1, "Choose folder containing your NectarX route scripts")
    if (folder = "")
        return
    RouteScriptsFolder := folder
    routesFolderBox.Value := folder
    routesStatus.Text := "Folder selected. Save Settings to remember it."
}
RunRouteScript(fileName, *) {
    global RouteScriptsFolder, routesFolderBox, routesStatus
    folder := Trim(routesFolderBox.Value)
    if (folder = "" || !DirExist(folder)) {
        MsgBox("Choose a valid route scripts folder first.", "NectarX", "Icon!")
        return
    }
    path := folder "\\" fileName
    if !FileExist(path) {
        MsgBox("Script not found:`n" path "`n`nCreate this .ahk file in your selected folder, then try again.", "NectarX", "Icon!")
        return
    }
    try {
        Run('"' A_AhkPath '" "' path '"', folder)
        routesStatus.Text := "Launched: " fileName
        LogActivity("Route script launched: " fileName)
    } catch as err {
        routesStatus.Text := "Launch failed: " err.Message
    }
}

StartAIGather(*) {
    global AIGatherRunning, AITokenFolder, aiTokenFolderBox, aiGatherStatus
    AITokenFolder := Trim(aiTokenFolderBox.Value)
    if (AITokenFolder = "" || !DirExist(AITokenFolder)) {
        MsgBox("Choose a folder containing cropped token images first.", "NectarX", "Icon!")
        return
    }
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") && !WinExist("Roblox") {
        MsgBox("Open Bee Swarm Simulator in Roblox first.", "NectarX", "Icon!")
        return
    }
    AIGatherRunning := true
    aiGatherStatus.Text := "Running: searching token templates…"
    LogActivity("AI gathering started.")
    SetTimer(AIGatherTick, 250)
    AIGatherTick()
}
ShutdownNectarX(*) {
    StopAIGather()
    StopVision()
    ExitApp()
}
StopAIGather(*) {
    global AIGatherRunning, aiGatherStatus, AIHeldKeys, AILeftHeld
    AIGatherRunning := false
    SetTimer(AIGatherTick, 0)
    for key in AIHeldKeys
        Send("{" key " up}")
    AIHeldKeys := []
    if AILeftHeld {
        Click("Left Up")
        AILeftHeld := false
    }
    aiGatherStatus.Text := "Stopped. Inputs released. (F8 also stops AI gathering.)"
    LogActivity("AI gathering stopped; inputs released.")
}
AIGatherTick() {
    global AIGatherRunning, AITokenFolder, aiGatherStatus, speedBox, LastHasteStacks, HasteImageFolder, VisionRunning, AIHeldKeys, AILeftHeld
    if !AIGatherRunning
        return
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        hwnd := WinExist("Roblox")
    if !hwnd {
        aiGatherStatus.Text := "Roblox window not found."
        return
    }
    try {
        WinActivate("ahk_id " hwnd)
        WinGetClientPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
        if (ww < 20 || wh < 20)
            return
        haste := Max(0, LastHasteStacks)
        if !VisionRunning && HasteImageFolder != "" && DirExist(HasteImageFolder) {
            Loop 10 {
                n := 11 - A_Index
                if FindTemplate(HasteImageFolder "\haste_" n ".png", wx, wy, wx + ww - 1, wy + wh - 1) {
                    haste := n
                    break
                }
            }
        }
        targetX := 0, targetY := 0, found := false, foundName := ""
        Loop Files, AITokenFolder "\*.*", "F" {
            ext := StrLower(A_LoopFileExt)
            if !(ext = "png" || ext = "bmp" || ext = "jpg" || ext = "jpeg")
                continue
            try {
                if ImageSearch(&tx, &ty, wx, wy, wx + ww - 1, wy + wh - 1, "*20 " A_LoopFileFullPath) {
                    targetX := tx, targetY := ty, found := true, foundName := A_LoopFileName
                    break
                }
            }
        }
        if !AILeftHeld {
            Click("Left Down")
            AILeftHeld := true
        }
        if !found {
            aiGatherStatus.Text := "Searching… tool click held. No saved token visible."
            AIReleaseMoveKeys()
            return
        }
        centerX := wx + Round(ww / 2), centerY := wy + Round(wh / 2)
        dx := targetX - centerX, dy := targetY - centerY
        speed := speedBox.Value + 0
        hasteMultiplier := 1.1 ** haste
        duration := Round((Abs(dx) + Abs(dy)) / Max(1, 2.2 * Max(0.2, speed) * hasteMultiplier))
        duration := Min(220, Max(35, duration))
        keys := []
        if Abs(dx) > 35
            keys.Push(dx < 0 ? "a" : "d")
        if Abs(dy) > 35
            keys.Push(dy < 0 ? "w" : "s")
        AISetMoveKeys(keys)
        aiGatherStatus.Text := "Target: " foundName " | Haste " haste " stacks | adjusting movement."
        Sleep(duration)
    } catch as err {
        aiGatherStatus.Text := "AI gather error: " err.Message
    }
}
AISetMoveKeys(keys) {
    global AIHeldKeys
    for key in AIHeldKeys {
        if !HasKeyInArray(keys, key)
            Send("{" key " up}")
    }
    for key in keys {
        if !HasKeyInArray(AIHeldKeys, key)
            Send("{" key " down}")
    }
    AIHeldKeys := keys
}
AIReleaseMoveKeys() {
    global AIHeldKeys
    for key in AIHeldKeys
        Send("{" key " up}")
    AIHeldKeys := []
}
HasKeyInArray(arr, value) {
    for item in arr
        if (item = value)
            return true
    return false
}
FindTemplate(imagePath, x1, y1, x2, y2) {
    if !FileExist(imagePath)
        return false
    try return ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*20 " imagePath)
    catch
        return false
}

LogActivity(message) {
    global ActivityLog
    line := FormatTime(, "HH:mm:ss") "  " message
    ActivityLog := line Chr(13) Chr(10) ActivityLog
    if (StrLen(ActivityLog) > 6000)
        ActivityLog := SubStr(ActivityLog, 1, 6000)
    RefreshActivity()
    SendWebhook(message)
}
RefreshActivity() {
    global ActivityLog, activityBox, activityText, honeyStatsText
    try activityBox.Value := ActivityLog
    try activityText.Text := StrSplit(ActivityLog, Chr(13) Chr(10))[1]
    try honeyStatsText.Text := StatsSummary()
}
LoadWebhook() {
    global WebhookPath, WebhookUrl, webhookBox
    if FileExist(WebhookPath) {
        try WebhookUrl := Trim(FileRead(WebhookPath, "UTF-8"))
        try webhookBox.Value := WebhookUrl
    }
}
SaveWebhook(*) {
    global WebhookPath, WebhookUrl, webhookBox, webhookStatus
    url := Trim(webhookBox.Value)
    if (url != "" && !RegExMatch(url, "^https://(discord\.com|discordapp\.com)/api/webhooks/")) {
        MsgBox("Enter a Discord webhook URL beginning with https://discord.com/api/webhooks/.", "NectarX", "Icon!")
        return
    }
    WebhookUrl := url
    try {
        if FileExist(WebhookPath)
            FileDelete(WebhookPath)
        FileAppend(WebhookUrl, WebhookPath, "UTF-8")
        webhookStatus.Text := "Saved"
        LogActivity("Discord webhook settings saved.")
    } catch as err {
        MsgBox("Could not save webhook settings: " err.Message, "NectarX", "Iconx")
    }
}
TestWebhook(*) {
    global WebhookUrl, webhookBox, webhookStatus
    WebhookUrl := Trim(webhookBox.Value)
    if (WebhookUrl = "") {
        MsgBox("Paste a Discord webhook URL first.", "NectarX", "Icon!")
        return
    }
    if SendWebhook("NectarX webhook test: connection configured.", true) {
        webhookStatus.Text := "Test sent"
        LogActivity("Discord webhook test sent.")
    } else {
        webhookStatus.Text := "Failed"
        MsgBox("Webhook test failed. Check the URL and internet connection.", "NectarX", "Iconx")
    }
}
SendWebhook(message, force := false) {
    global WebhookUrl, webhookEnable, HoneySession, SessionStartTick
    if (Trim(WebhookUrl) = "")
        return false
    if (!force && !webhookEnable.Value)
        return false
    try {
        elapsed := Max(1, (A_TickCount - SessionStartTick) / 1000)
        perSec := HoneySession / elapsed
        perMin := perSec * 60
        perHour := perSec * 3600
        graph := BuildHoneyGraph(perSec, perMin, perHour)
        description := "**Session honey:** " FormatHoney(HoneySession) "`n" 
            . "**Honey / second:** " FormatHoney(perSec) "`n"
            . "**Honey / minute:** " FormatHoney(perMin) "`n"
            . "**Average / hour:** " FormatHoney(perHour) "`n`n"
            . "```text`n" graph "`n```"
            . "`n**Activity:** " message
        body := "{""embeds"":[{""title"":""NectarX | Honey Analytics"",""description"":""" JsonEscape(description) """,""color"":1477631,""footer"":{""text"":""NectarX • This session""}}]}"
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.Open("POST", WebhookUrl, false)
        request.SetRequestHeader("Content-Type", "application/json")
        request.Send(body)
        return request.Status >= 200 && request.Status < 300
    } catch {
        return false
    }
}
UpdateHoneyStats(*) {
    global honeyBox, HoneySession, HoneyHistory, SessionStartTick
    value := Trim(honeyBox.Value)
    if (value = "" || !IsNumber(value) || value < 0) {
        MsgBox("Enter a valid non-negative honey amount.", "NectarX", "Icon!")
        return
    }
    HoneySession := value + 0
    elapsed := Max(1, (A_TickCount - SessionStartTick) / 1000)
    ; Store one checkpoint whenever the user updates the session total.
    HoneyHistory.Push({seconds: elapsed, honey: HoneySession})
    while (HoneyHistory.Length > 12)
        HoneyHistory.RemoveAt(1)
    RefreshActivity()
    LogActivity("Honey checkpoint saved: " FormatHoney(HoneySession) " total. Analytics sent if Discord updates are enabled.")
}
StatsSummary() {
    global HoneySession, SessionStartTick
    elapsed := Max(1, (A_TickCount - SessionStartTick) / 1000)
    perSec := HoneySession / elapsed
    return FormatHoney(perSec) " honey/s  |  " FormatHoney(perSec * 60) " honey/min  |  " FormatHoney(perSec * 3600) " honey/hour"
}
BuildHoneyGraph(perSec, perMin, perHour) {
    global HoneyHistory
    graph := "RATE SNAPSHOT`n"
        . "Per second : " FormatHoney(perSec) " honey/s`n"
        . "Per minute : " FormatHoney(perMin) " honey/min`n"
        . "Per hour   : " FormatHoney(perHour) " honey/hour`n`n"
        . "SESSION CHECKPOINTS (latest 12)`n"
    if (HoneyHistory.Length = 0)
        return graph "No checkpoints yet. Click Update stats to record one."
    maxHoney := 1
    for point in HoneyHistory
        maxHoney := Max(maxHoney, point.honey)
    startAt := Max(1, HoneyHistory.Length - 7)
    for i, point in HoneyHistory {
        if (i < startAt)
            continue
        minutes := Floor(point.seconds / 60)
        seconds := Mod(Floor(point.seconds), 60)
        elapsedLabel := Format("{:02}:{:02}", minutes, seconds)
        graph .= elapsedLabel " | " Bar(point.honey, maxHoney, 16) " "
            . FormatHoney(point.honey) " honey`n"
        if (i > startAt) {
            previous := HoneyHistory[i - 1]
            gained := Max(0, point.honey - previous.honey)
            graph .= "       +" FormatHoney(gained) " since previous checkpoint`n"
        }
    }
    if (HoneyHistory.Length < 2)
        graph .= "`nUpdate the total again later to show session progress."
    return graph
}
Bar(value, maxVal, width := 16) {
    length := (maxVal <= 0) ? 0 : Round((value / maxVal) * width)
    if (length < 1 && value > 0)
        length := 1
    return (length > 0 ? StrReplace(Format("{:" length "}", ""), " ", "█") : "·")
}
FormatHoney(value) {
    return Format("{:,.2f}", value)
}

CaptureScreen(*) {
    global TempPath, CurrentImage, nameBox, statusText
    statusText.Text := "…"
    ps := A_Temp "\nectarx_capture.ps1"
    script := "$ErrorActionPreference='Stop'`n"
        . "Add-Type -AssemblyName System.Windows.Forms`n"
        . "Add-Type -AssemblyName System.Drawing`n"
        . "$b=[System.Windows.Forms.SystemInformation]::VirtualScreen`n"
        . "$bmp=New-Object System.Drawing.Bitmap($b.Width,$b.Height)`n"
        . "$g=[System.Drawing.Graphics]::FromImage($bmp)`n"
        . "$g.CopyFromScreen($b.Left,$b.Top,0,0,$bmp.Size)`n"
        . "$bmp.Save('" . StrReplace(TempPath, "'", "''") . "',[System.Drawing.Imaging.ImageFormat]::Png)`n"
        . "$g.Dispose();$bmp.Dispose()`n"
    try {
        if FileExist(TempPath)
            FileDelete(TempPath)
        FileAppend(script, ps, "UTF-8")
        exitCode := RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ps '"', , "Hide")
        if (exitCode != 0 || !FileExist(TempPath))
            throw Error("Windows could not capture the screen.")
        CurrentImage := TempPath
        if (Trim(nameBox.Value) = "")
            nameBox.Value := "screen_capture"
        statusText.Text := "✓"
    } catch as err {
        MsgBox("Capture failed:`n" err.Message, "NectarX", "Iconx")
        statusText.Text := "×"
    }
}

ChooseImage(*) {
    global CurrentImage, nameBox, statusText
    file := FileSelect(1, , "Choose a screenshot", "Images (*.png; *.jpg; *.jpeg; *.bmp; *.webp)")
    if (file = "")
        return
    CurrentImage := file
    LogActivity("Selected image: " file)
    if (Trim(nameBox.Value) = "") {
        SplitPath(file, &baseName)
        nameBox.Value := baseName
    }
    statusText.Text := "✓"
}

SaveClipboardImage(*) {
    global TempPath, CurrentImage, nameBox, statusText
    ps := A_Temp "\nectarx_clipboard.ps1"
    script := "$ErrorActionPreference='Stop'`n"
        . "Add-Type -AssemblyName System.Windows.Forms`n"
        . "Add-Type -AssemblyName System.Drawing`n"
        . "$img=[System.Windows.Forms.Clipboard]::GetImage()`n"
        . "if($null -eq $img){throw 'Clipboard has no image. Use Win+Shift+S and copy a region first.'}`n"
        . "$img.Save('" . StrReplace(TempPath, "'", "''") . "',[System.Drawing.Imaging.ImageFormat]::Png)`n"
        . "$img.Dispose()`n"
    try {
        if FileExist(TempPath)
            FileDelete(TempPath)
        FileAppend(script, ps, "UTF-8")
        exitCode := RunWait('powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "' ps '"', , "Hide")
        if (exitCode != 0 || !FileExist(TempPath))
            throw Error("No image was found on the clipboard. Use Win+Shift+S, select an area, then try again.")
        CurrentImage := TempPath
        if (Trim(nameBox.Value) = "")
            nameBox.Value := "screen_region"
        statusText.Text := "✓"
    } catch as err {
        MsgBox(err.Message, "NectarX", "Iconx")
        statusText.Text := "×"
    }
}

SaveImage(*) {
    global CurrentImage, ImageRoot, ManifestPath, categoryBox, nameBox, statusText
    if (CurrentImage = "" || !FileExist(CurrentImage)) {
        MsgBox("Capture a screen, select an image, or copy a cropped screenshot first.", "NectarX", "Icon!")
        return
    }
    rawName := Trim(nameBox.Value)
    if (rawName = "") {
        MsgBox("Enter an image name first.", "NectarX", "Icon!")
        return
    }
    safeName := RegExReplace(rawName, "[^\pL\pN_-]", "_")
    safeName := Trim(safeName, "_")
    if (safeName = "") {
        MsgBox("Use a name containing letters or numbers.", "NectarX", "Icon!")
        return
    }
    category := categoryBox.Text
    folder := ImageRoot "\" category
    DirCreate(folder)
    target := folder "\" safeName ".png"
    if FileExist(target) {
        answer := MsgBox(target " already exists. Replace it?", "NectarX", "YesNo Icon?")
        if (answer != "Yes")
            return
    }
    try {
        ps := A_Temp "\nectarx_convert.ps1"
        sourcePath := CurrentImage
        script := "$ErrorActionPreference='Stop'`n"
            . "Add-Type -AssemblyName System.Drawing`n"
            . "$src=[System.Drawing.Image]::FromFile('" . StrReplace(sourcePath, "'", "''") . "')`n"
            . "$src.Save('" . StrReplace(target, "'", "''") . "',[System.Drawing.Imaging.ImageFormat]::Png)`n"
            . "$src.Dispose()`n"
        FileAppend(script, ps, "UTF-8")
        exitCode := RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ps '"', , "Hide")
        if (exitCode != 0 || !FileExist(target))
            throw Error("Could not convert and save this image.")
        sizeScript := "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Drawing; $i=[System.Drawing.Image]::FromFile('" . StrReplace(target, "'", "''") . "'); Write-Output ($i.Width.ToString()+','+$i.Height.ToString()); $i.Dispose()"
        sizeFile := A_Temp "\nectarx_size.txt"
        if FileExist(sizeFile)
            FileDelete(sizeFile)
        RunWait('powershell.exe -NoProfile -Command "' sizeScript '" > "' sizeFile '"', , "Hide")
        width := 0, height := 0
        if FileExist(sizeFile) {
            dims := StrSplit(Trim(FileRead(sizeFile)), ",")
            if (dims.Length >= 2)
                width := dims[1], height := dims[2]
        }
        relativePath := "NectarX images/" category "/" safeName ".png"
        manifest := LoadManifest(ManifestPath)
        entry := "  {""name"":""" JsonEscape(safeName) """,""category"":""" JsonEscape(category) """,""path"":""" JsonEscape(relativePath) """,""width"":" width ",""height"":" height ",""captured_at"":""" FormatTime(, "yyyy-MM-ddTHH:mm:ss") """,""label"":""" JsonEscape(StrReplace(rawName, "_", " ")) """}"
        if (manifest = "")
            manifest := "[" entry "]"
        else {
            manifest := Trim(manifest)
            manifest := RegExReplace(manifest, "\]\s*$", "")
            if (SubStr(manifest, -1) != "[")
                manifest .= ","
            manifest .= "`n" entry "`n]"
        }
        DirCreate(ImageRoot)
        if FileExist(ManifestPath)
            FileDelete(ManifestPath)
        FileAppend(manifest, ManifestPath, "UTF-8")
        CurrentImage := ""
        nameBox.Value := ""
        statusText.Text := "✓"
        LogActivity("Saved image: " relativePath)
        MsgBox("Image saved:`n" target "`n`nManifest updated.", "NectarX", "Iconi")
    } catch as err {
        MsgBox("Save failed:`n" err.Message, "NectarX", "Iconx")
    }
}

LoadManifest(path) {
    if !FileExist(path)
        return ""
    content := Trim(FileRead(path, "UTF-8"))
    if (content = "" || content = "[]")
        return ""
    return content
}

JsonEscape(value) {
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, '"', '\"')
    value := StrReplace(value, "`r", "\r")
    value := StrReplace(value, "`n", "\n")
    return value
}
