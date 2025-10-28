#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%/Lib/Tools/Image.ahk
#Include %A_ScriptDir%/Lib/Functions/Functions.ahk

; Application Info
global GameName := "Anime Last Stand"
global GameTitle := "Ryn's " GameName " Macro "
global version := "v1.8.4"
global rblxID := "ahk_exe RobloxPlayerBeta.exe"
; Update Checker
global repoOwner := "itsRynsRoblox"
global repoName := "anime-last-stand-multi-use"
;Coordinate and Positioning Variables
global targetWidth := 816
global targetHeight := 638
global offsetX := -5
global offsetY := 1
global centerX := 408
global centerY := 320
global successfulCoordinates := []
global totalUnits := Map()
;Statistics Tracking
global mode := ""
global StartTime := A_TickCount
global currentTime := GetCurrentTime()
; Config and Settings
global UnitConfigMap := Map()
;Auto Challenge
global challengeStartTime := A_TickCount
global inChallengeMode := false
global firstStartup := true
; Testing
global waitingState := Map()
;Custom Unit Placement
global waitingForClick := false
global savedCoords := Map()
; Custom Walk
global recording := false
global allWalks := Map()
global keyDownTimes := Map()
global lastActionTime := 0
;Nuke Ability
global nukeCoords := { x: 282, y: 291 }
;Hotkeys
global F1Key := "F1"
global F2Key := "F2"
global F3Key := "F3"
global F4Key := "F4"
;Gui creation
global uiBorders := []
global uiBackgrounds := []
global uiTheme := []
global UnitData := []
global MainUI := Gui("+AlwaysOnTop -Caption")
global CardGUI := Gui("+AlwaysOnTop")
global lastlog := ""
global MainUIHwnd := MainUI.Hwnd
global ActiveControlGroup := ""
global ControlGroups := Map()
;Theme colors
uiTheme.Push("0xffffff")  ; Header color
uiTheme.Push("0c000a")  ; Background color
uiTheme.Push("0xffffff")    ; Border color
uiTheme.Push("0c000a")  ; Accent color
uiTheme.Push("0x3d3c36")   ; Trans color
uiTheme.Push("000000")    ; Textbox color
;uiTheme.Push("00ffb3") ; HighLight
uiTheme.Push("00a2ff") ; HighLight
;Logs/Save settings
global currentOutputFile := A_ScriptDir "\Logs\LogFile.txt"
;Custom Pictures
GithubImage := "Images\github-logo.png"
DiscordImage := "Images\another_discord.png"

if !DirExist(A_ScriptDir "\Logs") {
    DirCreate(A_ScriptDir "\Logs")
}
if !DirExist(A_ScriptDir "\Settings") {
    DirCreate(A_ScriptDir "\Settings")
}

setupOutputFile()

; === Need To Load These Before GUI ===
global currentCardMode := "Boss Rush"
global CardModeConfigs := Map(
    "Boss Rush", Map(
        "modeName", "BossRush",
        "title", "Boss Rush Card Priority",
        "filePath", "Settings\BossRushCardPriority.txt",
        "options", [
            "Immolation",
            "Enraged",
            "Loyalty",
            "Initiative",
            "MetalSkin",
            "WeakPoint",
            "Reconnaissance",
            "Ambush",
            "Insanity",
            "Godspeed",
            "Avarice",
            "Opulence",
            "Sluggish",
            "DemonTakeover",
            "ChaosEater",
            "Fortune",
            "RagingPower",
            "FeelingMadness",
            "EmotionalDamage"
        ]
    ),
    "Halloween", Map(
        "modeName", "Halloween",
        "title", "Halloween Card Priority",
        "filePath", "Settings\HalloweenCardPriority.txt",
        "options", [
            "TrickorTreat",
            "ScorchingHell",
            "WeakenedResolve",
            "FierySurge",
            "HellMerchant",
            "FortuneFlow",
            "PowerReversal",
            "GrievousWounds",
            "FogofWar",
            "BulletBreaker",
            "GreedyVampires",
            "SeethingBloodlust",
            "LingeringFear",
            "HellishWarp",
            "HellishGravity",
            "CriticalDenial",
            "DeadlyStriker",
            "SoulLink",
            "DevilsSacrifice"
        ]
    )
)

global currentConfig := CardModeConfigs[currentCardMode]

; ========== Constants and Theme Setup ==========
mainWidth := 1364
mainHeight := 697
robloxWidth := 802
uiColors := Map(
    "Primary", uiTheme[1],
    "Background", uiTheme[2],
    "Border", uiTheme[3],
    "RobloxBox", uiTheme[5],
    "ProcessHighlight", uiTheme[7]
)

; ========== Helper Functions ==========
AddUI(type, options, text := "", onClickFunc := unset) {
    ctrl := MainUI.Add(type, options, text)
    if IsSet(onClickFunc)
        ctrl.OnEvent("Click", onClickFunc)
    return ctrl
}

AddBorder(x, y, w, h) {
    return MainUI.Add("Text", Format("x{} y{} w{} h{} +Background{}", x, y, w, h, uiColors["Border"]))
}
; ========== GUI Initialization ==========

MainUI.BackColor := uiColors["Background"]
global Webhookdiverter := AddUI("Edit", "x0 y0 w1 h1 +Hidden")

; ========== Borders ==========
uiBorders.Push(AddBorder(0, 0, mainWidth, 1))                          ; Top
uiBorders.Push(AddBorder(0, 0, 1, mainHeight))                         ; Left
uiBorders.Push(AddBorder(mainWidth - 1, 0, 1, 630))                    ; Right
uiBorders.Push(AddBorder(mainWidth - 1, 0, 1, mainHeight))            ; Full Right
uiBorders.Push(AddBorder(0, 30, mainWidth - 1, 1))                     ; Under Title
uiBorders.Push(AddBorder(803, 443, 560, 1))                            ; Placement Bottom
uiBorders.Push(AddBorder(803, 527, 560, 1))                            ; Process Bottom
uiBorders.Push(AddBorder(802, 30, 1, 667))                             ; Roblox Right
uiBorders.Push(AddBorder(0, mainHeight - 1, mainWidth, 1))            ; Bottom Line
uiBorders.Push(AddBorder(0, 630, robloxWidth + 0.5, 1))               ; Game Bottom

; ========== Backgrounds ==========
uiBackgrounds.Push(MainUI.Add("Text", Format("x3 y3 w{} h27 +Background{}", mainWidth - 4, uiColors["Background"])))

; ========== Roblox Window Area ==========
global robloxHolder := MainUI.Add("Text", Format("x3 y33 w797 h597 +Background{}", uiColors["RobloxBox"]), "")

; ========== Exit and Minimize Buttons ==========
global exitButton := AddUI("Picture", "x1330 y1 w32 h32 +BackgroundTrans", Exitbutton, (*) => Destroy())
global minimizeButton := AddUI("Picture", "x1305 y3 w27 h27 +Background" uiColors["Background"], Minimize, (*) => minimizeUI())

; ========== Import ==========
global importUnitConfigButton := AddUI("Picture", "x1312 y48 w20 h20 +BackgroundTrans", Import, (*) => ImportSettingsFromFile())
global exportUnitConfigButton := AddUI("Picture", "x1337 y48 w20 h20 +BackgroundTrans", Export, (*) => ExportUnitConfig())

; ========== Title ==========
MainUI.SetFont("Bold s16 c" uiColors["Primary"], "Verdana")
global windowTitle := MainUI.Add("Text", "x10 y3 w1200 h29 +BackgroundTrans", GameTitle "" . "" version)

; ========== Console Label ==========
MainUI.Add("Text", "x805 y501 w558 h25 +Center +BackgroundTrans", "Console")
uiBorders.Push(AddBorder(803, 499, 560, 1)) ; Console Top Border

; ========== Process Text Lines ==========
MainUI.SetFont("norm s11 c" uiColors["Primary"])
global processList := []
baseY := 536

loop 7 {
    yOffset := (A_Index - 1) * 22
    text := ""
    color := uiColors["Primary"]
    if A_Index = 1 {
        text := "➤ Original Creator: Ryn (@TheRealTension)"
        color := uiColors["ProcessHighlight"]
    }
    process := MainUI.Add("Text", Format("x810 y{} w538 h18 +BackgroundTrans c{}", baseY + yOffset, color), text)
    processList.Push(process)
}

; ========== Transparency ==========
WinSetTransColor(uiColors["RobloxBox"], MainUI)

OpenGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop")
    GuideGUI.SetFont("s10 bold", "Segoe UI")
    GuideGUI.Title := "Ryn's " GameName " Guide"

    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Add Guide content
    GuideGUI.SetFont("s16 bold", "Segoe UI")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center", "1 - In your ROBLOX settings, make sure your graphics are set to 1")
    GuideGUI.Add("Picture", "x50 w700   cWhite +Center", "Images\graphics1.png")
    GuideGUI.Show("w800")
}

OpenPrivateServerGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop +Resize", "Ryn's Private Server Guide")
    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Reset font for steps
    GuideGUI.SetFont("s12 bold", "Segoe UI")

    ; Add each step individually
    GuideGUI.Add("Text", "cWhite", "Step 1. Create a private server")
    GuideGUI.Add("Text", "cWhite", "Step 2. Name the server however you like")
    GuideGUI.Add("Text", "cWhite", "Step 3. Configure the private server")
    GuideGUI.Add("Text", "cWhite", "Step 4. Generate a link for the server")
    GuideGUI.Add("Text", "cWhite", "Step 5. Paste the link into your browser")
    GuideGUI.Add("Text", "cWhite", "Step 6. Wait for the link to change into the new version")
    GuideGUI.Add("Text", "cWhite", "Step 7. Copy the URL")
    GuideGUI.Add("Text", "cWhite", "Step 8. Paste the URL into the private server section of the macro")
    GuideGUI.Add("Text", "cWhite", "It should look like this at the end: privateServerLinkCode=12345")

    ; Show GUI
    GuideGUI.Show("AutoSize Center")
}

MainUI.SetFont("s9 Bold c" uiTheme[1])

ActiveConfigurationText:= MainUI.Add("Text", "x840 y7 +Center c" uiTheme[1], "Active Configuration: ")
ConfigurationDropdown := MainUI.Add("DropDownList", "x990 y4.5 w110 h180 +Center Choose1", ["Unit", "Cards", "Map Movement", "Mode", "Nuke", "Upgrade"])
ConfigurationDropdown.OnEvent("Change", UpdateActiveConfiguration)

global guideBtn := MainUI.Add("Button", "x1108 y5 w90 h20", "Guide")
guideBtn.OnEvent("Click", OpenGuide)

global settingsBtn := MainUI.Add("Button", "x1208 y5 w90 h20", "Settings")
settingsBtn.OnEvent("Click", (*) => ToggleControlGroup("Settings"))

placementSaveBtn := MainUI.Add("Button", "x807 y471 w80 h20", "Save")
placementSaveBtn.OnEvent("Click", SaveSettingsForMode)

MainUI.SetFont("s9")

global NextLevelBox := MainUI.Add("Checkbox", "x900 y451 cffffff", "Next Level")
global ReturnLobbyBox := MainUI.Add("Checkbox", "x1150 y476 cffffff Checked", "Return To Lobby")

global AutoAbilityBox := MainUI.Add("CheckBox", "x1005 y451 cffffff Checked", "Auto Ability")
global AutoAbilityText := MainUI.Add("Text", "x1125 y451 c" uiTheme[1], "Auto Ability Timer:")
global AutoAbilityTimer := MainUI.Add("Edit", "x1255 y449 w60 h20 cBlack Number", "60")

global SeamlessToggle := MainUI.Add("CheckBox", "x900 y476 cffffff", "Using Seamless Replay")

PlacementPatternText := MainUI.Add("Text", "x815 y390 w125 h20", "Placement Pattern")
global PlacementPatternDropdown := MainUI.Add("DropDownList", "x825 y410 w100 h180 Choose2 +Center", ["Circle", "Custom", "Grid", "3x3 Grid", "Spiral", "Up and Down", "Random"])

PlaceSpeedText := MainUI.Add("Text", "x1030 y390 w115 h20", "Placement Speed")
global PlaceSpeed := MainUI.Add("DropDownList", "x1035 y410 w100 h180 Choose3 +Center", ["Super Fast (1s)", "Fast (1.5s)", "Default (2s)", "Slow (2.5s)", "Very Slow (3s)", "Toaster (4s)"])

PlacementSelectionText := MainUI.Add("Text", "x1235 y390 w125 h20", "Placement Order")
global PlacementSelection := MainUI.Add("DropDownList", "x1240 y410 w100 h180 Choose1 +Center", ["Default", "By Priority", "Slot #2 First"])

;=== Card Config GUI ===
global CardBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Card Priority")

global BossRushCardText := MainUI.Add("Text", "x825 y110 Hidden cffffff", "Boss Rush Cards: ")
global BossRushCardButton := MainUI.Add("Button", "x975 y108 w80 h20 Hidden cffffff", "Edit Cards")
BossRushCardButton.OnEvent("Click", (*) => SwitchCardMode("Boss Rush"))

global HalloweenCardText := MainUI.Add("Text", "x825 y140 Hidden cffffff", "Halloween Cards: ")
global HalloweenCardButton := MainUI.Add("Button", "x975 y138 w80 h20 Hidden cffffff", "Edit Cards")
HalloweenCardButton.OnEvent("Click", (*) => SwitchCardMode("Halloween"))

;=== Custom Walk GUI ===
global CustomWalkBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden" uiTheme[1], "Custom Walk Configuration")
global WalkMapText := MainUI.Add("Text", "x875 y110 Hidden cffffff", "Map:")
global WalkMapDropdown := MainUI.Add("DropDownList", "x915 y108 w200 h180 Choose1 +Center Hidden", [
    "Custom",
    "Halloween",
    "Halloween P2",
    ;=== World 2 Story ===
    "Hog Town",
    "Hollow Night Palace",
    "Firefighter's Base",
    "Demon Skull Village",
    "Shibuya",
    "Abandoned Cathedral",
    "Morioh",
    "Soul Society",
    "Thriller Bark",
    "Dragon Heaven",
    "Ryudou Temple",
    "Snowy Village",
    "Rain Village",
    "Giants District (Forest)",
    "Oni Island",
    "Unknown Planet",
    "Oasis",
    "Harge Forest",
    "Babylon",
    "Destroyed Shinjuku",
    "Train Station",
    "Swordsmith Village",
    "Sacrificial Realm",
    "The Hollowlands",
    "NYC Rooftop",
    "Laboratory 5",
    "Sector 7",
    ;=== Raids ===
    "Marines Fort",
    "Hell City",
    "Snowy Capital",
    "Tokyo City",
    "Leaf Village",
    "Wanderniech",
    "Central City",
    "Giants District",
    "Flying Island",
    "U-18",
    "Flower Garden",
    "Ancient Dungeon",
    "Shinjuku Crater",
    "Valhalla Arena",
    "Frozen Planet",
    "Blossom Church",
    "Science Sanctuary",
    "Menos Forest",
    "Tokyo City",
    ;=== Dungeons ===
    "Monarch's Dungeon",
    "Infernal Dungeon",
    "Devil's Dungeon",
    "Corpse Dungeon",
    "Koi Pond Dungeon",
    ;=== Survivals ===;
    "Villain Invasion",
    "Holy Invasion",
    "Hell Invasion",
    "Pirate Invasion",
    "Soul Society",
    ;=== Sieges ===
    "Alchemy Siege",
    "Ninja Siege"
])
MovementSetButton := MainUI.Add("Button", "x1130 y110 w60 h20 Hidden", "Set")
MovementSetButton.OnEvent("Click", StartRecordingWalk)
MovementClearButton := MainUI.Add("Button", "x1205 y110 w60 h20 Hidden", "Clear")
MovementClearButton.OnEvent("Click", ClearMovement)
MovementTestButton := MainUI.Add("Button", "x1280 y110 w60 h20 Hidden", "Test")
MovementTestButton.OnEvent("Click", (*) => StartWalk(true))
MovementImport := MainUI.Add("Picture", "x820 y108 w20 h20 +BackgroundTrans Hidden", Import)
MovementImport.OnEvent("Click", (*) => ImportMovements())
MovementExport := MainUI.Add("Picture", "x845 y108 w20 h20 +BackgroundTrans Hidden", Export)
MovementExport.OnEvent("Click", (*) => ExportMovements(WalkMapDropdown.Text))

; === Custom Placement Settings ===
global CustomSettings := MainUI.Add("GroupBox", "x190 y632 w605 h60 +Center c" uiTheme[1], "Custom Placement Settings")
PlacementSettingsImportButton := AddUI("Picture", "x200 y652 w27 h27 +BackgroundTrans", Import, (*) => ImportCustomCoords())
PlacementSettingsExportButton := AddUI("Picture", "x235 y652 w27 h27 +BackgroundTrans", Export, (*) => ExportCustomCoords(CustomPlacementMapDropdown.Text))
CustomPlacementMap := MainUI.Add("Text", "x275 y655 w60 h20 +Left", "Map:")
global CustomPlacementMapDropdown := MainUI.Add("DropDownList", "x310 y653 w180 h200 Choose1 +Center", [
    "Custom",
    "Halloween",
    "Halloween P2",
    ;=== World 2 Story ===
    "Hog Town",
    "Hollow Night Palace",
    "Firefighter's Base",
    "Demon Skull Village",
    "Shibuya",
    "Abandoned Cathedral",
    "Morioh",
    "Soul Society",
    "Thriller Bark",
    "Dragon Heaven",
    "Ryudou Temple",
    "Snowy Village",
    "Rain Village",
    "Giants District (Forest)",
    "Oni Island",
    "Unknown Planet",
    "Oasis",
    "Harge Forest",
    "Babylon",
    "Destroyed Shinjuku",
    "Train Station",
    "Swordsmith Village",
    "Sacrificial Realm",
    "The Hollowlands",
    "NYC Rooftop",
    "Laboratory 5",
    "Sector 7",

    ;=== Raids ===
    "Marines Fort",
    "Hell City",
    "Snowy Capital",
    "Tokyo City",            
    "Leaf Village",
    "Wanderniech",
    "Central City",
    "Giants District",
    "Flying Island",
    "U-18",
    "Flower Garden",
    "Ancient Dungeon",
    "Shinjuku Crater",
    "Valhalla Arena",
    "Frozen Planet",
    "Blossom Church",
    "Science Sanctuary",
    "Menos Forest",
    "Tokyo City",

    ;=== Dungeons ===
    "Monarch's Dungeon",
    "Infernal Dungeon",
    "Devil's Dungeon",
    "Corpse Dungeon",
    "Koi Pond Dungeon",

    ;=== Survivals ===;
    "Villain Invasion",
    "Holy Invasion",
    "Hell Invasion",
    "Pirate Invasion",
    "Soul Society",

    ;=== Sieges ===
    "Alchemy Siege",
    "Ninja Siege"
])

CustomPlacementButton := MainUI.Add("Button", "x495 y655 w85 h20", "Set")
CustomPlacementButton.OnEvent("Click", (*) => StartCoordinateCapture())
CustomPlacementClearButton := MainUI.Add("Button", "x595 y655 w85 h20", "Clear")
CustomPlacementClearButton.OnEvent("Click", (*) => DeleteCustomCoordsForPreset(CustomPlacementMapDropdown.Text))
fixCameraButton := MainUI.Add("Button", "x695 y655 w85 h20", "Fix Camera")
fixCameraButton.OnEvent("Click", (*) => BasicSetup(true))
; === End of Custom Placement Settings ===

; === Event Configuration ===
global EventBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Event Configuration")
global HalloweenRestart := MainUI.Add("Checkbox", "x825 y110 Hidden cffffff", "Restart Halloween on wave: " )
global HalloweenRestartTimer := MainUI.Add("Edit", "x1060 y108 Hidden w45 h20 Hidden cBlack Number", "80")

placementSaveText := MainUI.Add("Text", "x807 y451 w80 h20", "Save Config")
Hotkeytext := MainUI.Add("Text", "x807 y35 w200 h30", F1Key ": Fix Roblox Position")
Hotkeytext2 := MainUI.Add("Text", "x807 y50 w200 h30", F2Key ": Start Macro")
Hotkeytext3 := MainUI.Add("Text", "x807 y65 w200 h30", F3Key ": Stop Macro")
GithubButton := MainUI.Add("Picture", "x30 y640", GithubImage)
DiscordButton := MainUI.Add("Picture", "x112 y645 w60 h34 +BackgroundTrans cffffff", DiscordImage)
; === End of Custom Walk Settings ===

; === Settings GUI ===
global WebhookBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Webhook Settings")
global WebhookEnabled := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Webhook Enabled")
WebhookEnabled.OnEvent("Click", (*) => ValidateWebhook())
global WebhookLogsEnabled := MainUI.Add("CheckBox", "x825 y130 Hidden cffffff", "Send Console Logs")
global WebhookURLBox := MainUI.Add("Edit", "x1000 y108 w260 h20 Hidden c" uiTheme[6], "")

global PrivateSettingsBorder := MainUI.Add("GroupBox", "x808 y145 w550 h296 +Center Hidden c" uiTheme[1], "Reconnection Settings")
global PrivateServerEnabled := MainUI.Add("CheckBox", "x825 y165 Hidden cffffff", "Reconnect to Private Server")
global PrivateServerURLBox := MainUI.Add("Edit", "x1050 y163 w160 h20 Hidden c" uiTheme[6], "")
PrivateServerTestButton := MainUI.Add("Button", "x1225 y163 w50 h20 Hidden", "Test")
PrivateServerTestButton.OnEvent("Click", (*) => Reconnect(true))
PrivateServerGuideButton := MainUI.Add("Button", "x1285 y163 w50 h20 Hidden", "Guide")
PrivateServerGuideButton.OnEvent("Click", OpenPrivateServerGuide)
global TeleportFailsafe := MainUI.Add("CheckBox", "x825 y185 Hidden cffffff", "Enable Teleport Failsafe")
global TeleportFailsafeTimerText := MainUI.Add("Text", "x1050 y188 h20 Hidden c" uiTheme[1], "Time until reconnect:")
global TeleportFailsafeTimer := MainUI.Add("Edit", "x1195 y186 w50 h20 Hidden Number c" uiTheme[6], "60")
; === End of Settings GUI ===

; HotKeys
global KeybindBorder := MainUI.Add("GroupBox", "x808 y205 w195 h176 +Center Hidden c" uiTheme[1], "Keybind Settings")
global F1Text := MainUI.Add("Text", "x825 y230 Hidden c" uiTheme[1], "Position Roblox:")
global F1Box := MainUI.Add("Edit", "x950 y228 w30 h20 Hidden c" uiTheme[6], F1Key)
global F2Text := MainUI.Add("Text", "x825 y260 Hidden c" uiTheme[1], "Start Macro:")
global F2Box := MainUI.Add("Edit", "x950 y258 w30 h20 Hidden c" uiTheme[6], F2Key)
global F3Text := MainUI.Add("Text", "x825 y290 Hidden c" uiTheme[1], "Stop Macro:")
global F3Box := MainUI.Add("Edit", "x950 y288 w30 h20 Hidden c" uiTheme[6], F3Key)
global F4Text := MainUI.Add("Text", "x825 y320 Hidden c" uiTheme[1], "Pause Macro:")
global F4Box := MainUI.Add("Edit", "x950 y318 w30 h20 Hidden c" uiTheme[6], F4Key)

keybindSaveBtn := MainUI.Add("Button", "x880 y350 w50 h20 Hidden", "Save")
keybindSaveBtn.OnEvent("Click", SaveKeybindSettings)

global UpgradeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Upgrade Settings")
global UnitManagerUpgradeSystem := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Use the Unit Manager to upgrade your units")
global PriorityUpgrade := MainUI.Add("CheckBox", "x825 y130 cffffff Hidden", "Use Unit Priority while Upgrading/Auto Upgrading")

global ZoomSettingsBorder := MainUI.Add("GroupBox", "x1000 y205 w165 h176 +Center Hidden c" uiTheme[1], "Zoom Tech Settings")
global ZoomText := MainUI.Add("Text", "x1018 y230 Hidden c" uiTheme[1], "Zoom Level:")
global ZoomBox := MainUI.Add("Edit", "x1115 y228 w30 h20 Hidden cBlack Number", "20")
global ZoomTech := MainUI.Add("Checkbox", "x1018 y260 Hidden Checked c" uiTheme[1], "Enable Zoom Tech")
global ZoomInOption := MainUI.Add("Checkbox", "x1018 y290 Hidden Checked c" uiTheme[1], "Zoom in then out")
global ZoomTeleport := MainUI.Add("Checkbox", "x1018 y320 Hidden Checked c" uiTheme[1], "Teleport to spawn")
ZoomBox.OnEvent("Change", (*) => ValidateEditBox(ZoomBox))

global MiscSettingsBorder := MainUI.Add("GroupBox", "x1163 y205 w195 h176 +Center Hidden c" uiTheme[1], "Update Settings")
global UpdateChecker := MainUI.Add("Checkbox", "x1175 y230 Hidden cffffff Checked", "Enable update checker")

global ModeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Mode Configuration")
global ModeConfigurations := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Enable Per-Mode Unit Settings")

global StoryBorder := MainUI.Add("GroupBox", "x808 y85 w550 h220  +Center Hidden c" uiTheme[1], "Story Settings")
global NightmareDifficulty := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Nightmare Difficulty")

global PortalBorder := MainUI.Add("GroupBox", "x808 y255 w550 h126 +Center Hidden c" uiTheme[1], "Portal Settings")
global PortalLobby := MainUI.Add("CheckBox", "x825 y280 Hidden cffffff", "Starting portal from the lobby")


; === Unit Config GUI ===
global NukeBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden" uiTheme[1], "Nuke Configuration")
global NukeUnitSlotEnabled := MainUI.Add("Checkbox", "x825 y113 Hidden Choose1 cffffff Checked", "Nuke Unit | Slot")
global NukeUnitSlot := MainUI.Add("DropDownList", "x960 y110 w100 h180 Hidden Choose1", ["1", "2", "3", "4", "5", "6"])
global NukeCoordinatesText := MainUI.Add("Text", "x1080 y113 Hidden cffffff", "Nuke Ability Coordinates")
global NukeCoordinatesButton := MainUI.Add("Button", "x1260 y110 w80 h20 Hidden", "Set")
NukeCoordinatesButton.OnEvent("Click", (*) => StartNukeCapture())
global NukeAtSpecificWave := MainUI.Add("Checkbox", "x825 y140 Hidden Choose1 cffffff Checked", "Nuke At Wave | Wave")
global NukeWave := MainUI.Add("DropDownList", "x1000 y137 w100 h180 Hidden Choose1", ["15", "20", "50"])
global NukeDelayText := MainUI.Add("Text", "x1120 y140 Hidden cffffff", "Nuke Delay")
global NukeDelay := MainUI.Add("Edit", "x1210 y138 w40 h20 Hidden cBlack Number", "0")
NukeDelay.OnEvent("Change", (*) => ValidateEditBox(NukeDelay))

; === Disbled At The Moment ===
global SJWNuke := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Use SJW Nuke")
global SJWSlotText := MainUI.Add("Text", "x825 y130 Hidden cffffff", "SJW Slot")
global SJWSlot := MainUI.Add("DropDownlist", "x905 y128 w45 Hidden Choose0 +Center", ["1", "2", "3", "4", "5", "6"])
; === End of Disabled At The Moment ===

global UnitBorder := MainUI.Add("GroupBox", "x808 y161 w550 h220 +Center Hidden" uiTheme[1], "Unit Manager Fixes")
global MinionSlot1 := MainUI.Add("CheckBox", "x825 y181 cffffff Hidden", "Slot 1 has minion")
global MinionSlot2 := MainUI.Add("CheckBox", "x1015 y181 cffffff Hidden", "Slot 2 has minion")
global MinionSlot3 := MainUI.Add("CheckBox", "x1200 y181 cffffff Hidden", "Slot 3 has minion")
global MinionSlot4 := MainUI.Add("CheckBox", "x825 y206 cffffff Hidden", "Slot 4 has minion")
global MinionSlot5 := MainUI.Add("CheckBox", "x1015 y206 cffffff Hidden", "Slot 5 has minion")
global MinionSlot6 := MainUI.Add("CheckBox", "x1200 y206 cffffff Hidden", "Slot 6 has minion")
; === End Unit Config GUI ===

GithubButton.OnEvent("Click", (*) => OpenGithub())
DiscordButton.OnEvent("Click", (*) => OpenDiscord())
;--------------SETTINGS--------------;
global modeSelectionGroup := MainUI.Add("GroupBox", "x808 y38 w500 h45 +Center Background" uiTheme[2], "Game Mode Selection")
MainUI.SetFont("s10 c" uiTheme[6])
global ModeDropdown := MainUI.Add("DropDownList", "x818 y53 w140 h180 Choose0 +Center", ["Story", "Boss Rush", "Dungeon", "Event", "Portal", "Raid", "Siege", "Survival", "Custom"])
global EventDropdown:= MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Halloween", "Halloween P2"])
global StoryDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Hog Town", "Hollow Night Palace", "Firefighters Base", "Demon Skull Village", "Shibuya", "Abandoned Cathedral", "Moriah", "Soul Society", "Thrilled Bark", "Dragon Heaven", "Ryuudou Temple", "Snowy Village", "Rain Village", "Giant's District", "Oni Island", "Unknown Planet", "Oasis", "Harge Forest", "Babylon", "Destroyed Shinjuku", "Train Station", "Swordsmith Village", "Sacrifical Realm", "The Hollowlands", "NYC Rooftop", "Laboratory 5", "Sector 7"])
global StoryActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6", "Infinite"])
global LegendDropDown := MainUI.Add("DropDownlist", "x968 y53 w150 h180 Choose0 +Center", ["Legend Stage #1"] )
;global LegendActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3"])
global RaidDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center", ["Marines Fort", "Hell City", "Snowy Capital", "Leaf Village", "Wanderniech", "Central City", "Giants District", "Flying Island", "U-18", "Flower Garden", "Ancient Dungeon", "Shinjuku Crater", "Valhalla Arena", "Frozen Planet", "Blossom Church", "Science Sanctuary", "Menos Forest"])
global RaidActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6"])
global DungeonDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Koi Pond Dungeon", "Corpse Dungeon", "Devil's Dungeon", "Infernal Dungeon", "Monarch's Dungeon"])
global PortalDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Demon Place", "Gate", "Soul King Palace", "Summer Laguna"])
global PortalRoleDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Host", "Guest"])
global BossRushDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Ninja Rush", "Mana Rush", "Grail Rush", "Titan Rush", "Godly Rush"])
global SiegeDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Ninja Siege", "Alchemy Siege"])
global SurvivalDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Soul Society", "Pirate Invasion", "Hell Invasion", "Holy Invasion", "Villain Invasion"])
global ConfirmButton := MainUI.Add("Button", "x1218 y53 w80 h25", "Confirm")


LegendDropDown.Visible := false
RaidDropdown.Visible := false
RaidActDropdown.Visible := false
ReturnLobbyBox.Visible := false
Hotkeytext.Visible := false
Hotkeytext2.Visible := false
Hotkeytext3.Visible := false
ModeDropdown.OnEvent("Change", OnModeChange)
StoryDropdown.OnEvent("Change", OnStoryChange)
LegendDropDown.OnEvent("Change", OnLegendChange)
RaidDropdown.OnEvent("Change", OnRaidChange)
PlacementPatternDropdown.OnEvent("Change", OnPlacementChange)
ConfirmButton.OnEvent("Click", OnConfirmClick)
;------MAIN UI------;

;------UNIT CONFIGURATION------UNIT CONFIGURATION------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/

AddUnitCard(MainUI, index, x, y) {
    unit := {}

    ; Helper for adding styled text
    AddText(ctrlX, ctrlY, width, height, options := "", text := "") {
        return MainUI.Add("Text", Format("x{} y{} w{} h{} {}", ctrlX, ctrlY, width, height, options), text)
    }

    ; Background and borders
    unit.Background     := AddText(x, y, 550, 45, "+Background" uiTheme[4])
    unit.BorderTop      := AddText(x, y, 550, 2, "+Background" uiTheme[3])
    unit.BorderBottom   := AddText(x, y + 45, 552, 2, "+Background" uiTheme[3])
    unit.BorderLeft     := AddText(x, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight    := AddText(x + 550, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight2   := AddText(x + 250, y, 2, 45, "+Background" uiTheme[3])
    unit.BorderRight3 := AddText(x + 420, y, 2, 45, "+Background" uiTheme[3])

    ; Main Labels
    MainUI.SetFont("s11 Bold c" uiTheme[1])
    unit.EnabledTitle   := AddText(x + 30, y + 18, 60, 25, "+BackgroundTrans", "Unit " index)

    ; Unit Configuration
    MainUI.SetFont("s9 c" uiTheme[1])
    unit.PlacementText        := AddText(x + 90, y + 2, 80, 20, "+BackgroundTrans", "Placements")
    unit.PriorityText         := AddText(x + 185, y + 2, 60, 20, "BackgroundTrans", "Priority")

    unit.AutoUpgradeTitle := AddText(x + 275, y + 5, 250, 25, "+BackgroundTrans", "Enable Auto Upgrade")
    unit.AutoAbilityTitle := AddText(x + 275, y + 25, 250, 25, "+BackgroundTrans", "Enable Auto Ability")

    if (!unitUpgradeLimitDisabled) {
        unit.UpgradeCapText := AddText(x + 440, y + 2, 250, 20, "BackgroundTrans", "Upgrade Limit")
        unit.UpgradeLimitTitle := AddText(x + 445, y + 20, 250, 25, "+BackgroundTrans", "Enabled")
    }
    UnitData.Push(unit)
    return unit
}


;Create Unit slot
y_start := 85
y_spacing := 50
Loop 6 {
    AddUnitCard(MainUI, A_Index, 808, y_start + ((A_Index-1)*y_spacing))
}

enabled1 := MainUI.Add("CheckBox", "x818 y105 w15 h15", "")
enabled2 := MainUI.Add("CheckBox", "x818 y155 w15 h15", "")
enabled3 := MainUI.Add("CheckBox", "x818 y205 w15 h15", "")
enabled4 := MainUI.Add("CheckBox", "x818 y255 w15 h15", "")
enabled5 := MainUI.Add("CheckBox", "x818 y305 w15 h15", "")
enabled6 := MainUI.Add("CheckBox", "x818 y355 w15 h15", "")

upgradeEnabled1 := MainUI.Add("CheckBox", "x1065 y90 w15 h15", "")
upgradeEnabled2 := MainUI.Add("CheckBox", "x1065 y140 w15 h15", "")
upgradeEnabled3 := MainUI.Add("CheckBox", "x1065 y190 w15 h15", "")
upgradeEnabled4 := MainUI.Add("CheckBox", "x1065 y240 w15 h15", "")
upgradeEnabled5 := MainUI.Add("CheckBox", "x1065 y290 w15 h15", "")
upgradeEnabled6 := MainUI.Add("CheckBox", "x1065 y340 w15 h15", "")

abilityEnabled1 := MainUI.Add("CheckBox", "x1065 y110 w15 h15", "")
abilityEnabled2 := MainUI.Add("CheckBox", "x1065 y160 w15 h15", "")
abilityEnabled3 := MainUI.Add("CheckBox", "x1065 y210 w15 h15", "")
abilityEnabled4 := MainUI.Add("CheckBox", "x1065 y260 w15 h15", "")
abilityEnabled5 := MainUI.Add("CheckBox", "x1065 y310 w15 h15", "")
abilityEnabled6 := MainUI.Add("CheckBox", "x1065 y360 w15 h15", "")

upgradeLimitEnabled1 := MainUI.Add("CheckBox", "x1235 y105 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled2 := MainUI.Add("CheckBox", "x1235 y155 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled3 := MainUI.Add("CheckBox", "x1235 y205 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled4 := MainUI.Add("CheckBox", "x1235 y255 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled5 := MainUI.Add("CheckBox", "x1235 y305 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")
upgradeLimitEnabled6 := MainUI.Add("CheckBox", "x1235 y355 w15 h15 " (unitUpgradeLimitDisabled ? "Hidden" : ""), "")

MainUI.SetFont("s8 c" uiTheme[6])

; Placement dropdowns
Placement1 := MainUI.Add("DropDownList", "x918 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement2 := MainUI.Add("DropDownList", "x918 y155 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement3 := MainUI.Add("DropDownList", "x918 y205 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement4 := MainUI.Add("DropDownList", "x918 y255 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement5 := MainUI.Add("DropDownList", "x918 y305 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement6 := MainUI.Add("DropDownList", "x918 y355 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])

Priority1 := MainUI.Add("DropDownList", "x980 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Priority1.OnEvent("Change", (*) => OnPriorityChange("Placement", 1, Priority1.Value))

Priority2 := MainUI.Add("DropDownList", "x980 y155 w35 h180 Choose2 +Center", ["1","2","3","4","5","6"])
Priority2.OnEvent("Change", (*) => OnPriorityChange("Placement", 2, Priority2.Value))

Priority3 := MainUI.Add("DropDownList", "x980 y205 w35 h180 Choose3 +Center", ["1","2","3","4","5","6"])
Priority3.OnEvent("Change", (*) => OnPriorityChange("Placement", 3, Priority3.Value))

Priority4 := MainUI.Add("DropDownList", "x980 y255 w35 h180 Choose4 +Center", ["1","2","3","4","5","6"])
Priority4.OnEvent("Change", (*) => OnPriorityChange("Placement", 4, Priority4.Value))

Priority5 := MainUI.Add("DropDownList", "x980 y305 w35 h180 Choose5 +Center", ["1","2","3","4","5","6"])
Priority5.OnEvent("Change", (*) => OnPriorityChange("Placement", 5, Priority5.Value))

Priority6 := MainUI.Add("DropDownList", "x980 y355 w35 h180 Choose6 +Center", ["1","2","3","4","5","6"])
Priority6.OnEvent("Change", (*) => OnPriorityChange("Placement", 6, Priority6.Value))

UpgradePriority1 := MainUI.Add("DropDownList", "x1020 y105 w35 h180 Choose1 +Center", ["1","2","3","4","5","6",""])
UpgradePriority1.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 1, UpgradePriority1.Text))

UpgradePriority2 := MainUI.Add("DropDownList", "x1020 y155 w35 h180 Choose2 +Center", ["1","2","3","4","5","6",""])
UpgradePriority2.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 2, UpgradePriority2.Text))

UpgradePriority3 := MainUI.Add("DropDownList", "x1020 y205 w35 h180 Choose3 +Center", ["1","2","3","4","5","6",""])
UpgradePriority3.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 3, UpgradePriority3.Text))

UpgradePriority4 := MainUI.Add("DropDownList", "x1020 y255 w35 h180 Choose4 +Center", ["1","2","3","4","5","6",""])
UpgradePriority4.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 4, UpgradePriority4.Text))

UpgradePriority5 := MainUI.Add("DropDownList", "x1020 y305 w35 h180 Choose5 +Center", ["1","2","3","4","5","6",""])
UpgradePriority5.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 5, UpgradePriority5.Text))

UpgradePriority6 := MainUI.Add("DropDownList", "x1020 y355 w35 h180 Choose6 +Center", ["1","2","3","4","5","6",""])
UpgradePriority6.OnEvent("Change", (*) => OnPriorityChange("Upgrade", 6, UpgradePriority6.Text))

; Upgrade Limit
UpgradeLimit1 := MainUI.Add("DropDownList", "x1310 y105 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit2 := MainUI.Add("DropDownList", "x1310 y155 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit3 := MainUI.Add("DropDownList", "x1310 y205 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit4 := MainUI.Add("DropDownList", "x1310 y255 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit5 := MainUI.Add("DropDownList", "x1310 y305 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit6 := MainUI.Add("DropDownList", "x1310 y355 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])

LoadUnitSettingsByMode()
MainUI.Show("w1366 h700")
WinMove(0, 0,,, "ahk_id " MainUIHwnd)
forceRobloxSize()  ; Initial force size and position
SetTimer(checkRobloxSize, 600000)  ; Check every 10 minutes
;------FUNCTIONS------;

AddToLog(current) {
    global processList, currentOutputFile, lastlog
    global WebhookLogsEnabled, WebhookEnabled

    ; Shift values downward and remove arrows
    loop processList.Length {
        i := processList.Length - A_Index + 1
        if (i > 1)
            processList[i].Value := StrReplace(processList[i - 1].Value, "➤ ", "")
    }

    ; Add new entry to the top
    processList[1].Value := "➤ " . current

    ; Optional: Log to file
    elapsedTime := getElapsedTime()
    Sleep(50)

    ; Remove emojis from the log string
    cleanCurrent := CleanString(current)

    ; Optional: Log to file
    elapsedTime := getElapsedTime()
    Sleep(50)
    FileAppend(cleanCurrent . " " . elapsedTime . "`n", currentOutputFile)

    ; Store last log and optionally send webhook
    lastlog := current
    if (WebhookLogsEnabled.Value && WebhookEnabled.Value && scriptInitialized)
        WebhookLog()
}

;Timer
getElapsedTime() {
    global StartTime
    ElapsedTime := A_TickCount - StartTime
    Minutes := Mod(ElapsedTime // 60000, 60)  
    Seconds := Mod(ElapsedTime // 1000, 60)
    return Format("{:02}:{:02}", Minutes, Seconds)
}

;Basically the code to move roblox, below

sizeDown() {
    global rblxID, targetWidth, targetHeight

    if !WinExist(rblxID) {
        return
    }

    WinActivate(rblxID)
    WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)

    if (OutWidth == targetWidth && OutHeight == targetHeight) {
        return
    }

    ; Check if in fullscreen
    isFullscreen := (OutWidth >= A_ScreenWidth && OutHeight >= A_ScreenHeight)
    if (isFullscreen) {
        Send "{F11}"
        Sleep(300)

        ; Recheck size
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth >= A_ScreenWidth && OutHeight >= A_ScreenHeight) {
            return
        }
    }

    loop 3 {
        if (debugMessages) {
            AddToLog("Attempt " A_Index ": current size: " OutWidth "x" OutHeight)
        }
        WinMove(X, Y, targetWidth, targetHeight, rblxID)
        Sleep(150)

        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth == targetWidth && OutHeight == targetHeight) {
            return
        }
    }
    if (debugMessages) {
        AddToLog("Failed to resize after 3 attempts. Final size: " OutWidth "x" OutHeight)
    }
}

moveRobloxWindow() {
    global MainUIHwnd, offsetX, offsetY, rblxID
    
    if !WinExist(rblxID) {
        AddToLog("Waiting for Roblox window...")
        return
    }

    ; First ensure correct size
    sizeDown()
    
    ; Then move relative to main UI
    WinGetPos(&x, &y, &w, &h, MainUIHwnd)
    WinMove(x + offsetX, y + offsetY,,, rblxID)
    WinActivate(rblxID)
}

forceRobloxSize() {
    global rblxID
    
    if !WinExist(rblxID) {
        checkCount := 0
        While !WinExist(rblxID) {
            Sleep(5000)
            if(checkCount >= 5) {
                AddToLog("Attempting to locate the Roblox window")
            } 
            checkCount += 1
            if (checkCount > 12) { ; Give up after 1 minute
                AddToLog("Could not find Roblox window")
                return
            }
        }
        AddToLog("Found Roblox window")
    }

    WinActivate(rblxID)
    sizeDown()
    moveRobloxWindow()
}

; Function to periodically check window size
checkRobloxSize() {
    global rblxID
    if WinExist(rblxID) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth != targetWidth || OutHeight != targetHeight) {
            sizeDown()
            moveRobloxWindow()
        }
    }
}

checkSizeTimer() {
    if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, "ahk_exe RobloxPlayerBeta.exe")
        if (OutWidth != 816 || OutHeight != 638) {
            AddToLog("Fixing Roblox window size")
            moveRobloxWindow()
        }
    }
}

UpdateTooltip() {
    global waitingForClick
    if waitingForClick {
        MouseGetPos &x, &y
        ToolTip "Click anywhere to save coordinates...", x + 10, y + 10  ; Offset tooltip slightly
    } else {
        ToolTip()  ; Hide tooltip when not waiting
        SetTimer UpdateTooltip, 0  ; Stop the timer
    }
}

~LShift::
{
    global waitingForClick
    if waitingForClick {
        AddToLog("Stopping coordinate capture")
    }
    if (WaitingFor("Placements")) {
        SaveCustomPlacements()
    }
    if (recording) {
        StopRecordingWalk()
    }
    RemoveWaiting()
}

~LButton::
{
    global waitingForClick, savedCoords
    global nukeCoords

    if !scriptInitialized
        return

    if waitingForClick {
        if (WaitingFor("Nuke")) {
            MouseGetPos(&x, &y)
            SetTimer(UpdateTooltip, 0)
            nukeCoords := {x: x, y: y}
            ToolTip("Nuke Coords Set", x + 10, y + 10)
            AddToLog("📌 Nuke Ability Coordinates Saved → X: " x ", Y: " y)
            SetTimer(ClearToolTip, -1200)
            RemoveWaiting()
        }
        else {
            mode := ModeDropdown.Text
            mapName := (mode = "Event") ? EventDropdown.Text : CustomPlacementMapDropdown.Text

            if (mapName = "") {
                AddToLog("⚠️ No map selected.")
                return
            }

            MouseGetPos(&x, &y)
            SetTimer(UpdateTooltip, 0)

            coords := GetOrInitCustomCoords(mapName)
            coords.Push({ x: x, y: y, mapName: mapName })
            savedCoords[mapName] := coords

            ToolTip("Coords Set: " coords.Length, x + 10, y + 10)
            AddToLog("📌 [Map: " mapName "] Saved → X: " x ", Y: " y " | Set: " coords.Length)
            SetTimer(ClearToolTip, -1200)
        }
    }
}

ClearToolTip() {
    ToolTip()  ; Properly clear tooltip
    Sleep 100  ; Small delay to ensure clearing happens across all systems
    ToolTip()  ; Redundant clear to catch edge cases
}

InitControlGroups() {
    global ControlGroups

    ControlGroups["Unit"] := []

    Blacklist := [""]

    for name in ["Placement", "enabled", "priority", "upgradePriority", "upgradeEnabled", "upgradeLimitEnabled",
        "upgradeLimit", "abilityEnabled"] {
        loop 6 {
            varName := name . A_Index
            baseName := RegExReplace(varName, "\d+$")

            ; Check if baseName is in Blacklist manually
            isBlacklisted := false
            for index, item in Blacklist {
                if (item = baseName) {
                    isBlacklisted := true
                    break
                }
            }

            if (isBlacklisted)
                continue

            if IsSet(%varName%)  ; Check if the variable exists
                ControlGroups["Unit"].Push(%varName%)
            else
                AddToLog("Variable " . varName . " does not exist!")
        }
    }

    ControlGroups["Settings"] := [
        WebhookBorder, WebhookEnabled, WebhookLogsEnabled, WebhookURLBox,
        PrivateSettingsBorder, PrivateServerEnabled, PrivateServerURLBox, PrivateServerTestButton, PrivateServerGuideButton,
        TeleportFailsafe, TeleportFailsafeTimerText, TeleportFailsafeTimer,
        KeybindBorder, F1Text, F1Box, F2Text, F2Box, F3Text, F3Box, F4Text, F4Box, keybindSaveBtn,
        ZoomSettingsBorder, ZoomText, ZoomBox, ZoomTech, ZoomInOption, ZoomTeleport,
        MiscSettingsBorder, UpdateChecker
    ]

    ControlGroups["Upgrade"] := [
        UpgradeBorder, UnitManagerUpgradeSystem, PriorityUpgrade,
        UnitBorder, MinionSlot1, MinionSlot2, MinionSlot3, MinionSlot4, MinionSlot5, MinionSlot6

    ]

    ControlGroups["Mode"] := [
        ModeBorder, ModeConfigurations
    ]

    ControlGroups["Event"] := [
        EventBorder,
        HalloweenRestart, HalloweenRestartTimer
    ]

    ControlGroups["Story"] := [
        StoryBorder,
        NightmareDifficulty
    ]

    ControlGroups["Portal"] := [
        PortalBorder
    ]

    ControlGroups["Cards"] := [
        CardBorder,
        BossRushCardButton, BossRushCardText,
        HalloweenCardButton, HalloweenCardText
    ]

    ControlGroups["Nuke"] := [
        NukeBorder, NukeUnitSlotEnabled, NukeUnitSlot, NukeCoordinatesText, NukeCoordinatesButton, NukeAtSpecificWave,
        NukeWave, NukeDelayText, NukeDelay
    ]

    ControlGroups["Map Movement"] := [
        CustomWalkBorder, WalkMapText, WalkMapDropdown, MovementSetButton, MovementClearButton, MovementTestButton,
        MovementImport, MovementExport
    ]
}

ShowOnlyControlGroup(groupName) {
    global ControlGroups
    if !ControlGroups.Has(groupName) {
        return false
    }

    for name, groupControls in ControlGroups {
        shouldShow := (name = groupName)
        for ctrl in groupControls {
            if IsObject(ctrl)
                ctrl.Visible := shouldShow
        }
    }
    return true
}

ToggleControlGroup(groupName) {
    global ActiveControlGroup
    if (groupName = "Mode") {
        ActiveControlGroup := "Mode"
    }
    if (groupName = "Settings") {
        if (ActiveControlGroup = "Settings") {
            groupName := "Unit"
            ActiveControlGroup := "Unit"
        } else {
            ActiveControlGroup := "Settings"
        }
    }
    if (ShowOnlyControlGroup((groupName = "Mode" ? ModeDropdown.Text : groupName))) {
        ; AddToLog("Displaying: " (groupName = "Settings" ? "Settings UI" : groupName " Settings UI"))
        SetUnitCardVisibility((groupName = "Unit") ? true : false)
    }
}

SetUnitCardVisibility(visible) {
    for _, unit in UnitData {
        for _, ctrl in unit.OwnProps() {
            if IsObject(ctrl)
                ctrl.Visible := visible
        }
    }

    for name in ["Placement", "enabled", "upgradeEnabled", "Priority"] {
        loop 6 {
            ctrl := %name%%A_Index%
            if IsObject(ctrl)
                ctrl.Visible := visible
        }
    }
}

ValidateWebhook() {
    global WebhookURLBox

    url := WebhookURLBox.Value
    
    if (url == "") {
        WebhookEnabled.Value := false
        WebhookURLBox.Value := ""
        MsgBox("Webhook URL cannot be blank. Please enter a valid Webhook URL.", "Missing URL", "+0x1000")
        return
    }
    
    if (!RegExMatch(url, "^https://discord\.com/api/webhooks/.*")) {
        WebhookEnabled.Value := false
        WebhookURLBox.Value := ""
        MsgBox("Invalid Webhook URL! Please ensure it follows the correct format.", "Invalid URL", "+0x1000")
        return
    }
}

ValidateEditBox(ctrl) {
    val := Trim(ctrl.Value)
    ; If the input is not a number, reset to 0
    if !IsInteger(val)
    {
        ctrl.Value := "0"
        return
    }

    ; Convert to integer
    num := Integer(val)

    if (num < 0)
        ctrl.Value := "0"

    if (ctrl == ZoomBox) {
        if (num > 20)
            ctrl.Value := "20"  ; Limit to a maximum of 20
    }
}

OpenCoordinateEditor() {
    
}