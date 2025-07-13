#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

global scriptInitialized := false

SendMode "Event"

#Include %A_ScriptDir%/lib/Image.ahk
#Include %A_ScriptDir%/lib/GUI.ahk
#Include %A_ScriptDir%/lib/GameMango.ahk
#Include %A_ScriptDir%/lib/Functions.ahk
#Include %A_ScriptDir%/lib/Config.ahk
#Include %A_ScriptDir%/lib/Modes/Caverns.ahk
#Include %A_ScriptDir%/lib/Modes/Challenges.ahk
#Include %A_ScriptDir%/lib/Modes/Dungeon.ahk
#Include %A_ScriptDir%/lib/Modes/Portal.ahk
#Include %A_ScriptDir%/lib/Modes/Survival.ahk
#Include %A_ScriptDir%/lib/WebhookSettings.ahk
#Include %A_ScriptDir%/lib/PlacementPatterns.ahk
#Include %A_ScriptDir%/lib/FindText.ahk
#Include %A_ScriptDir%/lib/Toggles.ahk

global scriptInitialized := true