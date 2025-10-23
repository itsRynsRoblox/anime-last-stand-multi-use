#Requires AutoHotkey v2.0
#Include %A_ScriptDir%/lib/Tools/Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount
global cachedCardPriorities := Map()
LoadKeybindSettings()  ; Load saved keybinds
Hotkey(F1Key, (*) => moveRobloxWindow())
Hotkey(F2Key, (*) => StartMacro())
Hotkey(F3Key, (*) => Reload())
Hotkey(F4Key, (*) => TogglePause())

F5:: {

}

F6:: {

}

F7:: {
    CopyMouseCoords(false)
}

F8:: {
    Run (A_ScriptDir "\Lib\Tools\FindText.ahk")
}

StartMacro(*) {
    if (!ValidateMode()) {
        return
    }
    if (StartsInLobby(ModeDropdown.Text) || StartsInLobby(EventDropdown.Text)) {
        if (ok := FindText(&X, &Y, 7, 590, 37, 618, 0, 0, LobbySettings)) {
            StartSelectedMode()
        } else {
            AddToLog("You need to be in the lobby to start " ModeDropdown.Text)
        }
    } else {
        StartSelectedMode()
    }
}

TogglePause(*) {
    Pause -1
    if (A_IsPaused) {
        AddToLog("Macro Paused")
        Sleep(1000)
    } else {
        AddToLog("Macro Resumed")
        Sleep(1000)
    }
}

CheckForXp() {
    return FindText(&X, &Y, 225, 217, 356, 246, 0.20, 0.20, Results)
}

ChallengeMode() {    
    AddToLog("Moving to Challenge mode")
    ChallengeMovement()
    
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, Story)) {
        ChallengeMovement()
    }

    RestartStage()
}

CustomMode() {
    AddToLog("Starting Custom Mode")
    RestartStage()
}

HandleEndScreen(isVictory := true) {
    Switch ModeDropdown.Text {
        Case "Story":
            HandleStoryEnd()
        Case "Portal":
            HandlePortalEnd(isVictory)
        case "Custom":
            HandleCustomEnd()    
        Default:
            HandleDefaultEnd()
    }
}

HandleStoryEnd() {
    global lastResult
    AddToLog("Handling Story mode end")
    if (NextLevelBox.Value && lastResult = "win") {
        AddToLog("Next level")
        ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyIcon, +260, -35)
    } else {
        AddToLog("Replay level")
        ClickReplay()
    }
    return RestartStage()
}

HandleCustomEnd() {
    global lastResult
    if (NextLevelBox.Value) {
        if (lastResult = "win") {
            AddToLog("[Game Over] Starting next level")
            ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyIcon, +260, -35)
            return RestartStage()
        }
    } else {
        AddToLog("[Game Over] Replaying stage")
        ClickReplay()
        return RestartStage()
    }
}

HandleDefaultEnd() {
    AddToLog("[Game Over] Restarting stage")
    ClickReplay()
    return RestartStage()
}

MonitorStage() {
    global Wins, loss, mode, stageStartTime

    lastClickTime := A_TickCount

    ; Initial anti-AFK click
    FixClick(400, 500)

    Loop {
        Sleep(1000)

        ; --- Anti-AFK ---
        if ((A_TickCount - lastClickTime) >= 10000) {
            FixClick(400, 500)
            lastClickTime := A_TickCount
        }

        ; --- Check for progression or special cases ---
        if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
            CheckForCardSelection()
        }

        CheckForPortalSelection()

        ; --- Fallback if disconnected ---
        Reconnect()

        ; --- Wait for XP/Results screen ---
        if (!CheckForXp())
            continue

        ; --- Handle Auto Ability ---
        if (AutoAbilityBox.Value) {
            SetTimer(CheckAutoAbility, 0)
        }

        if (NukeUnitSlotEnabled.Value) {
            ClearNuke()
        }

        ; --- Close Menus ---
        CloseMenu("Unit Manager")
        Sleep(500)
        CloseMenu("Ability Manager")

        ; --- Endgame Handling ---
        AddToLog("Checking win/loss status")
        stageEndTime := A_TickCount
        stageLength := FormatStageTime(stageEndTime - stageStartTime)
        result := false
        if (FindText(&X, &Y, 357, 253, 454, 310, 0.20, 0.20, Victory) || FindText(&X, &Y, 255, 118, 555, 418, 0.20, 0.20, Cleared)) {
            result := true
        } else if (FindText(&X, &Y, 357, 253, 454, 310, 0, 0, Defeat)) {
            result := true
        }

        AddToLog((result ? "Victory" : "Defeat") " detected - Stage Length: " stageLength)

        if (WebhookEnabled.Value) {
            try {
                SendWebhookWithTime(result, stageLength)
            } catch {
                AddToLog("Error: Unable to send webhook.")
            }
        } else {
            UpdateStreak(result)
        }

        HandleEndScreen(result)
        Reconnect()
        return
    }
}

ClickThroughDrops() {
    AddToLog("Clicking through item drops...")
    Loop 10 {
        FixClick(400, 495)
        Sleep(500)
        if CheckForXp() {
            return
        }
    }
}

CheckForPortalSelection() {
    if (ok := FindText(&X, &Y, 356, 436, 447, 455, 0, 0, ChoosePortal) or (ok := FindText(&X, &Y, 356, 436, 447, 455, 0.10, 0.10, ChoosePortalHighlighted))) {
        
        if (AutoAbilityBox.Value) {
            CloseMenu("Ability Manager")
            SetTimer(CheckAutoAbility, 0)
        }

        CloseMenu("Unit Manager")
        FixClick(399, 299)
        Sleep(500)
        FixClick(402, 414)

        ; Wait before checking for another portal
        Sleep(1500)

        if (ok := FindText(&X, &Y, 356, 436, 447, 455, 0, 0, ChoosePortal) or (ok := FindText(&X, &Y, 356, 436, 447, 455, 0.10, 0.10, ChoosePortalHighlighted))) {
            FixClick(399, 299)
            Sleep(500)
            FixClick(402, 414)
        }
        
        return true
    }

    return false
}

ChallengeMovement() {
    FixClick(765, 475)
    Sleep (500)
    FixClick(300, 415)
    SendInput ("{a down}")
    sleep (7000)
    SendInput ("{a up}")
}

StartContent(mapName, actName, getMapFunc, getActFunc, mapScrollMousePos, actScrollMousePos) {
    ;AddToLog("Selecting : " mapName " - " actName)

    ; Get the map
    Map := getMapFunc.Call(mapName)
    if !Map {
        AddToLog("Error: Map '" mapName "' not found.")
        return false
    }

    ; Scroll map if needed
    if Map.scrolls > 0 {
        AddToLog(Format("Scrolling down {} times for {}", Map.scrolls, mapName))
        MouseMove(mapScrollMousePos.x, mapScrollMousePos.y)
        Scroll(Map.scrolls, 'WheelDown', 250)
    }

    Sleep(1000)
    FixClick(Map.x, Map.y)
    Sleep(1000)

    ; Get the act
    Act := getActFunc.Call(actName)
    if !Act {
        AddToLog("ERROR: Act '" actName "' not found.")
        return false
    }

    ; Scroll act if needed
    if Act.scrolls > 0 {
        AddToLog(Format("Scrolling down {} times for {}", Act.scrolls, actName))
        MouseMove(actScrollMousePos.x, actScrollMousePos.y)
        Scroll(Act.scrolls, 'WheelDown', 250)
    }

    Sleep(1000)
    FixClick(Act.x, Act.y)
    Sleep(1000)

    return true
}

PlayHere(mode := "Story") {
    if (mode = "Story") {
        FixClick(400, 415)
        Sleep (300)
        FixClick(570, 405)
        Sleep (300)
    }
    else if (mode = "Raid") {
        FixClick(399, 413)
        Sleep (300)
        FixClick(570, 433)
    }
    else if (mode = "Dungeon" || mode = "Survival") {
        FixClick(301, 421)
        Sleep (300)
        FixClick(570, 433)
    }
}

Zoom() {
    WinActivate(rblxID)
    Sleep 100
    MouseMove(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Scroll(20, "WheelUp", 50)

    ; Look down
    Click
    MouseMove(400, 400)  ; Move mouse down to angle camera down
    
    ; Zoom back out smoothly
    Scroll(Integer(ZoomBox.Value), "WheelDown", 50)
    
    ; Move mouse back to center
    MouseMove(400, 300)
}

TeleportToSpawn() {
    FixClick(233, 10) ;click settings
    Sleep 300
    FixClick(464, 219) ;click tp to spawn
    Sleep 300
    FixClick(233, 10) ;click settings
    Sleep 300
}

RestartMatch() {
    FixClick(233, 10) ;click settings
    Sleep 300
    FixClick(338, 253) ;click restart match
    Sleep 3500
}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        AddToLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup(usedButton := false) {
    global firstStartup

    ; Skip setup entirely if Seamless is enabled
    if (SeamlessToggle.Value) {
        if (!firstStartup) {
            AddToLog("Seamless mode enabled. Skipping setup.")
            return
        }
    }

    ; Close various UI elements

    CloseChat()
    Sleep 300

    if (ModeDropdown.Text = "Custom" && SeamlessToggle.Value && !usedButton || ModeDropdown.Text == "Portal" && SeamlessToggle.Value) {
        return
    }

    Zoom()

    ; Teleport to spawn
    TeleportToSpawn()

    FixClick(487, 72) ; Closes Player leaderboard
    Sleep 300

    if (EventDropdown.Text = "Halloween P2") {
        WalkToHalloweenPath()
    } else {
        WalkToCoords()
    }

    if (SeamlessToggle.Value && !usedButton) {
        firstStartup := false
    }
}

DetectMap() {
    if (ModeDropdown.Text = "Raid") {
        AddToLog("Map selected: " RaidDropdown.Text)
        return RaidDropdown.Text
    } else if (ModeDropdown.Text = "Story") {
        AddToLog("Map selected: " StoryDropdown.Text)
        return StoryDropdown.Text
    } else if (ModeDropdown.Text = "Dungeon") {
        AddToLog("Map selected: " DungeonDropdown.Text)
        return DungeonDropdown.Text
    } else if (ModeDropdown.Text = "Portal") {
        return PortalDropdown.Text
    } else {
        return "no map found"
    }
}

HandleMapMovement(MapName) {
    AddToLog("Executing Movement for: " MapName)
    
    switch MapName {
        case "Central City":
            MoveForCentralCity()
    }
}

MoveForCentralCity() {
    Fixclick(390, 29, "Right")
    Sleep (5000)
}

    
RestartStage() {
    
    ; Wait for loading
    CheckLoaded()

    BasicSetup()

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    StartPlacingUnits(PlacementPatternDropdown.Text == "Custom" || PlacementPatternDropdown.Text = "Map Specific")
    
    ; Monitor stage progress
    MonitorStage()
}

RestartCustomStage() {
    if (!SeamlessToggle.Value) {
        currentMap := DetectMap()
    
        ; Wait for loading
        CheckLoaded()
    
        ; Do initial setup and map-specific movement during vote timer
        BasicSetup()
        if (currentMap != "no map found") {
            HandleMapMovement(currentMap)
        }
    }

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    StartPlacingUnits(PlacementPatternDropdown.Text == "Custom" || PlacementPatternDropdown.Text = "Map Specific")
    
    ; Monitor stage progress
    MonitorStage()
}

Reconnect(force := false) {
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    if (FindText(&X, &Y, 202, 206, 601, 256, 0.10, 0.10, Disconnect) || force) {

        ; Wait until internet is available
        while !isConnectedToInternet() {
            AddToLog("❌ No internet connection. Waiting to reconnect...")
            Sleep(5000) ; wait 5 seconds before checking again
        }

        AddToLog("✅ Internet connection verified, attempting to reconnect...")
        sendDCWebhook()

        if (PrivateServerEnabled.Value) {
            psLink := PrivateServerURLBox.Value
            if (psLink != "") {
                serverCode := GetPrivateServerCode(psLink)
                deepLink := "roblox://experiences/start?placeId=107573139811370&linkCode=" serverCode
                if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
                    WinClose("ahk_exe RobloxPlayerBeta.exe")
                    Sleep(3000)
                }
                AddToLog("Connecting to your private server...")
                Run(serverCode = "" ? psLink : deepLink)
                loop {
                    if WinWait("ahk_exe RobloxPlayerBeta.exe", , 15) {
                        AddToLog("New Roblox Window Found!")
                        break
                    } else {
                        AddToLog("Waiting for new Roblox Window...")
                        Sleep(1000)
                    }
                }
            }
        } else {
            Run("roblox://placeID=107573139811370")
            while (isInLobby()) {
                Sleep(100)
            }
        }

        AddToLog("Reconnecting to " GameName "...")

        while (!isInLobby()) {
            if (WinExist(rblxID)) {
                WinActivate(rblxID)
                sizeDown()
            }

            if (PrivateServerEnabled.Value) {
                psLink := PrivateServerURLBox.Value
                if (psLink != "") {
                    serverCode := GetPrivateServerCode(psLink)
                    deepLink := "roblox://experiences/start?placeId=12886143095&linkCode=" serverCode
                    if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
                        WinClose("ahk_exe RobloxPlayerBeta.exe")
                        Sleep(3000)
                    }
                    AddToLog("Retrying private server connection...")
                    Run(serverCode = "" ? psLink : deepLink)
                    WinWait("ahk_exe RobloxPlayerBeta.exe", , 15)
                }
            } else {
                Run("roblox://placeID=12886143095")
                WinWait("ahk_exe RobloxPlayerBeta.exe", , 15)
            }
        }

        Sleep(1000)
        AddToLog("Reconnected Successfully!")
        return StartSelectedMode()
    }
}

MaxUpgrade() {
    Sleep 500
    ; Check for max text
    if (ok := FindText(&X, &Y, 97, 387, 166, 407, 0.20, 0.20, MaxUpgradeText)) {
        return true
    }
    return false
}

HandleAutoAbilityUnitManager() {
    if !AutoAbilityBox.Value
        return

    wiggle()

    ; Grid configuration
    baseX    := 675            ; Left column starting X
    xOffset  := 95             ; Distance between columns
    baseY    := 130            ; Top row starting Y
    yStep    := 60             ; Vertical gap between rows
    numRows  := 8              ; Total rows to scan
    numCols  := 2              ; Columns per row
    color    := 0xC22725       ; Target pixel color

    ; Scan grid
    Loop numRows {
        rowIndex := A_Index - 1
        rowY := baseY + rowIndex * yStep

        Loop numCols {
            colIndex := A_Index - 1
            colX := baseX + colIndex * xOffset

            if GetPixel(color, colX, rowY, 4, 4, 20) {
                FixClick(colX, rowY)
                Sleep(100)
            }
        }
    }
}

wiggle() {
    MouseMove(1, 1, 5, "R")
    Sleep(30)
    MouseMove(-1, -1, 5, "R")
}

UpgradeUnit(x, y) {
    FixClick(x, y)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
}

CheckLobby() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 8, 589, 37, 619, 0, 0, LobbySettings)) {
            break
        }
        Reconnect()
    }
    AddToLog("Returned to lobby, restarting selected mode")
    return StartSelectedMode()
}

CheckForLobby() {
    return FindText(&X, &Y, 8, 589, 37, 619, 0, 0, LobbySettings)
}

CheckLoaded() {
    loop {
        Sleep(500)
        
        if (ok := FindText(&X, &Y, 14, 596, 39, 616, 0.20, 0.20, IngameQuests)) {
            AddToLog("Successfully Loaded In")
            Sleep(500)
            break
        }

        Reconnect()
    }
}

StartedGame() {
    AddToLog("Game started")
    global stageStartTime := A_TickCount
    StartNukeTimer()
}

StartSelectedMode() {

    if (StartsInLobby(ModeDropdown.Text) || StartsInLobby(EventDropdown.Text)) {
        CloseLobbyPopups()
    }

    switch (ModeDropdown.Text) {
        case "Dungeon":
            StartDungeonMode()
        case "Story":
            StartStoryMode()
        case "Boss Rush":
            StartBossRush()
        case "Raid":
            StartRaidMode()
        case "Custom":
            CustomMode()
        case "Portal":
            StartPortalMode()
        case "Survival":
            StartSurvivalMode()
        case "Event":
            StartEvent()
    }
}

FormatStageTime(ms) {
    seconds := Floor(ms / 1000)
    minutes := Floor(seconds / 60)
    hours := Floor(minutes / 60)
    
    minutes := Mod(minutes, 60)
    seconds := Mod(seconds, 60)
    
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}

ValidateMode() {
    if (ModeDropdown.Text = "") {
        AddToLog("Please select a gamemode before starting the macro!")
        return false
    }
    if (!confirmClicked) {
        AddToLog("Please click the confirm button before starting the macro!")
        return false
    }
    return true
}

GetNavKeys() {
    return StrSplit(FileExist("Settings\UINavigation.txt") ? FileRead("Settings\UINavigation.txt", "UTF-8") : "\,#,}", ",")
}

ClickUntilGone(x, y, searchX1, searchY1, searchX2, searchY2, textToFind, offsetX:=0, offsetY:=0, textToFind2:="") {
    while (ok := FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind) || 
           textToFind2 && FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind2)) {
        if (offsetX != 0 || offsetY != 0) {
            FixClick(X + offsetX, Y + offsetY)  
        } else {
            FixClick(x, y) 
        }
        Sleep(1000)
    }
}

ClickReturnToLobby() {
    ClickUntilGone(0, 0, 238, 400, 566, 445, LobbyIcon, 0, -35)
}

ClickReplay() {
    ClickUntilGone(0, 0, 238, 400, 566, 445, Retry, 0, -25)
}

SetupForInfinite() {
    ChangeCameraMode("Follow")
    Sleep (1000)
    ZoomIn()
    Sleep (1000)
    ZoomOut()
    ChangeCameraMode("Default (Classic)")
    Sleep (1000)
    SendInput ("{a down}")
    Sleep 2000
    SendInput ("{a up}")
    KeyWait "a"
}

ChangeCameraMode(mode := "") {
    AddToLog("Changing camera mode to " mode)
    SendInput("{Escape}") ; Open Roblox Menu
    Sleep (1000)
    FixClick(205, 90) ; Click Settings
    Sleep (1000)
    loop 2 {
        FixClick(336, 209) ; Change Camera Mode
        Sleep (500)
    }
    SendInput("{Escape}") ; Open Roblox Menu
}

ZoomIn() {
    MouseMove 400, 300
    Sleep 100
    FixClick(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Loop 12 {
        Send "{WheelUp}"
        Sleep 50
    }

    ; Right-click and drag camera down
    Sleep 100
    MouseMove 400, 300  ; Ensure starting point
    Click "Right Down"
    Sleep 50
    MouseMove 400, 400, 20  ; Drag downward over 20ms
    Sleep 50
    Click "Right Up"
    Sleep 100
}

ZoomOut() {
    ; Zoom out smoothly
    Loop 10 {
        Send "{WheelDown}"
        Sleep 50
    }

    ; Move mouse back to center
    MouseMove 400, 300
}

DetectAngle(mode := "Story") {
    switch mode {
        case "Story":
            firstAngle := GetPixel(0xAC7841, 407, 92, 2, 2, 10)
            secondAngle := GetPixel(0xD77106, 407, 92, 2, 2, 10)
            if (firstAngle) {
                AddToLog("Spawn Angle: Left")
                return 1
            } else if (secondAngle) {
                AddToLog("Spawn Angle: Right")
                return 2
            } else {
                AddToLog("Spawn Angle: Unknown | Color: " PixelGetColor(407, 92) )
                return 3
            }

        case "Raid":
            firstAngle := GetPixel(0xB74D0D, 414, 49, 2, 2, 10)
            secondAngle := GetPixel(0x71250F, 414, 49, 2, 2, 10)
            if (firstAngle) {
                AddToLog("Spawn Angle: Left")
                return 1
            } else if (secondAngle) {
                AddToLog("Spawn Angle: Right")
                return 2
            } else {
                AddToLog("Spawn Angle: Unknown | Color: " PixelGetColor(414, 49) )
                return 3
            }
    }
    return 0
}

HandleStageEnd(waveRestart := false) {
    AddToLog("Stage ended during upgrades, proceeding to results")
    ResetPlacementTracking()
    return MonitorStage()
}

CheckForStartButton() {
    return FindText(&X, &Y, 319, 536, 396, 558, 0.10, 0.10, StartButton)
}

HandleStartButton() {
    if (CheckForStartButton()) {
        AddToLog("Start button found, clicking to start stage")
        FixClick(355, 515) ; Click the start button
        Sleep(500)
    }
}

StartsInLobby(ModeName) {
    ; Array of modes that usually start in lobby
    static modes := ["Story", "Boss Rush", "Raid", "Challenge", "Dungeon", "Portal", "Survival", "Event"]
    
    ; Special case: If PortalLobby.Value is set, don't start in lobby for "Portal"
    if (ModeName = "Portal" && !PortalLobby.Value)
        return false

    ; Check if current mode is in the array
    for mode in modes {
        if (mode = ModeName)
            return true
    }
    return false
}

HasCards(ModeName) {
    ; Array of modes that have card selection
    static modesWithCards := ["Boss Rush", "Halloween", "Halloween P2"]
    
    ; Check if current mode is in the array
    for mode in modesWithCards {
        if (mode = ModeName)
            return true
    }
    return false
}

isMenuOpen(name := "") {
    if (name = "Unit Manager") {
        return FindText(&X, &Y, 700, 142, 789, 166, 0.20, 0.20, UnitManager) or FindText(&X, &Y, 679, 595, 782, 616, 0.20, 0.20, UnitManagerDark)
    }
    else if (name = "Ability Manager") {
        return FindText(&X, &Y, 675, 594, 785, 616, 0.20, 0.20, AbilityManager)
    }
    else if (name = "Story") {
        return FindText(&X, &Y, 302, 432, 401, 456, 0.20, 0.20, StorySelectButton)
    }
    else if (name = "End Screen") {
        return FindText(&X, &Y, 225, 217, 356, 246, 0.20, 0.20, Results)
    }
    else if (name = "Boss Rush") {
        return FindText(&X, &Y, 333, 439, 367, 454, 0.20, 0.20, BossRushEnter)
    }
    else if (name = "Survival") {
        return FindText(&X, &Y, 284, 443, 328, 462, 0.20, 0.20, SurvivalSelect)
    }
    else if (name = "Card Selection") {
        return GetPixel(0x4A4747, 436, 383, 2, 2, 3)
    }
}