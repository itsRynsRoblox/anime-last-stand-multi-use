#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Event"

global scriptInitialized := false

; === Testing and Debugging ===
#Include %A_ScriptDir%/lib/Toggles.ahk

; === Main Script ===
#Include %A_ScriptDir%/lib/GUI.ahk
#Include %A_ScriptDir%/lib/GameMango.ahk

; === Saving and Loading Configs ===
#Include %A_ScriptDir%/lib/Config.ahk

; === Tool Libraries ===
#Include %A_ScriptDir%/lib/Tools/FindText.ahk
#Include %A_ScriptDir%/lib/Tools/Image.ahk

; === Game Modes ===
#Include %A_ScriptDir%/lib/Modes/BossRush.ahk
#Include %A_ScriptDir%/lib/Modes/Caverns.ahk
#Include %A_ScriptDir%/lib/Modes/Challenges.ahk
#Include %A_ScriptDir%/lib/Modes/Dungeon.ahk
#Include %A_ScriptDir%/lib/Modes/Portal.ahk
#Include %A_ScriptDir%/lib/Modes/Story.ahk
#Include %A_ScriptDir%/lib/Modes/Survival.ahk

; === Limited Time Game Modes ===
#Include %A_ScriptDir%/lib/Modes/Halloween/HalloweenEvent.ahk
#Include %A_ScriptDir%/lib/Modes/Halloween/HalloweenCardManager.ahk

; === Core Mechanics ===
#Include %A_ScriptDir%/lib/Functions/Functions.ahk
#Include %A_ScriptDir%/lib/Functions/Upgrading.ahk
#Include %A_ScriptDir%/lib/Functions/WalkManager.ahk
#Include %A_ScriptDir%/lib/PlacementPatterns.ahk
#Include %A_ScriptDir%/lib/Functions/NukeManager.ahk
#Include %A_ScriptDir%/lib/Functions/CardManager.ahk

; === Webhook Integration ===
#Include %A_ScriptDir%/lib/WebhookSettings.ahk

global scriptInitialized := true