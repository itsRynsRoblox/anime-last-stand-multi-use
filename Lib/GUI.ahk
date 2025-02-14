#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Image.ahk
#Include Functions.ahk

; Basic Application Info
global aaTitle := "Ryn's Anime Last Stand Macro "
global version := "v1.0"
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
;Gui creation
global uiBorders := []
global uiBackgrounds := []
global uiTheme := []
global UnitData := []
global aaMainUI := Gui("+AlwaysOnTop -Caption")
global lastlog := ""
global aaMainUIHwnd := aaMainUI.Hwnd
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
global WebhookURLFile := "Settings\WebhookURL.txt"
global DiscordUserIDFile := "Settings\DiscordUSERID.txt"
global SendActivityLogsFile := "Settings\SendActivityLogs.txt"
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
aaMainUI.BackColor := uiTheme[2]
global Webhookdiverter := aaMainUI.Add("Edit", "x0 y0 w1 h1 +Hidden", "") ; diversion
uiBorders.Push(aaMainUI.Add("Text", "x0 y0 w1364 h1 +Background" uiTheme[3]))  ;Top line
uiBorders.Push(aaMainUI.Add("Text", "x0 y0 w1 h697 +Background" uiTheme[3]))   ;Left line
uiBorders.Push(aaMainUI.Add("Text", "x1363 y0 w1 h630 +Background" uiTheme[3])) ;Right line
uiBorders.Push(aaMainUI.Add("Text", "x1363 y0 w1 h697 +Background" uiTheme[3])) ;Second Right line
uiBackgrounds.Push(aaMainUI.Add("Text", "x3 y3 w1360 h27 +Background" uiTheme[2])) ;Title Top
uiBorders.Push(aaMainUI.Add("Text", "x0 y30 w1363 h1 +Background" uiTheme[3])) ;Title bottom
uiBorders.Push(aaMainUI.Add("Text", "x802 y30 w1 h600 +Background" uiTheme[3])) ;Roblox Right
uiBorders.Push(aaMainUI.Add("Text", "x803 y433 w560 h1 +Background" uiTheme[3])) ;Process Top
uiBorders.Push(aaMainUI.Add("Text", "x803 y461 w560 h1 +Background" uiTheme[3])) ;Process bottom
uiBorders.Push(aaMainUI.Add("Text", "x0 y630 w1364 h1 +Background" uiTheme[3], "")) ;Roblox bottom
uiBorders.Push(aaMainUI.Add("Text", "x0 y697 w1364 h1 +Background" uiTheme[3], "")) ;Roblox second bottom

global robloxHolder := aaMainUI.Add("Text", "x3 y33 w797 h597 +Background" uiTheme[5], "") ;Roblox window box
global exitButton := aaMainUI.Add("Picture", "x1330 y1 w32 h32 +BackgroundTrans", Exitbutton) ;Exit image
exitButton.OnEvent("Click", (*) => Destroy()) ;Exit button
global minimizeButton := aaMainUI.Add("Picture", "x1300 y3 w27 h27 +Background" uiTheme[2], Minimize) ;Minimize gui
minimizeButton.OnEvent("Click", (*) => minimizeUI()) ;Minimize gui
aaMainUI.SetFont("Bold s16 c" uiTheme[1], "Verdana") ;Font
global windowTitle := aaMainUI.Add("Text", "x10 y3 w1200 h29 +BackgroundTrans", aaTitle "" . "" version) ;Title

aaMainUI.Add("Text", "x805 y435 w558 h25 +Center +BackgroundTrans", "Process") ;Process header
aaMainUI.SetFont("norm s11 c" uiTheme[1]) ;Font
global process1 := aaMainUI.Add("Text", "x810 y470 w538 h18 +BackgroundTrans c" uiTheme[7], "➤ Original Creator: Ryn") ;Processes
global process2 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") ;Processes 
global process3 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process4 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process5 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process6 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
global process7 := aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", "") 
WinSetTransColor(uiTheme[5], aaMainUI) ;Roblox window box

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
    SettingsGUI := Gui("-MinimizeBox +Owner" aaMainUIHwnd)  
    SettingsGui.Title := "Settings"
    SettingsGUI.OnEvent("Close", OnSettingsGuiClose)
    SettingsGUI.BackColor := uiTheme[2]
    
    ; Window border
    SettingsGUI.Add("Text", "x0 y0 w1 h600 +Background" uiTheme[3])     ; Left
    SettingsGUI.Add("Text", "x599 y0 w1 h600 +Background" uiTheme[3])   ; Right
    SettingsGUI.Add("Text", "x0 y399 w600 h1 +Background" uiTheme[3])   ; Bottom
    
    ; Right side sections
    SettingsGUI.SetFont("s10", "Verdana")
    SettingsGUI.Add("GroupBox", "x310 y5 w280 h160 c" uiTheme[1], "Discord Webhook")  ; Box
    
    SettingsGUI.SetFont("s9", "Verdana")
    SettingsGUI.Add("Text", "x320 y30 c" uiTheme[1], "Webhook URL")     ; Webhook Text
    global WebhookURLBox := SettingsGUI.Add("Edit", "x320 y50 w260 h20 c" uiTheme[6])  ; Store webhook
    SettingsGUI.Add("Text", "x320 y83 c" uiTheme[1], "Discord ID (optional)")  ; Discord Id Text
    global DiscordUserIDBox := SettingsGUI.Add("Edit", "x320 y103 w260 h20 c" uiTheme[6])  ; Store Discord ID
    global SendActivityLogsBox := SettingsGUI.Add("Checkbox", "x320 y135 c" uiTheme[1], "Send Process")  ; Enable Activity

    ; Banner section
    SettingsGUI.Add("GroupBox", "x310 y175 w280 h100 c" uiTheme[1], "Banner Checker")  ; Box
    SettingsGUI.Add("Text", "x320 y195 c" uiTheme[1], "Banner Unit Name (Adding later)")  ; Banner Text
    global BannerUnitBox := SettingsGUI.Add("Edit", "x320 y215 w260 h20 c" uiTheme[6])  ; Store banner
    testBannerBtn := SettingsGUI.Add("Button", "x320 y240 w120 h25", "Test Banner")

    ; Private Server section
    SettingsGUI.Add("GroupBox", "x310 y280 w280 h100 c" uiTheme[1], "PS Link")  ; Box
    SettingsGUI.Add("Text", "x320 y300 c" uiTheme[1], "Private Server Link (optional)")  ; Ps text
    global PsLinkBox := SettingsGUI.Add("Edit", "x320 y320 w260 h20 c" uiTheme[6])  ;  ecit box

    SettingsGUI.Add("GroupBox", "x10 y10 w115 h70 c" uiTheme[1], "UI Navigation")
    SettingsGUI.Add("Text", "x20 y30 c" uiTheme[1], "Navigation Key")
    global UINavBox := SettingsGUI.Add("Edit", "x20 y50 w20 h20 c" uiTheme[6], "\")

    SettingsGUI.Add("GroupBox", "x160 y10 w115 h70 c" uiTheme[1], "Card Priority")
    ;SettingsGUI.Add("Text", "x170 y30 c" uiTheme[1], "Navigation Key")
    global PriorityPicker := SettingsGUI.Add("Button", "x170 y50 w95 h20", "Edit")

    PriorityPicker.OnEvent("Click", (*) => )

    ; Save buttons
    webhookSaveBtn := SettingsGUI.Add("Button", "x460 y135 w120 h25", "Save Webhook")
    webhookSaveBtn.OnEvent("Click", (*) => SaveWebhookSettings())

    bannerSaveBtn := SettingsGUI.Add("Button", "x460 y240 w120 h25", "Save Banner")
    bannerSaveBtn.OnEvent("Click", (*) => )

    PsSaveBtn := SettingsGUI.Add("Button", "x460 y345 w120 h25", "Save PsLink")
    PsSaveBtn.OnEvent("Click", (*) => SavePsSettings())

    UINavSaveBtn := SettingsGUI.Add("Button", "x50 y50 w60 h20", "Save")
    UINavSaveBtn.OnEvent("Click", (*) => SaveUINavSettings())

    ; Loadsettings
    if FileExist(WebhookURLFile)
        WebhookURLBox.Value := FileRead(WebhookURLFile, "UTF-8")
    if FileExist(DiscordUserIDFile)
        DiscordUserIDBox.Value := FileRead(DiscordUserIDFile, "UTF-8")
    if FileExist(SendActivityLogsFile)
        SendActivityLogsBox.Value := (FileRead(SendActivityLogsFile, "UTF-8") = "1")   
    if FileExist("Settings\BannerUnit.txt")
        BannerUnitBox.Value := FileRead("Settings\BannerUnit.txt", "UTF-8")
    if FileExist("Settings\PrivateServer.txt")
        PsLinkBox.Value := FileRead("Settings\PrivateServer.txt", "UTF-8")
    if FileExist("Settings\UINavigation.txt")
        UINavBox.Value := FileRead("Settings\UINavigation.txt", "UTF-8")

    ; Show the settings window
    SettingsGUI.Show("w600 h400")
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

aaMainUI.SetFont("s12 Bold c" uiTheme[1])
global settingsBtn := aaMainUI.Add("Button", "x1160 y0 w90 h30", "Settings")
settingsBtn.OnEvent("Click", ShowSettingsGUI)
global guideBtn := aaMainUI.Add("Button", "x1060 y0 w90 h30", "Guide")
guideBtn.OnEvent("Click", OpenGuide)

placementSaveBtn := aaMainUI.Add("Button", "x807 y405 w80 h20", "Save")
placementSaveBtn.OnEvent("Click", SaveSettings)
aaMainUI.SetFont("s9")
global NextLevelBox := aaMainUI.Add("Checkbox", "x900 y385 cffffff", "Next Level")
;global SkipLobby := aaMainUI.Add("Checkbox", "x1035 y385 cffffff Hidden Checked", "Skip Lobby")
global SkipLobby := aaMainUI.Add("Checkbox", "x900 y385 cffffff", "Skip Lobby")
;global ReturnLobbyBox := aaMainUI.Add("Checkbox", "x900 y385 cffffff Checked", "Return To Lobby")
global AutoAbilityBox := aaMainUI.Add("CheckBox", "x900 y410 cffffff Checked", "Auto Ability")
global ReturnLobbyBox := aaMainUI.Add("Checkbox", "x1143 y410 cffffff Checked", "Return To Lobby")
;global ChallengeBox := aaMainUI.Add("CheckBox", "x1143 y410 cffffff", "Auto Challenge")
global PriorityUpgrade := aaMainUI.Add("CheckBox", "x1005 y410 cffffff", "Priority Upgrade")
global PlacementPatternDropdown := aaMainUI.Add("DropDownList", "x1250 y662 w100 h180 Choose2 +Center", ["Circle", "Grid", "3x3 Grid", "Map Specific", "Spiral", "Up and Down", "Random", ])
PlacementPatternText := aaMainUI.Add("Text", "x1250 y642 w105 h20", "Placement Type")
PlaceSpeedText := aaMainUI.Add("Text", "x1123 y642 w115 h20", "Placement Speed")
global PlaceSpeed := aaMainUI.Add("DropDownList", "x1130 y662 w100 h180 Choose1 +Center", ["2.25 sec", "2 sec", "2.5 sec", "2.75 sec", "3 sec"])
placementSaveText := aaMainUI.Add("Text", "x807 y385 w80 h20", "Save Config")
Hotkeytext := aaMainUI.Add("Text", "x807 y35 w200 h30", "F1: Position roblox")
Hotkeytext2 := aaMainUI.Add("Text", "x807 y50 w200 h30", "F2: Start mango")
Hotkeytext3 := aaMainUI.Add("Text", "x807 y65 w200 h30", "F3: Stop mango")
GithubButton := aaMainUI.Add("Picture", "x30 y640 w40 h40 +BackgroundTrans cffffff", GithubImage)
DiscordButton := aaMainUI.Add("Picture", "x112 y645 w60 h34 +BackgroundTrans cffffff", DiscordImage)

GithubButton.OnEvent("Click", (*) => OpenGithub())
DiscordButton.OnEvent("Click", (*) => OpenDiscord())
;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS
;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT
global modeSelectionGroup := aaMainUI.Add("GroupBox", "x808 y38 w500 h45 Background" uiTheme[2], "Mode Select")
aaMainUI.SetFont("s10 c" uiTheme[6])
global ModeDropdown := aaMainUI.Add("DropDownList", "x818 y53 w140 h180 Choose0 +Center", ["Elemental Cavern", "Story", "Legend", "Raid"])
global StoryDropdown := aaMainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center", ["Story #1"])
;global StoryActDropdown := aaMainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6", "Infinity"])
global LegendDropDown := aaMainUI.Add("DropDownlist", "x968 y53 w150 h180 Choose0 +Center", ["Legend Stage #1"] )
;global LegendActDropdown := aaMainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3"])
global RaidDropdown := aaMainUI.Add("DropDownList", "x968 y53 w150 h180 Choose0 +Center", ["Marines Fort", "Hell City", "Snowy Capital", "Leaf Village", "Wanderniech", "Central City", "Giants District"])
;global RaidActDropdown := aaMainUI.Add("DropDownList", "x1128 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3", "Act 4", "Act 5"])
global ConfirmButton := aaMainUI.Add("Button", "x1218 y53 w80 h25", "Confirm")

StoryDropdown.Visible := false
;StoryActDropdown.Visible := false
LegendDropDown.Visible := false
;LegendActDropdown.Visible := false
RaidDropdown.Visible := false
;RaidActDropdown.Visible := false
SkipLobby.Visible := true
ReturnLobbyBox.Visible := true
NextLevelBox.Visible := false
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

AddUnitCard(aaMainUI, index, x, y) {
    unit := {}
 
    unit.Background := aaMainUI.Add("Text", Format("x{} y{} w550 h45 +Background{}", x, y, uiTheme[4]))
    unit.BorderTop := aaMainUI.Add("Text", Format("x{} y{} w550 h2 +Background{}", x, y, uiTheme[3]))
    unit.BorderBottom := aaMainUI.Add("Text", Format("x{} y{} w552 h2 +Background{}", x, y+45, uiTheme[3]))
    unit.BorderLeft := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x, y, uiTheme[3]))
    unit.BorderRight := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x+550, y, uiTheme[3]))
    unit.BorderRight := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x+250, y, uiTheme[3]))
    aaMainUI.SetFont("s11 Bold c" uiTheme[1])
    unit.Title := aaMainUI.Add("Text", Format("x{} y{} w60 h25 +BackgroundTrans", x+30, y+18), "Unit " index)

    aaMainUI.SetFont("s9 c" uiTheme[1])
    unit.PlacementText := aaMainUI.Add("Text", Format("x{} y{} w70 h20 +BackgroundTrans", x+100, y+2), "Placement")
    unit.PriorityText := aaMainUI.Add("Text", Format("x{} y{} w60 h20 BackgroundTrans hidden", x+180, y+2), "Upgrade")
    
    UnitData.Push(unit)
    return unit
}

;Create Unit slot
y_start := 85
y_spacing := 50
Loop 6 {
    AddUnitCard(aaMainUI, A_Index, 808, y_start + ((A_Index-1)*y_spacing))
}

enabled1 := aaMainUI.Add("CheckBox", "x818 y105 w15 h15", "")
enabled2 := aaMainUI.Add("CheckBox", "x818 y155 w15 h15", "")
enabled3 := aaMainUI.Add("CheckBox", "x818 y205 w15 h15", "")
enabled4 := aaMainUI.Add("CheckBox", "x818 y255 w15 h15", "")
enabled5 := aaMainUI.Add("CheckBox", "x818 y305 w15 h15", "")
enabled6 := aaMainUI.Add("CheckBox", "x818 y355 w15 h15", "")

aaMainUI.SetFont("s8 c" uiTheme[6])

; Placement dropdowns (x+100 = 908)
placement1 := aaMainUI.Add("DropDownList", "x908 y105 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
placement2 := aaMainUI.Add("DropDownList", "x908 y155 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
placement3 := aaMainUI.Add("DropDownList", "x908 y205 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
placement4 := aaMainUI.Add("DropDownList", "x908 y255 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
placement5 := aaMainUI.Add("DropDownList", "x908 y305 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
placement6 := aaMainUI.Add("DropDownList", "x908 y355 w60 h180 Choose1 +Center", ["1","2","3","4","5","6"])
; Upgrade priority dropdowns
Priority1 := aaMainUI.Add("DropDownList", "x990 y105 w60 h180 Choose1 +Center Hidden", ["1","2","3","4","5","6"])
Priority2 := aaMainUI.Add("DropDownList", "x990 y155 w60 h180 Choose2 +Center Hidden", ["1","2","3","4","5","6"])
Priority3 := aaMainUI.Add("DropDownList", "x990 y205 w60 h180 Choose3 +Center Hidden", ["1","2","3","4","5","6"])
Priority4 := aaMainUI.Add("DropDownList", "x990 y255 w60 h180 Choose4 +Center Hidden", ["1","2","3","4","5","6"])
Priority5 := aaMainUI.Add("DropDownList", "x990 y305 w60 h180 Choose5 +Center Hidden", ["1","2","3","4","5","6"])
Priority6 := aaMainUI.Add("DropDownList", "x990 y355 w60 h180 Choose6 +Center Hidden", ["1","2","3","4","5","6"])
PriorityUpgrade.OnEvent("Click", TogglePriorityDropdowns)

readInSettings()
aaMainUI.Show("w1366 h700")
WinMove(0, 0,,, "ahk_id " aaMainUIHwnd)
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
    if FileExist("Settings\SendActivityLogs.txt") {
        SendActivityLogsStatus := FileRead("Settings\SendActivityLogs.txt", "UTF-8")
        if (SendActivityLogsStatus = "1") {
            WebhookLog()
        }
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
    global aaMainUIHwnd, offsetX, offsetY, rblxID
    
    if !WinExist(rblxID) {
        AddToLog("Waiting for Roblox window...")
        return
    }

    ; First ensure correct size
    sizeDown()
    
    ; Then move relative to main UI
    WinGetPos(&x, &y, &w, &h, aaMainUIHwnd)
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

