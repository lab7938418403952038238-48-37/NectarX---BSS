#Requires AutoHotkey v2.0
#SingleInstance Force

global RootDir := A_ScriptDir
global ImageRoot := RootDir "\NectarX images"
global ManifestPath := ImageRoot "\image_manifest.json"
global TempPath := A_Temp "\nectarx_capture.png"
global Categories := ["fields_landmarks", "tokens_flowers", "backpack_pollen", "hive_conversion", "movement_travel", "npcs_quests", "bees_abilities", "planters", "menus_ui", "other"]
global CurrentImage := ""

main := Gui("+Resize", "NectarX")
main.BackColor := "55585D"
main.SetFont("s10", "Segoe UI")
main.MarginX := 0
main.MarginY := 0

; Minimal logo in the upper-left; the vertical icon rail sits directly below it.
logo := main.AddText("x18 y16 w46 h46 Center 0x200 cF0F0F0", "⬡")
logo.SetFont("s28", "Segoe UI Symbol")
sidebar := main.AddText("x0 y72 w64 h430 Background:44474B", "")
toggleBtn := main.AddButton("x15 y82 w34 h32", "‹")
captureTab := main.AddButton("x12 y132 w40 h40", "◉")
fileTab := main.AddButton("x12 y182 w40 h40", "▧")
clipTab := main.AddButton("x12 y232 w40 h40", "▣")
saveTab := main.AddButton("x12 y282 w40 h40", "↓")

categoryBox := main.AddDropDownList("x100 y105 w470 Choose1", Categories)
nameBox := main.AddEdit("x100 y150 w470")
captureBtn := main.AddButton("x100 y205 w470 h38", "◉")
chooseBtn := main.AddButton("x100 y253 w470 h38", "▧")
clipBtn := main.AddButton("x100 y301 w470 h38", "▣")
saveBtn := main.AddButton("x100 y357 w470 h42 Default", "↓")
statusText := main.AddText("x100 y414 w470 h62 cEEEEEE", "")

; Tooltips provide guidance without adding visible labels.
toggleBtn.ToolTip := "Expand or collapse the sidebar"
captureTab.ToolTip := "Capture screen"
fileTab.ToolTip := "Choose image file"
clipTab.ToolTip := "Use clipboard image"
saveTab.ToolTip := "Save image"
categoryBox.ToolTip := "Image category"
nameBox.ToolTip := "Image name"

captureBtn.OnEvent("Click", CaptureScreen)
chooseBtn.OnEvent("Click", ChooseImage)
clipBtn.OnEvent("Click", SaveClipboardImage)
saveBtn.OnEvent("Click", SaveImage)
captureTab.OnEvent("Click", CaptureScreen)
fileTab.OnEvent("Click", ChooseImage)
clipTab.OnEvent("Click", SaveClipboardImage)
saveTab.OnEvent("Click", SaveImage)
toggleBtn.OnEvent("Click", ToggleSidebar)
main.OnEvent("Close", (*) => ExitApp())
main.Show("w650 h520")

ToggleSidebar(*) {
    global main, sidebar, toggleBtn, captureTab, fileTab, clipTab, saveTab
    global categoryBox, nameBox, captureBtn, chooseBtn, clipBtn, saveBtn, statusText
    static expanded := false
    expanded := !expanded
    if expanded {
        sidebar.Move(0, 72, 150, 430)
        toggleBtn.Move(105, 82, 34, 32)
        captureTab.Move(55, 132, 90, 40)
        fileTab.Move(55, 182, 90, 40)
        clipTab.Move(55, 232, 90, 40)
        saveTab.Move(55, 282, 90, 40)
        toggleBtn.Text := "‹"
        categoryBox.Move(185, 105, 420)
        nameBox.Move(185, 150, 420)
        captureBtn.Move(185, 205, 420, 38)
        chooseBtn.Move(185, 253, 420, 38)
        clipBtn.Move(185, 301, 420, 38)
        saveBtn.Move(185, 357, 420, 42)
        statusText.Move(185, 414, 420, 62)
        main.Show("w640")
    } else {
        sidebar.Move(0, 72, 64, 430)
        toggleBtn.Move(15, 82, 34, 32)
        captureTab.Move(12, 132, 40, 40)
        fileTab.Move(12, 182, 40, 40)
        clipTab.Move(12, 232, 40, 40)
        saveTab.Move(12, 282, 40, 40)
        toggleBtn.Text := "›"
        categoryBox.Move(100, 105, 470)
        nameBox.Move(100, 150, 470)
        captureBtn.Move(100, 205, 470, 38)
        chooseBtn.Move(100, 253, 470, 38)
        clipBtn.Move(100, 301, 470, 38)
        saveBtn.Move(100, 357, 470, 42)
        statusText.Move(100, 414, 470, 62)
        main.Show("w650")
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
