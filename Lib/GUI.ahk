#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Image.ahk
#Include Functions.ahk

; Basic Application Info
global GameTitle := "Ryn's Anime Last Stand Macro "
global version := "v1.5.5"
global rblxID := "ahk_exe RobloxPlayerBeta.exe"
;Coordinate and Positioning Variables
global targetWidth := 816
global targetHeight := 638
global offsetX := -5
global offsetY := 1
global WM_SIZING := 0x0214
global WM_SIZE := 0x0005
global centerX := 408
global centerY := 320
global successfulCoordinates := []
;State Variables
global enabledUnits := Map()  
global placementValues := Map()  
;Statistics Tracking
global Wins := 0
global loss := 0
global mode := ""
global StartTime := A_TickCount
global currentTime := GetCurrentTime()
;Auto Challenge
global challengeStartTime := A_TickCount
global inChallengeMode := false
global firstStartup := true
;Custom Unit Placement
global waitingForClick := false
global savedCoords := [[], []]  ; Index-based: one array for each preset
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
uiTheme.Push("00ffb3") ; HighLight
;Logs/Save settings
global settingsGuiOpen := false
global SettingsGUI := ""
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

;------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------
MainUI.BackColor := uiTheme[2]
global Webhookdiverter := MainUI.Add("Edit", "x0 y0 w1 h1 +Hidden", "") ; diversion
uiBorders.Push(MainUI.Add("Text", "x0 y0 w1364 h1 +Background" uiTheme[3]))  ;Top line
uiBorders.Push(MainUI.Add("Text", "x0 y0 w1 h697 +Background" uiTheme[3]))   ;Left line
uiBorders.Push(MainUI.Add("Text", "x1363 y0 w1 h630 +Background" uiTheme[3])) ;Right line
uiBorders.Push(MainUI.Add("Text", "x1363 y0 w1 h697 +Background" uiTheme[3])) ;Second Right line
uiBackgrounds.Push(MainUI.Add("Text", "x3 y3 w1360 h27 +Background" uiTheme[2])) ;Title Top
uiBorders.Push(MainUI.Add("Text", "x0 y30 w1363 h1 +Background" uiTheme[3])) ;Title bottom
uiBorders.Push(MainUI.Add("Text", "x803 y443 w560 h1 +Background" uiTheme[3])) ;Placement bottom
uiBorders.Push(MainUI.Add("Text", "x803 y527 w560 h1 +Background" uiTheme[3])) ;Process bottom
uiBorders.Push(MainUI.Add("Text", "x802 y30 w1 h667 +Background" uiTheme[3])) ;Roblox Right
uiBorders.Push(MainUI.Add("Text", "x0 y697 w1364 h1 +Background" uiTheme[3], "")) ;Roblox second bottom
uiBorders.Push(MainUI.Add("Text", "x0 y630 w802.5 h1 +Background" uiTheme[3], "")) ;Roblox game bottom

global robloxHolder := MainUI.Add("Text", "x3 y33 w797 h597 +Background" uiTheme[5], "") ;Roblox window box
global exitButton := MainUI.Add("Picture", "x1330 y1 w32 h32 +BackgroundTrans", Exitbutton) ;Exit image
exitButton.OnEvent("Click", (*) => Destroy()) ;Exit button
global minimizeButton := MainUI.Add("Picture", "x1305 y3 w27 h27 +Background" uiTheme[2], Minimize) ;Minimize gui
minimizeButton.OnEvent("Click", (*) => minimizeUI()) ;Minimize gui
MainUI.SetFont("Bold s16 c" uiTheme[1], "Verdana") ;Font
global windowTitle := MainUI.Add("Text", "x10 y3 w1200 h29 +BackgroundTrans", GameTitle "" . "" version) ;Title

MainUI.Add("Text", "x805 y501 w558 h25 +Center +BackgroundTrans", "Console") ;Process header
uiBorders.Push(MainUI.Add("Text", "x803 y499 w560 h1 +Background" uiTheme[3])) ;Process Top
MainUI.SetFont("norm s11 c" uiTheme[1]) ;Font
global process1 := MainUI.Add("Text", "x810 y536 w538 h18 +BackgroundTrans c" uiTheme[7], "➤ Original Creator: Ryn (@TheRealTension)") ;Processes
global process2 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") ;Processes 
global process3 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process4 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process5 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process6 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process7 := MainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
WinSetTransColor(uiTheme[5], MainUI) ;Roblox window box

;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS
ShowSettingsGUI(*) {
    global settingsGuiOpen, SettingsGUI
    
    ; Check if settings window already exists
    if (SettingsGUI && WinExist("ahk_id " . SettingsGUI.Hwnd)) {
        WinActivate("ahk_id " . SettingsGUI.Hwnd)
        return
    }
    
    if (settingsGuiOpen) {
        return
    }
    
    settingsGuiOpen := true
    SettingsGUI := Gui("-MinimizeBox +Owner" MainUIHwnd)  
    SettingsGui.Title := "Settings"
    SettingsGUI.OnEvent("Close", OnSettingsGuiClose)
    SettingsGUI.BackColor := uiTheme[2]
    
    ; Window border
    SettingsGUI.Add("Text", "x0 y0 w1 h300 +Background" uiTheme[3])     ; Left
    SettingsGUI.Add("Text", "x599 y0 w1 h300 +Background" uiTheme[3])   ; Right
    SettingsGUI.Add("Text", "x0 y281 w600 h1 +Background" uiTheme[3])   ; Bottom
    
    ; Right side sections
    SettingsGUI.SetFont("s9", "Verdana")

    ; Private Server section
    SettingsGUI.Add("GroupBox", "x310 y175 w280 h100 Center c" uiTheme[1], "Private Server")  ; Box

    SettingsGUI.Add("Text", "x320 y195 c" uiTheme[1], "Private Server Link (optional)")  ; Ps text
    global PsLinkBox := SettingsGUI.Add("Edit", "x320 y215 w260 h20 c" uiTheme[6])  ;  ecit box

    SettingsGUI.Add("GroupBox", "x10 y10 w115 h70 c" uiTheme[1], "UI Navigation")
    SettingsGUI.Add("Text", "x20 y30 c" uiTheme[1], "Navigation Key")
    global UINavBox := SettingsGUI.Add("Edit", "x20 y50 w20 h20 c" uiTheme[6], "\")

    PsSaveBtn := SettingsGUI.Add("Button", "x460 y240 w120 h25", "Save PsLink")
    PsSaveBtn.OnEvent("Click", (*) => SavePsSettings())

    UINavSaveBtn := SettingsGUI.Add("Button", "x50 y50 w60 h20", "Save")
    UINavSaveBtn.OnEvent("Click", (*) => SaveUINavSettings())

    ; Loadsettings
    if FileExist("Settings\PrivateServer.txt")
        PsLinkBox.Value := FileRead("Settings\PrivateServer.txt", "UTF-8")
    if FileExist("Settings\UINavigation.txt")
        UINavBox.Value := FileRead("Settings\UINavigation.txt", "UTF-8")

    ; Show the settings window
    SettingsGUI.Show("w600 h285")
    Webhookdiverter.Focus()
}

OpenGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop")
    GuideGUI.SetFont("s10 bold", "Segoe UI")
    GuideGUI.Title := "Anime Last Stand Guide"

    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Add Guide content
    GuideGUI.SetFont("s16 bold", "Segoe UI")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center", "1 - In your ROBLOX settings, make sure your graphics are set to 1")
    GuideGUI.Add("Picture", "x50 w700   cWhite +Center", "Images\graphics1.png")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center", "2 - Make sure you have enabled unit selection to the right")
    GuideGUI.Add("Picture", "x100 w511   cWhite +Center", "Images\als_settings.png")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center", "3 - Start the macro after you have started your mode")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center", "4 - Map Specific placement currently only covers Raids")

    GuideGUI.Show("w800")
}

MainUI.SetFont("s9 Bold c" uiTheme[1])

DebugButton := MainUI.Add("Button", "x808 y5 w90 h20 +Center", "Debug")
DebugButton.OnEvent("Click", (*) => "")

global guideBtn := MainUI.Add("Button", "x908 y5 w90 h20", "Guide")
guideBtn.OnEvent("Click", OpenGuide)

global unitsButton := MainUI.Add("Button", "x1008 y5 w90 h20", "Upgrades")
unitsButton.OnEvent("Click", (*) => ToggleControlGroup("Upgrades"))

global modeButton := MainUI.Add("Button", "x1108 y5 w90 h20", "Mode Config")
;modeButton.OnEvent("Click", (*) => ToggleControlGroup("Mode"))

global settingsBtn := MainUI.Add("Button", "x1208 y5 w90 h20", "Settings")
settingsBtn.OnEvent("Click", (*) => ToggleControlGroup("Settings"))

placementSaveBtn := MainUI.Add("Button", "x807 y471 w80 h20", "Save")
placementSaveBtn.OnEvent("Click", SaveSettings)

MainUI.SetFont("s9")

global NextLevelBox := MainUI.Add("Checkbox", "x900 y451 cffffff", "Next Level")
global SkipLobby := MainUI.Add("Checkbox", "x900 y451 cffffff", "Skip Lobby")
global ReturnLobbyBox := MainUI.Add("Checkbox", "x1150 y476 cffffff Checked", "Return To Lobby")

global AutoAbilityBox := MainUI.Add("CheckBox", "x1005 y451 cffffff Checked", "Auto Ability")
global AutoAbilityText := MainUI.Add("Text", "x1125 y451 c" uiTheme[1], "Auto Ability Timer:")
global AutoAbilityTimer := MainUI.Add("Edit", "x1255 y449 w30 h20 cBlack Number", "60")

global SeamlessToggle := MainUI.Add("CheckBox", "x900 y476 cffffff", "Seamless Replay Enabled")

PlacementPatternText := MainUI.Add("Text", "x815 y390 w125 h20", "Placement Pattern")
global PlacementPatternDropdown := MainUI.Add("DropDownList", "x825 y410 w100 h180 Choose2 +Center", ["Circle", "Custom", "Grid", "3x3 Grid", "Spiral", "Up and Down", "Random"])

PlacementProfilesText := MainUI.Add("Text", "x1100 y390 w125 h20", "Placement Presets")
global PlacementProfiles := MainUI.Add("DropDownList", "x1110 y410 w100 h180 Choose1 +Center", ["Story", "Raid", "Portals", "Boss Rush", "Survival", "Custom #1", "Custom #2", "Custom #3"])

PlaceSpeedText := MainUI.Add("Text", "x956 y390 w115 h20", "Placement Speed")
global PlaceSpeed := MainUI.Add("DropDownList", "x963 y410 w100 h180 Choose3 +Center", ["Super Fast (1s)", "Fast (1.5s)", "Default (2s)", "Slow (2.5s)", "Very Slow (3s)", "Toaster (4s)"])

PlacementSelectionText := MainUI.Add("Text", "x1245 y390 w115 h20", "Placement Order")
global PlacementSelection := MainUI.Add("DropDownList", "x1250 y410 w100 h180 Choose1 +Center", ["Slot #1 First", "Slot #2 First"])

placementSaveText := MainUI.Add("Text", "x807 y451 w80 h20", "Save Config")
Hotkeytext := MainUI.Add("Text", "x807 y35 w200 h30", "F1: Fix Roblox Position")
Hotkeytext2 := MainUI.Add("Text", "x807 y50 w200 h30", "F2: Start Macro")
Hotkeytext3 := MainUI.Add("Text", "x807 y65 w200 h30", "F3: Stop Macro")
GithubButton := MainUI.Add("Picture", "x30 y640", GithubImage)
DiscordButton := MainUI.Add("Picture", "x112 y645 w60 h34 +BackgroundTrans cffffff", DiscordImage)

global CustomSettings := MainUI.Add("GroupBox", "x190 y632 w390 h60 +Center c" uiTheme[1], "Custom Placement Settings")

customPlacementButton := MainUI.Add("Button", "x210 y662 w80 h20", "Set")
customPlacementButton.OnEvent("Click", (*) => StartCoordCapture())

customPlacementClearButton := MainUI.Add("Button", "x345 y662 w80 h20", "Clear")
customPlacementClearButton.OnEvent("Click", (*) => DeleteCoordsForPreset(PlacementProfiles.Value))

fixCameraText := MainUI.Add("Text", "x505 y642 w60 h20 +Left", "Camera")
fixCameraButton := MainUI.Add("Button", "x490 y662 w80 h20", "Fix")
fixCameraButton.OnEvent("Click", (*) => BasicSetup(true))

global WebhookBorder := MainUI.Add("GroupBox", "x808 y85 w550 h296 +Center Hidden c" uiTheme[1], "Webhook Settings")
global WebhookEnabled := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Webhook Enabled")
WebhookEnabled.OnEvent("Click", (*) => ValidateWebhook())
global WebhookLogsEnabled := MainUI.Add("CheckBox", "x825 y130 Hidden cffffff", "Send Console Logs")
global WebhookURLBox := MainUI.Add("Edit", "x1000 y108 w260 h20 Hidden c" uiTheme[6], "")

global PrivateSettingsBorder := MainUI.Add("GroupBox", "x808 y145 w550 h296 +Center Hidden c" uiTheme[1], "Reconnection Settings")
global PrivateServerEnabled := MainUI.Add("CheckBox", "x825 y175 Hidden cffffff", "Reconnect to Private Server")
global PrivateServerURLBox := MainUI.Add("Edit", "x1050 y173 w160 h20 Hidden c" uiTheme[6], "")
PrivateServerTestButton := MainUI.Add("Button", "x1225 y173 w80 h20 Hidden", "Test Link")
PrivateServerTestButton.OnEvent("Click", (*) => Reconnect(true))
;global PrivateSettingsBorderBottom := MainUI.Add("GroupBox", "x808 y205 w550 h176 Hidden c" uiTheme[1], "")

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
global LeftSideUnitManager := MainUI.Add("CheckBox", "x825 y110 Hidden cffffff", "Using Left-Side Unit Selection (Anime Last Stand's Default)")
global UnitManagerUpgradeSystem := MainUI.Add("CheckBox", "x825 y130 Hidden cffffff", "Use the Unit Manager to upgrade your units")
global PriorityUpgrade := MainUI.Add("CheckBox", "x825 y150 cffffff", "Use Unit Priority while Upgrading/Auto Upgrading")

global AutoUpgradeBorder := MainUI.Add("GroupBox", "x808 y170 w550 h210 +Center Hidden c" uiTheme[1], "Auto-Upgrade Settings")
global UnitManagerAutoUpgrade := MainUI.Add("CheckBox", "x825 y197 Hidden cffffff", "Enable Auto-Upgrading (Via the Unit Manager)")

global ZoomSettingsBorder := MainUI.Add("GroupBox", "x1000 y205 w165 h176 +Center Hidden c" uiTheme[1], "Zoom Settings")
global ZoomText := MainUI.Add("Text", "x1018 y230 Hidden c" uiTheme[1], "Zoom Level:")
global ZoomBox := MainUI.Add("Edit", "x1115 y228 w30 h20 Hidden cBlack Number", "20")
ZoomBox.OnEvent("Change", (*) => ValidateEditBox(ZoomBox))

global MiscSettingsBorder := MainUI.Add("GroupBox", "x1163 y205 w195 h176 +Center Hidden c" uiTheme[1], "")

GithubButton.OnEvent("Click", (*) => OpenGithub())
DiscordButton.OnEvent("Click", (*) => OpenDiscord())
;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS
global modeSelectionGroup := MainUI.Add("GroupBox", "x808 y38 w500 h45 +Center Background" uiTheme[2], "Game Mode Selection")
MainUI.SetFont("s10 c" uiTheme[6])
global ModeDropdown := MainUI.Add("DropDownList", "x818 y53 w140 h180 Choose0 +Center", ["Dungeon", "Portal", "Raid", "Custom"])
global StoryDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Story #1"])
global StoryActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center Hidden", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6", "Infinite"])
global LegendDropDown := MainUI.Add("DropDownlist", "x968 y53 w150 h180 Choose0 +Center", ["Legend Stage #1"] )
;global LegendActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3"])
global RaidDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center", ["Marines Fort", "Hell City", "Snowy Capital", "Leaf Village", "Wanderniech", "Central City", "Giants District", "Flying Island", "U-18", "Flower Garden", "Ancient Dungeon", "Shinjuku Crater", "Valhalla Arena", "Frozen Planet", "Blossom Church"])
global RaidActDropdown := MainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6"])
global DungeonDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Devil's Dungeon", "Infernal Dungeon", "Monarch's Dungeon"])
global PortalDropdown := MainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center Hidden", ["Demon Place", "Gate", "Soul King Palace", "Summer Laguna"])
global ConfirmButton := MainUI.Add("Button", "x1218 y53 w80 h25", "Confirm")


LegendDropDown.Visible := false
;LegendActDropdown.Visible := false
RaidDropdown.Visible := false
RaidActDropdown.Visible := false
SkipLobby.Visible := false
ReturnLobbyBox.Visible := false
Hotkeytext.Visible := false
Hotkeytext2.Visible := false
Hotkeytext3.Visible := false
ModeDropdown.OnEvent("Change", OnModeChange)
StoryDropdown.OnEvent("Change", OnStoryChange)
LegendDropDown.OnEvent("Change", OnLegendChange)
RaidDropdown.OnEvent("Change", OnRaidChange)
ConfirmButton.OnEvent("Click", OnConfirmClick)
;------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI
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
    unit.BorderRight3   := AddText(x + 390, y, 2, 45, "+Background" uiTheme[3])

    ; Main Labels
    MainUI.SetFont("s11 Bold c" uiTheme[1])
    unit.EnabledTitle   := AddText(x + 30, y + 18, 60, 25, "+BackgroundTrans", "Unit " index)

    ; Unit Configuration
    MainUI.SetFont("s9 c" uiTheme[1])
    unit.PlacementText        := AddText(x + 90, y + 2, 80, 20, "+BackgroundTrans", "Placements")
    unit.PriorityText         := AddText(x + 185, y + 2, 60, 20, "BackgroundTrans", "Priority")
    unit.PlaceAndUpgradeText  := AddText(x + 266, y + 2, 250, 20, "BackgroundTrans", "Place && Upgrade")
    unit.UpgradeTitle         := AddText(x + 295, y + 20, 250, 25, "+BackgroundTrans", "Enabled")
    unit.UpgradeCapText       := AddText(x + 425, y + 2, 250, 20, "BackgroundTrans", "Upgrade Limit")
    unit.UpgradeLimitTitle    := AddText(x + 435, y + 20, 250, 25, "+BackgroundTrans", "Enabled")

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

upgradeEnabled1 := MainUI.Add("CheckBox", "x1070 y105 w15 h15", "")
upgradeEnabled2 := MainUI.Add("CheckBox", "x1070 y155 w15 h15", "")
upgradeEnabled3 := MainUI.Add("CheckBox", "x1070 y205 w15 h15", "")
upgradeEnabled4 := MainUI.Add("CheckBox", "x1070 y255 w15 h15", "")
upgradeEnabled5 := MainUI.Add("CheckBox", "x1070 y305 w15 h15", "")
upgradeEnabled6 := MainUI.Add("CheckBox", "x1070 y355 w15 h15", "")

upgradeLimitEnabled1 := MainUI.Add("CheckBox", "x1210 y105 w15 h15", "")
upgradeLimitEnabled2 := MainUI.Add("CheckBox", "x1210 y155 w15 h15", "")
upgradeLimitEnabled3 := MainUI.Add("CheckBox", "x1210 y205 w15 h15", "")
upgradeLimitEnabled4 := MainUI.Add("CheckBox", "x1210 y255 w15 h15", "")
upgradeLimitEnabled5 := MainUI.Add("CheckBox", "x1210 y305 w15 h15", "")
upgradeLimitEnabled6 := MainUI.Add("CheckBox", "x1210 y355 w15 h15", "")

MainUI.SetFont("s8 c" uiTheme[6])

; Placement dropdowns
Placement1 := MainUI.Add("DropDownList", "x908 y105 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement2 := MainUI.Add("DropDownList", "x908 y155 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement3 := MainUI.Add("DropDownList", "x908 y205 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement4 := MainUI.Add("DropDownList", "x908 y255 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement5 := MainUI.Add("DropDownList", "x908 y305 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Placement6 := MainUI.Add("DropDownList", "x908 y355 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])

Priority1 := MainUI.Add("DropDownList", "x990 y105 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
Priority2 := MainUI.Add("DropDownList", "x990 y155 w60 h180 Choose2 +Center", ["1","2","3","4","5","6"])
Priority3 := MainUI.Add("DropDownList", "x990 y205 w60 h180 Choose3 +Center", ["1","2","3","4","5","6"])
Priority4 := MainUI.Add("DropDownList", "x990 y255 w60 h180 Choose4 +Center", ["1","2","3","4","5","6"])
Priority5 := MainUI.Add("DropDownList", "x990 y305 w60 h180 Choose5 +Center", ["1","2","3","4","5","6"])
Priority6 := MainUI.Add("DropDownList", "x990 y355 w60 h180 Choose6 +Center", ["1","2","3","4","5","6"])

UpgradePriority1 := MainUI.Add("DropDownList", "x1250 y105 w60 h180 Choose1 +Center Hidden", ["1","2","3","4","5","6"])
UpgradePriority2 := MainUI.Add("DropDownList", "x1250 y155 w60 h180 Choose2 +Center Hidden", ["1","2","3","4","5","6"])
UpgradePriority3 := MainUI.Add("DropDownList", "x1250 y205 w60 h180 Choose3 +Center Hidden", ["1","2","3","4","5","6"])
UpgradePriority4 := MainUI.Add("DropDownList", "x1250 y255 w60 h180 Choose4 +Center Hidden", ["1","2","3","4","5","6"])
UpgradePriority5 := MainUI.Add("DropDownList", "x1250 y305 w60 h180 Choose5 +Center Hidden", ["1","2","3","4","5","6"])
UpgradePriority6 := MainUI.Add("DropDownList", "x1250 y355 w60 h180 Choose6 +Center Hidden", ["1","2","3","4","5","6"])

; Upgrade Limit
UpgradeLimit1 := MainUI.Add("DropDownList", "x1310 y105 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit2 := MainUI.Add("DropDownList", "x1310 y155 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit3 := MainUI.Add("DropDownList", "x1310 y205 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit4 := MainUI.Add("DropDownList", "x1310 y255 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit5 := MainUI.Add("DropDownList", "x1310 y305 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
UpgradeLimit6 := MainUI.Add("DropDownList", "x1310 y355 w45 h180 Choose1 +Center", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14"])

readInSettings()
MainUI.Show("w1366 h700")
WinMove(0, 0,,, "ahk_id " MainUIHwnd)
forceRobloxSize()  ; Initial force size and position
SetTimer(checkRobloxSize, 600000)  ; Check every 10 minutes
;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION
;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS

;Process text
AddToLog(current) { 
    global process1, process2, process3, process4, process5, process6, process7, currentOutputFile, lastlog

    ; Remove arrow from all lines first
    process7.Value := StrReplace(process6.Value, "➤ ", "")
    process6.Value := StrReplace(process5.Value, "➤ ", "")
    process5.Value := StrReplace(process4.Value, "➤ ", "")
    process4.Value := StrReplace(process3.Value, "➤ ", "")
    process3.Value := StrReplace(process2.Value, "➤ ", "")
    process2.Value := StrReplace(process1.Value, "➤ ", "")
    
    ; Add arrow only to newest process
    process1.Value := "➤ " . current
    
    elapsedTime := getElapsedTime()
    Sleep(50)
    FileAppend(current . " " . elapsedTime . "`n", currentOutputFile)

    ; Add webhook logging
    lastlog := current

    if (WebhookLogsEnabled.Value && WebhookEnabled.Value) {
        WebhookLog()
    }
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
    global rblxID
    
    if !WinExist(rblxID)
        return

    WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
    
    ; Exit fullscreen if needed
    if (OutWidth >= A_ScreenWidth && OutHeight >= A_ScreenHeight) {
        Send "{F11}"
        Sleep(100)
    }

    ; Force the window size and retry if needed
    Loop 3 {
        WinMove(X, Y, targetWidth, targetHeight, rblxID)
        Sleep(100)
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth == targetWidth && OutHeight == targetHeight)
            break
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
;Basically the code to move roblox, Above

OnSettingsGuiClose(*) {
    global settingsGuiOpen, SettingsGUI
    settingsGuiOpen := false
    if SettingsGUI {
        SettingsGUI.Destroy()
        SettingsGUI := ""  ; Clear the GUI reference
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

StartCoordCapture() {
    global savedCoords
    global waitingForClick
    global placement1, placement2, placement3, placement4, placement5, placement6

    presetIndex := PlacementProfiles.Value

    ; Retrieve values from dropdowns
    totalEnabled := placement1.Value + placement2.Value + placement3.Value + placement4.Value + placement5.Value + placement6.Value

    ; Stop coordinate capture if the max total is reached
    if savedCoords[presetIndex].Length >= totalEnabled {
        AddToLog("Max total coordinates reached. Stopping coordinate capture.")
        return
    }

    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    waitingForClick := true
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position every 50ms
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
        waitingForClick := false
    }
}

~LButton::
{
    global waitingForClick, savedCoords
    global placement1, placement2, placement3, placement4, placement5, placement6

    if !scriptInitialized
        return

    if waitingForClick {
        presetIndex := PlacementProfiles.Value

        if (presetIndex < 1)
        {
            if (debugMessages) {
                AddToLog("⚠️ Invalid preset index: " presetIndex)
            }
            return
        }

        totalEnabled := placement1.Value + placement2.Value + placement3.Value + placement4.Value + placement5.Value + placement6.Value

        MouseGetPos(&x, &y)
        SetTimer(UpdateTooltip, 0)

        ; Use your function here
        coords := GetOrInitPresetCoords(presetIndex)
        coords.Push({x: x, y: y})
        savedCoords[presetIndex] := coords  ; Not strictly needed, but OK for clarity

        ToolTip("Coords Set: " coords.Length " / Total Enabled: " totalEnabled, x + 10, y + 10)
        AddToLog("📌 [Preset: " PlacementProfiles.Text "] Saved → X: " x ", Y: " y " | Set: " coords.Length " / Enabled: " totalEnabled)
        SetTimer(ClearToolTip, -1200)

        if coords.Length >= totalEnabled {
            AddToLog("✅ [Preset " PlacementProfiles.Text "] All coordinates set, stopping capture.")
            waitingForClick := false
        }
    }
}

GetOrInitPresetCoords(index) {
    global savedCoords
    if !IsObject(savedCoords)
        savedCoords := []

    ; Extend the array up to the index if needed
    while (savedCoords.Length < index)
        savedCoords.Push([])

    if !IsObject(savedCoords[index])
        savedCoords[index] := []

    return savedCoords[index]
}

ClearToolTip() {
    ToolTip()  ; Properly clear tooltip
    Sleep 100  ; Small delay to ensure clearing happens across all systems
    ToolTip()  ; Redundant clear to catch edge cases
}

DeleteCoordsForPreset(index) {
    global savedCoords

    ; Ensure savedCoords is initialized as an object
    if !IsObject(savedCoords)
        savedCoords := []

    ; Extend the array up to the index if needed
    while (savedCoords.Length < index)
        savedCoords.Push([])

    ; Check if the preset has coordinates (i.e., non-empty)
    if (savedCoords[index].Length > 0) {
        savedCoords[index] := []  ; Clear the coordinates for the specified preset
        AddToLog("🗑️ Cleared coordinates for Preset: " PlacementProfiles.Text)
    } else {
        AddToLog("⚠️ No coordinates to clear for Preset: " PlacementProfiles.Text)
    }
}

InitControlGroups() {
    global ControlGroups

    ControlGroups["Default"] := []

    for name in ["Placement", "enabled", "priority", "upgradeEnabled", "upgradeLimitEnabled", "upgradeLimit"] {
        loop 6 {
            varName := name . A_Index
            if IsSet(%varName%)  ; Check if the variable exists
                ControlGroups["Default"].Push(%varName%)
            else
                MsgBox("Variable " . varName . " does not exist!")
        }
    }

    ControlGroups["Settings"] := [
        WebhookBorder, WebhookEnabled, WebhookLogsEnabled, WebhookURLBox,
        PrivateSettingsBorder, PrivateServerEnabled, PrivateServerURLBox, PrivateServerTestButton,
        KeybindBorder, F1Text, F1Box, F2Text, F2Box, F3Text, F3Box, F4Text, F4Box, keybindSaveBtn,
        ZoomSettingsBorder, ZoomText, ZoomBox,
        MiscSettingsBorder, 
    ]

    ControlGroups["Upgrades"] := [
        UpgradeBorder, LeftSideUnitManager, UnitManagerUpgradeSystem,
        AutoUpgradeBorder, UnitManagerAutoUpgrade
    ]
}


ShowOnlyControlGroup(groupName) {
    global ControlGroups
    if !ControlGroups.Has(groupName) {
        AddToLog("Invalid control group: " groupName)
        return
    }

    for name, groupControls in ControlGroups {
        shouldShow := (name = groupName)
        for ctrl in groupControls {
            if IsObject(ctrl)
                ctrl.Visible := shouldShow
        }
    }
}

ToggleControlGroup(groupName) {
    global ActiveControlGroup
    if (ActiveControlGroup = groupName) {
        ShowOnlyControlGroup("Default")
        ActiveControlGroup := ""
        AddToLog("Displaying: Default UI")
        ShowUnitCards()
    } else {
        ShowOnlyControlGroup(groupName)
        ActiveControlGroup := groupName
        AddToLog("Displaying: " groupName " Settings UI")
        HideUnitCards()
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

HideUnitCards() {
    SetUnitCardVisibility(false)
}

ShowUnitCards() {
    SetUnitCardVisibility(true)
}

ValidateWebhook() {
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

    if (num > 20)
        ctrl.Value := "20"  ; Limit to a maximum of 20
}
