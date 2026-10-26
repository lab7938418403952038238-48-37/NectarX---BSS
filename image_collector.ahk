#Requires AutoHotkey v2.0
#SingleInstance Force

global RootDir := A_ScriptDir
global ImageRoot := RootDir "\NectarX images"
global ManifestPath := ImageRoot "\image_manifest.json"
global TempPath := A_Temp "\nectarx_capture.png"
global Categories := ["fields_landmarks", "tokens_flowers", "backpack_pollen", "hive_conversion", "movement_travel", "npcs_quests", "bees_abilities", "planters", "menus_ui", "other"]
global CurrentImage := ""

main := Gui(, "NectarX — Image Collector (AHK v2)")
main.SetFont("s10", "Segoe UI")
main.AddText("w470", "NectarX Image Collector")
main.AddText("w470 c666666", "Capture or choose real Bee Swarm Simulator screenshots and label them.")
main.AddText("xm y+14", "Category")
categoryBox := main.AddDropDownList("xm y+5 w470 Choose1", Categories)
main.AddText("xm y+12", "Image name (example: field_clover)")
nameBox := main.AddEdit("xm y+5 w470")
captureBtn := main.AddButton("xm y+14 w470 h32", "1. Capture full screen")
chooseBtn := main.AddButton("xm y+7 w470 h32", "2. Choose screenshot file")
clipBtn := main.AddButton("xm y+7 w470 h32", "3. Save image from clipboard")
saveBtn := main.AddButton("xm y+14 w470 h36 Default", "Save image to library")
statusText := main.AddText("xm y+12 w470 h48 c555555", "Images save locally to: " ImageRoot)
main.AddText("xm y+3 w470 c666666", "Tip: use Win+Shift+S to crop a region, then click 'Save image from clipboard'.")
captureBtn.OnEvent("Click", CaptureScreen)
chooseBtn.OnEvent("Click", ChooseImage)
clipBtn.OnEvent("Click", SaveClipboardImage)
saveBtn.OnEvent("Click", SaveImage)
main.OnEvent("Close", (*) => ExitApp())
main.Show()

CaptureScreen(*) {
    global TempPath, CurrentImage, nameBox, statusText
    statusText.Text := "Capturing screen..."
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
        statusText.Text := "Screen captured. Enter a descriptive name, then save."
    } catch as err {
        MsgBox("Capture failed:`n" err.Message, "NectarX", "Iconx")
        statusText.Text := "Capture failed."
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
    statusText.Text := "Selected: " file
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
        statusText.Text := "Clipboard image ready. Enter a name, then save."
    } catch as err {
        MsgBox(err.Message, "NectarX", "Iconx")
        statusText.Text := "Clipboard capture failed."
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
        statusText.Text := "Saved " relativePath
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
