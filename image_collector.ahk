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
gatherTab.ToolTip := "Gather", settingsTab.ToolTip := "Settings", imagesTab.ToolTip := "Images", statusTab.ToolTip := "Status"

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
saveSettingsBtn := main.AddButton("x105 y330 w220 h42", "✓")
resetSettingsBtn := main.AddButton("x345 y330 w220 h42", "↺")
settingsStatus := main.AddText("x105 y390 w470 h40 cEEEEEE", "")
saveSettingsBtn.ToolTip := "Save settings", resetSettingsBtn.ToolTip := "Reset settings"

; Status tab: current activity, event history, and Discord notification settings.
statusPage := main.AddGroupBox("x82 y72 w550 h450", "")
statusTitle := main.AddText("x105 y91 w490 h30 cF0F0F0", "◷")
statusTitle.SetFont("s16 Bold", "Segoe UI")
activityLabel := main.AddText("x105 y128 w470 h22 cEEEEEE", "Current activity")
activityText := main.AddText("x105 y151 w470 h30 cFFFFFF", "Ready")
logLabel := main.AddText("x105 y188 w470 h22 cEEEEEE", "Recent activity")
activityBox := main.AddEdit("x105 y211 w470 h105 ReadOnly -Wrap")
webhookLabel := main.AddText("x105 y332 w470 h22 cEEEEEE", "Discord webhook URL")
webhookBox := main.AddEdit("x105 y356 w470 h28 Password")
webhookEnable := main.AddCheckbox("x105 y392 w260 h24", "Send activity updates to Discord")
saveWebhookBtn := main.AddButton("x105 y428 w135 h36", "Save")
testWebhookBtn := main.AddButton("x255 y428 w135 h36", "Test")
webhookStatus := main.AddText("x400 y433 w175 h24 cEEEEEE", "")
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
toggleBtn.OnEvent("Click", ToggleSidebar)
startBtn.OnEvent("Click", StartGather)
stopBtn.OnEvent("Click", StopGather)
saveSettingsBtn.OnEvent("Click", SaveSettings)
resetSettingsBtn.OnEvent("Click", ResetSettings)
saveWebhookBtn.OnEvent("Click", SaveWebhook)
testWebhookBtn.OnEvent("Click", TestWebhook)
main.OnEvent("Close", (*) => ExitApp())
LoadSettings()
LoadWebhook()
LogActivity("NectarX ready. Gather automation runner is not connected.")
ShowPage("gather")
main.Show("w650 h550")

ShowPage(page) {
    global gatherPage, gatherTitle, fieldLabel, fieldBox, patternLabel, patternBox, durationLabel, durationBox, repeatLabel, repeatBox, startBtn, stopBtn, gatherStatus
    global settingsPage, settingsTitle, speedLabel, speedBox, speedHint, gameLabel, gameBox, detectLabel, detectBox, cameraLabel, cameraBox, saveSettingsBtn, resetSettingsBtn, settingsStatus
    global imagesPage, imagesTitle, categoryBox, nameBox, captureBtn, chooseBtn, clipBtn, saveBtn, statusText
    global statusPage, statusTitle, activityLabel, activityText, logLabel, activityBox, webhookLabel, webhookBox, webhookEnable, saveWebhookBtn, testWebhookBtn, webhookStatus
    for c in [gatherPage,gatherTitle,fieldLabel,fieldBox,patternLabel,patternBox,durationLabel,durationBox,repeatLabel,repeatBox,startBtn,stopBtn,gatherStatus]
        c.Visible := page = "gather"
    for c in [settingsPage,settingsTitle,speedLabel,speedBox,speedHint,gameLabel,gameBox,detectLabel,detectBox,cameraLabel,cameraBox,saveSettingsBtn,resetSettingsBtn,settingsStatus]
        c.Visible := page = "settings"
    for c in [imagesPage,imagesTitle,categoryBox,nameBox,captureBtn,chooseBtn,clipBtn,saveBtn,statusText]
        c.Visible := page = "images"
    for c in [statusPage,statusTitle,activityLabel,activityText,logLabel,activityBox,webhookLabel,webhookBox,webhookEnable,saveWebhookBtn,testWebhookBtn,webhookStatus]
        c.Visible := page = "status"
    if (page = "status")
        RefreshActivity()
}
ToggleSidebar(*) {
    global main, sidebar, toggleBtn, gatherTab, settingsTab, imagesTab, statusTab
    static expanded := false
    expanded := !expanded
    if expanded {
        sidebar.Move(0,66,150,470), toggleBtn.Move(105,74,34,30)
        gatherTab.Move(12,119,126,44), settingsTab.Move(12,173,126,44), imagesTab.Move(12,227,126,44), statusTab.Move(12,281,126,44)
        gatherTab.Text := "◈  Gather", settingsTab.Text := "⚙  Settings", imagesTab.Text := "▧  Images", statusTab.Text := "◷  Status"
        toggleBtn.Text := "‹", main.Show("w740")
    } else {
        sidebar.Move(0,66,64,470), toggleBtn.Move(15,74,34,30)
        gatherTab.Move(9,119,46,44), settingsTab.Move(9,173,46,44), imagesTab.Move(9,227,46,44), statusTab.Move(9,281,46,44)
        gatherTab.Text := "◈", settingsTab.Text := "⚙", imagesTab.Text := "▧", statusTab.Text := "◷"
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
    global RootDir, speedBox, gameBox, detectBox, cameraBox, settingsStatus
    speed := Trim(speedBox.Value)
    if (speed = "" || !IsNumber(speed) || speed <= 0 || speed > 5) {
        MsgBox("Move speed must be greater than 0 and no more than 5.", "NectarX", "Icon!")
        return
    }
    data := "move_speed=" speed "`n" . "game=" gameBox.Text "`n" . "game_detection=" detectBox.Text "`n" . "camera=" cameraBox.Text "`n"
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
    global RootDir, speedBox, gameBox, detectBox, cameraBox
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
        }
    }
}
ResetSettings(*) {
    global speedBox, gameBox, detectBox, cameraBox, settingsStatus
    speedBox.Value := "1.0", gameBox.Choose(1), detectBox.Choose(1), cameraBox.Choose(1)
    settingsStatus.Text := ""
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
    global ActivityLog, activityBox, activityText
    try activityBox.Value := ActivityLog
    try activityText.Text := StrSplit(ActivityLog, Chr(13) Chr(10))[1]
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
    global WebhookUrl, webhookEnable
    if (Trim(WebhookUrl) = "")
        return false
    if (!force && !webhookEnable.Value)
        return false
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.Open("POST", WebhookUrl, false)
        request.SetRequestHeader("Content-Type", "application/json")
        request.Send("{""content"":""" JsonEscape("**NectarX** · " message) """}")
        return request.Status >= 200 && request.Status < 300
    } catch {
        return false
    }
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
