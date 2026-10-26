#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Event")
SetKeyDelay(20, 20)

; NectarX field -> hive starter.
; This uses Roblox's reset-character flow to try returning to the player's claimed hive.
; It does not identify hive slot by image and cannot guarantee the character will
; respawn at a hive if the game places the character on the global spawn platform.
; F8 aborts and releases keys.

global ReturnStopped := false
Hotkey("F8", EmergencyStop)
OnExit(ReturnCleanup)

hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
if !hwnd
    hwnd := WinExist("Roblox")
if !hwnd {
    MsgBox("Open Bee Swarm Simulator in Roblox first, then try again.", "NectarX — Return to Hive", "Icon!")
    ExitApp()
}

answer := MsgBox("Return to hive by resetting your character?" Chr(10) Chr(10) "This interrupts current movement and may briefly respawn you. Press F8 to abort.", "NectarX — Return to Hive", "YesNo Icon!")
if (answer != "Yes")
    ExitApp()

WinActivate("ahk_id " hwnd)
if !WinWaitActive("ahk_id " hwnd, , 3) {
    MsgBox("Could not activate Roblox. Click the game and try again.", "NectarX", "Icon!")
    ExitApp()
}

ToolTip("Returning to hive…  (F8 = cancel)")
if !WaitOrStop(300)
    ExitApp()
Send("{Esc}")
if !WaitOrStop(300)
    ExitApp()
Send("r")
if !WaitOrStop(300)
    ExitApp()
Send("{Enter}")
if !WaitOrStop(5000)
    ExitApp()
ToolTip()
MsgBox("Reset sequence finished. Check your character's location. If Roblox respawned you on the global spawn platform, use Spawn → Hive Slot 1 from the NectarX Routes tab.", "NectarX — Return to Hive", "Iconi")
ExitApp()

WaitOrStop(ms) {
    global ReturnStopped
    started := A_TickCount
    while (!ReturnStopped && A_TickCount - started < ms)
        Sleep(40)
    return !ReturnStopped
}

EmergencyStop(*) {
    global ReturnStopped
    ReturnStopped := true
    Send("{Esc up}{r up}{Enter up}{w up}{a up}{s up}{d up}")
    ToolTip()
}

ReturnCleanup(*) {
    ToolTip()
    Send("{Esc up}{r up}{Enter up}{w up}{a up}{s up}{d up}")
}
