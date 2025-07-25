#Requires AutoHotkey v2.0
#Include Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount

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
    CopyMouseCoords(true)
}

F8:: {
    Run (A_ScriptDir "\Lib\FindText.ahk")
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
                            successfulCoordinates.Push({x: point.x, y: point.y, slot: slotNum})
                            placedCounts[slotNum] += 1
                            AddToLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                            HandleAutoAbility()
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

                            successfulCoordinates.Push({
                                x: point.x,
                                y: point.y,
                                slot: slotNum,
                                upgradePriority: GetUpgradePriority(slotNum),
                                placementIndex: placementIndex
                            })
                            placedCounts[slotNum] += 1
                            AddToLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                            HandleAutoAbility()
                            SendInput("X")
                            ;AttemptUpgrade()
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
                HandleAutoAbility()
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

RaidMode() {

    ; Get current map and act
    currentRaidMap := RaidDropdown.Text
    currentRaidAct := RaidActDropdown.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentRaidMap)
    RaidMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 351, 435, 454, 455, 0, 0, RaidSelectButton)) {
        RaidMovement()
    }

    AddToLog("Starting " currentRaidMap " - " currentRaidAct)
    StartRaid(currentRaidMap, currentRaidAct)
    ; Handle play mode selection
    PlayHere("Raid")
    RestartStage()
}

CustomMode() {
    AddToLog("Starting Custom Mode")
    RestartStage()
}

HandleEndScreen(isVictory := true) {
    Switch ModeDropdown.Text {
        Case "Dungeon":
            HandleDungeonEnd()
        Case "Story":
            HandleStoryEnd()
        Case "Raid":
            HandleRaidEnd()
        Case "Portal":
            HandlePortalEnd(isVictory)
        Default:
            HandleCustomEnd()
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

HandleRaidEnd() {
    AddToLog("Handling Raid end")
    if (ReturnLobbyBox.Value) {
        AddToLog("Return to lobby")
        ClickReturnToLobby()
        return CheckLobby()
    } else {
        AddToLog("Replay raid")
        ClickReplay()
        return RestartStage()
    }
}

HandleCustomEnd() {
    global lastResult
    if (NextLevelBox.Value) {
        if (lastResult = "win") {
            AddToLog("[Info] Starting next level")
            ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyIcon, +260, -35)
            return RestartStage()
        }
    } else {
        AddToLog("[Info] Replaying stage")
        ClickReplay()
        return RestartStage()
    }
}

MonitorStage() {
    global Wins, loss, mode, stageStartTime

    lastClickTime := A_TickCount

    Loop {
        Sleep(1000)

        ; --- Anti-AFK ---
        if ((A_TickCount - lastClickTime) >= 10000) {
            FixClick(400, 500)
            lastClickTime := A_TickCount
        }

        ; --- Check for progression or special cases ---
        CheckForPortalSelection()

        ; --- Fallback if disconnected ---
        Reconnect()

        ; --- Wait for XP/Results screen ---
        if (!CheckForXp())
            continue

        if (AutoAbilityBox.Value) {
            SetTimer(CheckAutoAbility, 0)
        }

        CloseMenu("Unit Manager")
        CloseMenu("Ability Manager")

        AddToLog("Checking win/loss status")
        stageEndTime := A_TickCount
        stageLength := FormatStageTime(stageEndTime - stageStartTime)

        ; --- Victory or Cleared ---
        if (FindText(&X, &Y, 357, 253, 454, 310, 0.20, 0.20, Victory) || FindText(&X, &Y, 255, 118, 555, 418, 0.20, 0.20, Cleared)) {
            AddToLog("Victory detected - Stage Length: " stageLength)
            Wins++
            SendWebhookWithTime(true, stageLength)
            Sleep(2000)
            Reconnect()
            HandleEndScreen(true)
            return
        }

        ; --- Defeat ---
        if (FindText(&X, &Y, 357, 253, 454, 310, 0, 0, Defeat)) {
            AddToLog("Defeat detected - Stage Length: " stageLength)
            loss++
            SendWebhookWithTime(false, stageLength)
            Sleep(2000)
            Reconnect()
            HandleEndScreen(false)
            return
        }
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

RaidMovement() {
    Teleport("Raid")
    Sleep (1000)
    spawnAngle := DetectAngle("Raid")
    WalkToRaidRoom(spawnAngle)
    Sleep (1000)
    
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


StartRaid(map, act) {
    return StartContent(map, act, GetRaidMap, GetRaidAct, { x: 195, y: 185 }, { x: 195, y: 185 })
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
    else if (mode = "Dungeon") {
        FixClick(301, 421)
        Sleep (300)
        FixClick(570, 433)
    }
}

GetRaidMap(map) {
    switch map {
        case "Marines Fort": return { x: 185, y: 185, scrolls: 0 }
        case "Hell City": return { x: 185, y: 225, scrolls: 0 }
        case "Snowy Capital": return { x: 185, y: 260, scrolls: 0 }
        case "Leaf Village": return { x: 185, y: 295, scrolls: 0 }
        case "Wanderniech": return { x: 185, y: 335, scrolls: 0 }
        case "Central City": return { x: 185, y: 370, scrolls: 0 }
        case "Giants District": return { x: 185, y: 265, scrolls: 1 }
        case "Flying Island": return { x: 185, y: 305, scrolls: 1 }
        case "U-18": return { x: 185, y: 340, scrolls: 1 }
        case "Flower Garden": return { x: 185, y: 375, scrolls: 1 }
        case "Ancient Dungeon": return { x: 185, y: 275, scrolls: 2 }
        case "Shinjuku Crater": return { x: 185, y: 315, scrolls: 2 }
        case "Valhalla Arena": return { x: 185, y: 350, scrolls: 2 }
        case "Frozen Planet": return { x: 185, y: 380, scrolls: 2 }
        case "Blossom Church": return { x: 185, y: 370, scrolls: 3 }
    }
}

GetRaidAct(act) {
    baseY := 185
    spacing := 30
    x := 270

    ; Extract the act number from the string, e.g., "Act 3" → 3
    if RegExMatch(act, "Act\s*(\d+)", &match) {
        actNumber := match[1]
        y := baseY + spacing * (actNumber - 1)
        return { x: x, y: y, scrolls: 0 }
    }

    ; Default return if the input doesn't match expected format
    return { x: x, y: baseY, scrolls: 0 }
}

Zoom() {
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
    FixClick(487, 72) ; Closes Player leaderboard
    Sleep 300

    CloseChat()
    Sleep 300

    if (ModeDropdown.Text = "Custom" && SeamlessToggle.Value && !usedButton || ModeDropdown.Text == "Portal" && SeamlessToggle.Value) {
        return
    }

    Zoom()

    ; Teleport to spawn
    TeleportToSpawn()

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
    global currentMap

    if (currentMap = "" || currentMap = "no map found" || ModeDropdown.Text != "Custom") {
        currentMap := DetectMap()
    }
    
    ; Wait for loading
    CheckLoaded()

    BasicSetup()

    if (currentMap != "no map found") {
        HandleMapMovement(currentMap)
    }

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
    ; Credit: @Haie
    color_home := PixelGetColor(10, 10)
    color_reconnect := PixelGetColor(519, 329)

    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    if (color_home = 0x121215 || color_reconnect = 0x393B3D || testing) {
        AddToLog("Disconnected! Attempting to reconnect...")
        sendDCWebhook()

        ; Use PrivateServerURLBox.Value instead of file
        psLink := PrivateServerURLBox.Value

        ; Reconnect to PS
        if (psLink != "") {
            AddToLog("Connecting to private server...")
            Run(psLink)
        } else {
            Run("roblox://placeID=12886143095")
        }

        Sleep 2000

        if WinExist(rblxID) {
            WinActivate(rblxID)
            Sleep 1000
        }

        loop {
            FixClick(490, 400)
            AddToLog("Reconnecting to Anime Last Stand...")
            Sleep 15000
            if (ok := FindText(&X, &Y, 7, 590, 37, 618, 0, 0, LobbySettings)) {
                AddToLog("Reconnected Successfully!")
                return StartSelectedMode()
            } else {
                Reconnect()
            }
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
    if (ok := FindText(&X, &Y, 95, 386, 170, 407, 0, 0, MaxUpgradeText)) {
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

WaitForUpgradeText(timeout := 4500) {
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        if (ok := GetPixel(0x1034AC, 78, 362, 2, 2, 2)) {
            return true
        }
        Sleep 100  ; Check every 100ms
    }
    return false  ; Timed out, upgrade text was not found
}

WaitForUpgradeLimitText(upgradeCap, timeout := 4500) {
    upgradeTexts := [
        Upgrade0, Upgrade1, Upgrade2, Upgrade3, Upgrade4, Upgrade5, Upgrade6, Upgrade7, Upgrade8, Upgrade9, Upgrade10, Upgrade11, Upgrade12, Upgrade13, Upgrade14
    ]
    targetText := upgradeTexts[upgradeCap]

    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        if (FindText(&X, &Y, 103, 373, 165, 386, 0, 0, targetText)) {
            AddToLog("Found Upgrade Cap")
            return true
        }
        Sleep 100
    }
    return false  ; Timed out
}

HandleAutoAbility() {
    if !AutoAbilityBox.Value
        return

    wiggle()

    pixelChecks := [
        {color: 0xC22725, x: 539, y: 285},
        {color: 0xC22725, x: 539, y: 268},
        {color: 0xC22725, x: 539, y: 303},

        {color: 0xC22725, x: 326, y: 284} ; Left Side
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
        
        if (ok := FindText(&X, &Y, 18, 600, 42, 614, 0, 0, IngameQuests)) {
            AddToLog("Successfully Loaded In")
            Sleep(500)
            break
        }

        Reconnect()
    }
}

StartedGame() {
    Sleep(500)
    AddToLog("Game started")
    global stageStartTime := A_TickCount
}

StartSelectedMode() {

    if (ModeDropdown.Text != "Custom") {
        CloseLobbyPopups()
    }

    if (ModeDropdown.Text = "Dungeon") {
        Dungeon()
    }
    else if (ModeDropdown.Text = "Story") {
        StartStoryMode()
    }
    else if (ModeDropdown.Text = "Raid") {
        RaidMode()
    }
    else if (ModeDropdown.Text = "Custom") {
        CustomMode()
    }
    else if (ModeDropdown.Text = "Portal") {
        StartPortalMode()
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
            firstAngle := GetPixel(0xAC7841, 407, 92, 2, 2, 2)

            if (firstAngle) {
                return 1
            } else {
                return 2
            }

        case "Raid":
            firstAngle := GetPixel(0x6F4746, 414, 49, 2, 2, 2)

            if (firstAngle) {
                return 1
            } else {
                return 2
            }
    }
    return 0
}

WalkToRaidRoom(angle) {
    switch angle {
        case 1:
            SendInput("{a down}")
            Sleep(800)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
            SendInput("{s down}")
            Sleep(800)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
        case 2:
            SendInput("{s down}")
            Sleep(800)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
            SendInput("{d down}")
            Sleep(2000)
            SendInput("{d up}")
            KeyWait "d"  ; Wait for the key to be fully processed    
    }
}

TestAllUpgradeFindTexts() {
    foundCount := 0
    notFoundCount := 0

    Loop 15 {
        upgradeCap := A_Index  ; Now 1–15, aligns with AHK v2 arrays
        result := WaitForUpgradeLimitText(upgradeCap, 500)

        if (result) {
            AddToLog("Found Upgrade Level: " upgradeCap - 1)
            foundCount++
        } else {
            AddToLog("Did NOT Find Upgrade Level: " upgradeCap - 1)
            notFoundCount++
        }
    }

    AddToLog("Found: " foundCount " | Not Found: " notFoundCount)
}

UpgradePlacedUnits() {
    global stage
    global successfulCoordinates, maxedCoordinates
    global totalUnits := Map(), upgradedCount := Map()

    hasUpgradeableUnits := false

    ; Check if there are any units eligible for upgrading
    for coord in successfulCoordinates {
        totalUnits[coord.slot] := (totalUnits.Has(coord.slot) ? totalUnits[coord.slot] + 1 : 1)
        upgradedCount[coord.slot] := upgradedCount.Has(coord.slot) ? upgradedCount[coord.slot] : 0

        if (IsUpgradeEnabled(coord.slot) && !maxedCoordinates.Has(coord)) {
            hasUpgradeableUnits := true
        }
    }

    ; If no upgradeable units found, skip the rest
    if (!hasUpgradeableUnits) {
        return
    }

    AddToLog("Initiating Single-Pass Unit Upgrades...")
    stage := "Upgrading"

    if (ShouldOpenUnitManager()) {
        OpenMenu("Unit Manager")
    }

    if (PriorityUpgrade.Value) {
        AddToLog("Using priority upgrade system (single pass)")
        for priorityNum in [1, 2, 3, 4, 5, 6] {
            for slot in [1, 2, 3, 4, 5, 6] {
                if (!IsUpgradeEnabled(slot))
                    continue

                priority := "priority" slot
                priority := %priority%

                if (priority.Text = priorityNum && HasUnitsInSlot(slot, successfulCoordinates)) {
                    AddToLog("Processing upgrades for priority " priorityNum " (slot " slot ")")
                    ProcessUpgrades(slot, priorityNum, true) ; true = single pass
                }
            }
        }
    } else {
        seenSlots := Map()
        for coord in successfulCoordinates {
            if (!IsUpgradeEnabled(coord.slot))
                continue

            if (!seenSlots.Has(coord.slot)) {
                ProcessUpgrades(coord.slot, "", true)
                seenSlots[coord.slot] := true
            }
        }
    }

    AddToLog("Upgrade attempt completed")
}

ProcessUpgrades(slot := false, priorityNum := "", singlePass := false) {
    global successfulCoordinates, totalUnits

    if (singlePass) {
        for index, coord in successfulCoordinates {
            if (!slot || coord.slot = slot) {
                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                UpgradeUnitWithLimit(coord, index)

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                PostUpgradeChecks()

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                }

                if (!UnitManagerUpgradeSystem.Value) {
                    SendInput("X")
                }

                PostUpgradeChecks()
            }
        }

        if (slot)
            AddToLog("Finished single-pass upgrades for priority " priorityNum)

        return
    }

    ; Original behavior (full upgrade loop)
    while (true) {
        slotDone := true
        for index, coord in successfulCoordinates {
            if (!slot || coord.slot = slot) {
                slotDone := false

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                UpgradeUnitWithLimit(coord, index)

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                PostUpgradeChecks()

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                    break
                }

                if (!UnitManagerUpgradeSystem.Value) {
                    SendInput("X") ; Close unit menu
                }

                PostUpgradeChecks()
            }
        }

        if (slot && (slotDone || successfulCoordinates.Length = 0)) {
            AddToLog("Finished upgrades for priority " priorityNum)
            break
        }

        if (!slot)
            break
    }
}

StageEndedDuringUpgrades() {
    return CheckForXp()
}

PostUpgradeChecks() {
    HandleAutoAbility()
    CheckForPortalSelection()
    Reconnect()
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

    CheckForPortalSelection()

    Reconnect()

}

UpgradeUnitWithLimit(coord, index) {
    global totalUnits

    upgradeLimitEnabled := "upgradeLimitEnabled" coord.slot
    upgradeLimitEnabled := %upgradeLimitEnabled%

    upgradeLimit := "upgradeLimit" coord.slot
    upgradeLimit := %upgradeLimit%
    upgradeLimit := String(upgradeLimit.Text)

    upgradePriority := "upgradePriority" coord.slot
    upgradePriority := %upgradePriority%
    upgradePriority := String(upgradePriority.Text)

    if (!upgradeLimitEnabled.Value) {
        if (UnitManagerUpgradeSystem.Value) {
            UnitManagerUpgrade(coord.slot)
        } else {
            UpgradeUnit(coord.x, coord.y)
        }
    } else {
        if (UnitManagerUpgradeSystem.Value) {
            UnitManagerUpgradeWithLimit(coord, index, upgradeLimit)
        } else {
            UpgradeUnitLimit(coord, index, upgradeLimit)
        }
    }
}

UpgradeUnitLimit(coord, index, upgradeLimit) {
    FixClick(coord.x, coord.y)
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
}

HandleMaxUpgrade(coord, index) {
    global successfulCoordinates, maxedCoordinates, upgradedCount, totalUnits

    if (IsSet(totalUnits) && IsSet(upgradedCount)) {
        upgradedCount[coord.slot]++
        AddToLog("Max upgrade reached for Unit: " coord.slot " (" upgradedCount[coord.slot] "/" totalUnits[coord.slot] ")")
    } else {
        AddToLog("Max upgrade reached for Unit: " coord.slot)
        maxedCoordinates.Push(coord)
    }
    maxedCoordinates.Push(coord)
    successfulCoordinates.RemoveAt(index)
    SendInput("X")
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

HasUnitsInSlot(slot, coordinates) {
    for coord in coordinates {
        if (coord.slot = slot)
            return true
    }
    return false
}

CheckForStartButton() {
    return FindText(&X, &Y, 319, 536, 396, 558, 0, 0, StartButton)
    || FindText(&X, &Y, 319, 536, 396, 558, 0, 0, StartButton)
}

HandleStartButton() {
    if (CheckForStartButton()) {
        AddToLog("Start button found, clicking to start stage")
        FixClick(355, 515) ; Click the start button
        Sleep(500)
    }
}

IsUpgradeEnabled(slotNum) {
    setting := "upgradeEnabled" slotNum
    return %setting%.Value
}

StartsInLobby(ModeName) {
    ; Array of modes that usually start in lobby
    static modes := ["Story", "Raid", "Challenge", "Dungeon", "Portal", "Survival"]
    
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

UnitManagerUpgrade(slot) {
    global totalUnits
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(slot, totalUnits)
        Sleep(500)
    }
    Loop 3 {
        SendInput("T")
    }
}

UnitManagerUpgradeWithLimit(coord, index, upgradeLimit) {
    global totalUnits
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(coord.upgradePriority, totalUnits)
        Sleep(500)
    }
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
    
}

ShouldOpenUnitManager() {
    if (UnitManagerAutoUpgrade.Value || UnitManagerUpgradeSystem.Value) {
        return true
    }
}

isMenuOpen(name := "") {
    if (name = "Unit Manager") {
        return FindText(&X, &Y, 700, 142, 789, 166, 0, 0, UnitManager)
    }
    else if (name = "Ability Manager") {
        return FindText(&X, &Y, 675, 594, 785, 616, 0, 0, AbilityManager)
    }
    else if (name = "Story") {
        return FindText(&X, &Y, 352, 431, 451, 458, 0, 0, StorySelectButton)
    }
    else if (name = "End Screen") {
        return FindText(&X, &Y, 225, 217, 356, 246, 0.20, 0.20, Results)
    }
}