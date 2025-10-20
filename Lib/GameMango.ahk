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
    if (StartsInLobby(ModeDropdown.Text)) {
        if (ok := FindText(&X, &Y, 7, 590, 37, 618, 0, 0, LobbySettings)) {
            StartSelectedMode()
        } else {
            AddToLog("You need to be in the lobby to start " ModeDropdown.Text " mode")
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

StartPlacingUnits(untilSuccessful := true) {
    global successfulCoordinates, maxedCoordinates
    successfulCoordinates := []
    maxedCoordinates := []
    placedCounts := Map()  

    ; --- Priority Setup ---
    global slotPriority := Map(1, 2, 2, 1, 3, 3)  ; Customize as needed
    usePriorityPlacement := true  ; <- Toggle to enable/disable priority mode

    ; --- Check if any slot is enabled ---
    anyEnabled := false
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := "enabled" slotNum
        enabled := %enabled%
        enabled := enabled.Value
        if (enabled) {
            anyEnabled := true
            break
        }
    }

    if (!anyEnabled) {
        AddToLog("No units enabled - skipping to monitoring")
        return MonitorStage()
    }

    ; --- Placement Order Logic ---
    if (PlacementSelection.Text = "By Priority") {
        global slotPriorityList := []

        ; Build list of enabled slots and their priorities
        for slotNum in [1, 2, 3, 4, 5, 6] {
            priorityVar := "priority" slotNum
            enabledVar := "enabled" slotNum

            priority := %priorityVar%
            enabled := %enabledVar%

            if (enabled.Value) {
                slotPriorityList.Push({slot: slotNum, priority: priority.Value})
            }
        }

        ; Manually sort the list by priority (ascending)
        Loop slotPriorityList.Length {
            for i, item in slotPriorityList {
                if (i = slotPriorityList.Length)
                    continue
                if (slotPriorityList[i].priority > slotPriorityList[i + 1].priority) {
                    temp := slotPriorityList[i]
                    slotPriorityList[i] := slotPriorityList[i + 1]
                    slotPriorityList[i + 1] := temp
                }
            }
        }

        ; Extract sorted slot numbers into placementOrder
        placementOrder := []

        for item in slotPriorityList {
            placementOrder.Push(item.slot)
        }
    } else {
        placementOrder := PlacementSelection.Text = "Slot #2 First" ? [2, 1, 3, 4, 5, 6] : [1, 2, 3, 4, 5, 6]
    }

    placementStrategies := Map(
        "Map Specific", UseRecommendedPoints,
        "Custom", UseCustomPoints,
        "Circle", GenerateCirclePoints,
        "Grid", GenerateGridPoints,
        "Spiral", GenerateSpiralPoints,
        "Up and Down", GenerateUpandDownPoints
    )

    ; Get the selected text
    selection := PlacementPatternDropdown.Text

    ; Call mapped function if it exists, else use fallback
    if placementStrategies.Has(selection)
        placementPoints := placementStrategies[selection].Call()
    else
        placementPoints := GenerateRandomPoints()

    ; Use user-defined placement order to iterate through slots
    for slotNum in placementOrder {
        enabled := "enabled" slotNum
        enabled := %enabled%
        enabled := enabled.Value

        ; Get number of placements wanted for this slot
        placements := "placement" slotNum
        placements := %placements%
        placements := Integer(placements.Text)

        ; Initialize count if not exists
        if !placedCounts.Has(slotNum)
            placedCounts[slotNum] := 0

        ; If enabled, place all units for this slot
        if (enabled && placements > 0) {
            HandleStartButton() ; Check for start button if placement failed
            AddToLog("Placing Unit " slotNum " (0/" placements ")")
            
            for point in placementPoints {
                ; Skip if this coordinate was already used successfully
                alreadyUsed := false
                for coord in successfulCoordinates {
                    if (coord.x = point.x && coord.y = point.y) {
                        alreadyUsed := true
                        break
                    }
                }
                for coord in maxedCoordinates {
                    if (coord.x = point.x && coord.y = point.y) {
                        alreadyUsed := true
                        break
                    }
                }
                if (alreadyUsed)
                    continue

                ; If untilSuccessful is false, try once and move on
                if (!untilSuccessful) {
                    if (placedCounts[slotNum] < placements) {
                        if PlaceUnit(point.x, point.y, slotNum) {
                            placementIndex := successfulCoordinates.Length + 1
                            if (HasMinionInSlot(slotNum)) {
                                successfulCoordinates.Push({
                                    x: point.x,
                                    y: point.y,
                                    slot: slotNum,
                                    upgradePriority: GetUpgradePriority(slotNum),
                                    placementIndex: placementIndex
                                })
                                placementIndex += 1
                            }
                            successfulCoordinates.Push({
                                x: point.x,
                                y: point.y,
                                slot: slotNum,
                                upgradePriority: GetUpgradePriority(slotNum),
                                placementIndex: placementIndex
                            })
                            placedCounts[slotNum] += 1
                            AddToLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                            if (!NukeUnitSlotEnabled.Value && slotNum != NukeUnitSlot.Value) {
                                HandleAutoAbility(slotNum)
                            }
                            SendInput("X")
                            ;AttemptUpgrade()
                            UpgradePlacedUnits()
                        } else {
                            PostPlacementChecks()
                        }
                    }
                }
                ; If untilSuccessful is true, keep trying the same point until it works
                else {
                    while (placedCounts[slotNum] < placements) {
                        if PlaceUnit(point.x, point.y, slotNum) {
                            placementIndex := successfulCoordinates.Length + 1

                            if (HasMinionInSlot(slotNum)) {
                                successfulCoordinates.Push({
                                x: point.x,
                                y: point.y,
                                slot: slotNum,
                                upgradePriority: GetUpgradePriority(slotNum),
                                placementIndex: placementIndex
                                })
                            }

                            successfulCoordinates.Push({
                                x: point.x,
                                y: point.y,
                                slot: slotNum,
                                upgradePriority: GetUpgradePriority(slotNum),
                                placementIndex: placementIndex
                            })
                            placedCounts[slotNum] += 1
                            AddToLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                            if (!NukeUnitSlotEnabled.Value && slotNum != NukeUnitSlot.Value) {
                                HandleAutoAbility(slotNum)
                            }
                            SendInput("X")
                            UpgradePlacedUnits()
                            break ; Move to the next placement spot
                        }
                        UpgradePlacedUnits()
                        PostPlacementChecks()
                        Sleep(500) ; Prevents spamming clicks too fast
                    }
                }

                if CheckForXp()
                    return MonitorStage()
            }
        }
    }

    AddToLog("All units placed to requested amounts")
    UpgradeUnits()
}

PlaceDungeonUnits() {
    placementPoints := PlacementPatternDropdown.Text = "Custom" ? UseCustomPoints() : GenerateDungeonPoints()

    ; Collect enabled slots
    enabledSlots := []
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := "enabled" slotNum
        enabled := %enabled%
        enabled := enabled.Value
        if (enabled) {
            enabledSlots.Push(slotNum)
        }
    }

    if (enabledSlots.Length = 0) {
        if (debugMessages) {
            AddToLog("No units enabled - exiting")
        }
        return
    }

    ; Loop through placement points and assign them to enabled slots in order
    pointIndex := 1
    while true {
        for slotIndex, slotNum in enabledSlots {
            point := placementPoints[pointIndex]
            if PlaceUnit(point.x, point.y, slotNum) {
                SendInput("{T}")
                HandleAutoAbility(slotNum)
                FixClick(700, 560) ; Move Click
            }
            Sleep(500) ; Prevent spamming

            ; Move to the next placement point, loop back if at the end
            pointIndex++
            if (pointIndex > placementPoints.Length) {
                pointIndex := 1
            }
        }
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
        if (HasCards(ModeDropdown.Text)) {
            CheckForCardSelection()
        }

        CheckForPortalSelection()

        ; --- Fallback if disconnected ---
        Reconnect()

        ; --- Wait for XP/Results screen ---
        if (!CheckForXp())
            continue

        ; --- Handle Auto Ability ---
        if (AutoAbilityBox.Value && UnitManagerAutoUpgrade.Value) {
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
        
        if (AutoAbilityBox.Value && UnitManagerAutoUpgrade.Value) {
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

    WalkToCoords()

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

Reconnect(testing := false) {
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    if (FindText(&X, &Y, 202, 206, 601, 256, 0.10, 0.10, Disconnect) || testing) {

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
                deepLink := "roblox://experiences/start?placeId=12886143095&linkCode=" serverCode
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
            Run("roblox://placeID=12886143095")
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
            Sleep(1000)
        }

        if (isInLobby()) {
            AddToLog("Reconnected Successfully!")
            return StartSelectedMode()
        } else {
            Reconnect()
        }
    }
}

PlaceUnit(x, y, slot := 1) {
    ; Select the unit slot
    SendInput(slot)
    Sleep 300  ; Slightly reduced for responsiveness

    ; First click to prepare placement
    FixClick(x, y)
    Sleep 75

    ; Confirm placement with 'x' key
    SendInput("x")
    Sleep 500

    wiggle()

    ; Second click to confirm the placement location
    FixClick(x, y)
    Sleep 75

    ; Check if the unit was successfully placed
    if (UnitPlaced()) {
        return true
    }

    return false
}

MaxUpgrade() {
    Sleep 500
    ; Check for max text
    if (ok := FindText(&X, &Y, 97, 387, 166, 407, 0.20, 0.20, MaxUpgradeText)) {
        return true
    }
    return false
}

UnitPlaced() {
    if (WaitForUpgradeText(GetPlacementSpeed())) { ; Wait up to 4.5 seconds for the upgrade text to appear
        AddToLog("Unit Placed Successfully")
        return true
    }
    return false
}

HandleAutoAbility(slotNum) {
    if !AutoAbilityBox.Value
        return

    if (NukeUnitSlotEnabled.Value && slotNum == NukeUnitSlot.Value) {
        return
    }

    wiggle()

    pixelChecks := [
        {color: 0xC22725, x: 539, y: 285},
        {color: 0xC22725, x: 539, y: 268},
        {color: 0xC22725, x: 539, y: 303},

        {color: 0xC22725, x: 326, y: 284}, ; Left Side
        {color: 0xC22725, x: 326, y: 265},
        {color: 0xC22725, x: 326, y: 303}
    ]

    for pixel in pixelChecks {
        if GetPixel(pixel.color, pixel.x, pixel.y, 4, 4, 20) {
            AddToLog("Enabled Auto Ability")
            FixClick(pixel.x, pixel.y)
            Sleep(500)
        }
    }
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

    if (ModeDropdown.Text != "Custom") {
        CloseLobbyPopups()
    }

    if (ModeDropdown.Text = "Dungeon") {
        StartDungeonMode
    }
    else if (ModeDropdown.Text = "Story") {
        StartStoryMode()
    }
    else if (ModeDropdown.Text = "Boss Rush") {
        StartBossRush()
    }
    else if (ModeDropdown.Text = "Raid") {
        StartRaidMode()
    }
    else if (ModeDropdown.Text = "Custom") {
        CustomMode()
    }
    else if (ModeDropdown.Text = "Portal") {
        StartPortalMode()
    }
    else if (ModeDropdown.Text = "Survival") {
        StartSurvivalMode()
    }
    else if (ModeDropdown.Text = "Halloween Event") {
        StartHalloweenEvent()
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

GetPlacementSpeed() {
    speeds := [1000, 1500, 2000, 2500, 3000, 4000]  ; Array of sleep values
    speedIndex := PlaceSpeed.Value  ; Get the selected speed value

    if speedIndex is number  ; Ensure it's a number
        return speeds[speedIndex]  ; Use the value directly from the array
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

PostPlacementChecks() {
    HandleStartButton()

    if (CheckForLobby()) {
        AddToLog("Found in lobby, restarting mode if possible")
        return CheckLobby()
    }

    if CheckForXp() {
        return MonitorStage()
    }

    if (HasCards(ModeDropdown.Text)) {
        CheckForCardSelection()
    }

    CheckForPortalSelection()

    Reconnect()

}

HandleStageEnd(waveRestart := false) {
    global challengeStartTime
    AddToLog("Stage ended during upgrades, proceeding to results")
    ResetPlacementTracking()
    return MonitorStage()
}

ResetPlacementTracking() {
    global successfulCoordinates, maxedCoordinates
    successfulCoordinates := []
    maxedCoordinates := []
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
    static modes := ["Story", "Boss Rush", "Raid", "Challenge", "Dungeon", "Portal", "Survival", "Halloween Event"]
    
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
    static modesWithCards := ["Boss Rush", "Halloween Event"]
    
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