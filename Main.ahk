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
#Include %A_ScriptDir%\Lib\OCR-main\Lib\OCR.ahk
#Include Lib\RapidOcr\ImagePut.ahk
#Include %A_ScriptDir%/lib/Tools/RapidOcr.ahk
#Include %A_ScriptDir%/lib/Tools/jsongo.v2.ahk

; === Game Modes ===
#Include %A_ScriptDir%/lib/Modes/BossRush.ahk
#Include %A_ScriptDir%/lib/Modes/Caverns.ahk
#Include %A_ScriptDir%/lib/Modes/Challenges.ahk
#Include %A_ScriptDir%/lib/Modes/Dungeon.ahk
#Include %A_ScriptDir%/lib/Modes/Portal.ahk
#Include %A_ScriptDir%/lib/Modes/Story.ahk
#Include %A_ScriptDir%/lib/Modes/Survival.ahk
#Include %A_ScriptDir%/lib/Modes/Raid.ahk
#Include %A_ScriptDir%/lib/Modes/Siege.ahk

; === Limited Time Game Modes ===
#Include %A_ScriptDir%/lib/Modes/Limited/Events.ahk
#Include %A_ScriptDir%/lib/Modes/Limited/HalloweenEvent.ahk

; === Core Mechanics ===
#Include %A_ScriptDir%/lib/Functions/Functions.ahk
#Include %A_ScriptDir%/lib/Functions/Upgrading.ahk
#Include %A_ScriptDir%/lib/Functions/UnitPlacement.ahk
#Include %A_ScriptDir%/lib/Functions/AutoAbilityManager.ahk
#Include %A_ScriptDir%/lib/Functions/WalkManager.ahk
#Include %A_ScriptDir%/lib/PlacementPatterns.ahk
#Include %A_ScriptDir%/lib/Functions/NukeManager.ahk
#Include %A_ScriptDir%/lib/Functions/CardManager.ahk
#Include %A_ScriptDir%/lib/Functions/TimerManager.ahk
#Include %A_ScriptDir%/lib/Functions/CustomPlacements.ahk
#Include %A_ScriptDir%/lib/Functions/ProfileManager.ahk
#Include %A_ScriptDir%/lib/Functions/CustomRecording.ahk

; === Update Checker ===
#Include %A_ScriptDir%/lib/Functions/UpdateChecker.ahk

; === Webhook Integration ===
#Include %A_ScriptDir%/lib/WebhookSettings.ahk

global scriptInitialized := true