#Requires AutoHotkey v2.0
#Include Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount

global step := 50

LoadKeybindSettings()  ; Load saved keybinds
Hotkey(F1Key, (*) => moveRobloxWindow())
Hotkey(F2Key, (*) => StartMacro())
Hotkey(F3Key, (*) => Reload())
Hotkey(F4Key, (*) => TogglePause())

StartMacro(*) {
    if (!ValidateMode()) {
        return
    }
    StartSelectedMode()
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

PlacingUnits() {
    global successfulCoordinates
    successfulCoordinates := []
    placedCounts := Map()  

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

    placementPoints := PlacementPatternDropdown.Text = "Custom" ? GenerateCustomPoints() : PlacementPatternDropdown.Text = "Circle" ? GenerateCirclePoints() : PlacementPatternDropdown.Text = "Grid" ? GenerateGridPoints() : PlacementPatternDropdown.Text = "Spiral" ? GenerateSpiralPoints() : PlacementPatternDropdown.Text = "Up and Down" ? GenerateUpandDownPoints() : GenerateRandomPoints()
    
    ; Go through each slot
    for slotNum in [1, 2, 3, 4, 5, 6] {
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
            AddToLog("Placing Unit " slotNum " (0/" placements ")")
            ; Place all units for this slot
            while (placedCounts[slotNum] < placements) {
                for point in placementPoints {
                    ; Skip if this coordinate was already used successfully
                    alreadyUsed := false
                    for coord in successfulCoordinates {
                        if (coord.x = point.x && coord.y = point.y) {
                            alreadyUsed := true
                            break
                        }
                    }
                    if (alreadyUsed)
                        continue
                
                    if PlaceUnit(point.x, point.y, slotNum) {
                        successfulCoordinates.Push({x: point.x, y: point.y, slot: slotNum})
                        placedCounts[slotNum] += 1
                        AddToLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                        FixClick(740, 545) ; Click away from unit
                        if (UpgradeDuringPlacementBox.Value) {
                            AttemptUpgrade()   ; Upgrade units while placing
                        }
                        break
                    }
                    
                    if CheckForXp()
                        return MonitorStage()
                    Reconnect()
                    CheckEndAndRoute()
                }
                Sleep(500)
            }
        }
    }
    
    AddToLog("All units placed to requested amounts")
    UpgradeUnits()
}

AttemptUpgrade() {
    global successfulCoordinates, PriorityUpgrade
    global priority1, priority2, priority3, priority4, priority5, priority6

    if (successfulCoordinates.Length = 0) {
        return ; No units placed yet
    }

    AddToLog("Attempting to upgrade units...")

    if (PriorityUpgrade.Value) {
        AddToLog("Using priority-based upgrading")
        
        ; Loop through priority levels (1-6) and upgrade all matching units
        for priorityNum in [1, 2, 3, 4, 5, 6] {
            upgradedThisRound := false

            for index, coord in successfulCoordinates.Clone() { ; Clone to allow removal
                ; Get the priority value for this unit's slot
                priority := "priority" coord.slot
                priority := %priority%

                if (priority.Text = priorityNum) {
                    UpgradeUnit(coord.x, coord.y)

                    if CheckForXp() {
                        AddToLog("Stage ended during upgrades, proceeding to results")
                        successfulCoordinates := []
                        return MonitorStage()
                    }

                    if CheckForPortalSelection() {
                        AddToLog("Stage ended during upgrades, proceeding to results")
                        successfulCoordinates := []
                        MonitorStage()
                        return
                    }

                    if MaxUpgrade() {
                        AddToLog("Max upgrade reached for Unit " coord.slot)
                        successfulCoordinates.RemoveAt(index)
                        FixClick(325, 185) ; Close upgrade menu
                        continue
                    }

                    Sleep(200)
                    FixClick(740, 545) ; Click away from unit
                    Reconnect()
                    CheckEndAndRoute()

                    upgradedThisRound := true
                }
            }

            if upgradedThisRound {
                Sleep(300) ; Add a slight delay between batches
            }
        }
    } else {
        ; Normal (non-priority) upgrading - upgrade all available units
        for index, coord in successfulCoordinates.Clone() {
            UpgradeUnit(coord.x, coord.y)

            if CheckForXp() {
                AddToLog("Stage ended during upgrades, proceeding to results")
                successfulCoordinates := []
                return MonitorStage()
            }

            if CheckForPortalSelection() {
                AddToLog("Stage ended during upgrades, proceeding to results")
                successfulCoordinates := []
                MonitorStage()
                return
            }

            if MaxUpgrade() {
                AddToLog("Max upgrade reached for Unit " coord.slot)
                successfulCoordinates.RemoveAt(index)
                FixClick(325, 185) ; Close upgrade menu
                continue
            }

            Sleep(200)
            FixClick(740, 545) ; Click away from unit
            Reconnect()
            CheckEndAndRoute()
        }
    }
}

CheckForXp() {
    ; Check for lobby text
    if (ok := FindText(&X, &Y, 273-150000, 229-150000, 273+150000, 229+150000, 0, 0, Results)) {
        FixClick(325, 185)
        FixClick(560, 560)
        return true
    }
    return false
}


UpgradeUnits() {
    global successfulCoordinates, PriorityUpgrade, priority1, priority2, priority3, priority4, priority5, priority6

    totalUnits := Map()    
    upgradedCount := Map()  
    
    ; Initialize counters
    for coord in successfulCoordinates {
        if (!totalUnits.Has(coord.slot)) {
            totalUnits[coord.slot] := 0
            upgradedCount[coord.slot] := 0
        }
        totalUnits[coord.slot]++
    }

    AddToLog("Initiating Unit Upgrades...")

    if (PriorityUpgrade.Value) {
        AddToLog("Using priority upgrade system")
        
        ; Go through each priority level (1-6)
        for priorityNum in [1, 2, 3, 4, 5, 6] {
            ; Find which slot has this priority number
            for slot in [1, 2, 3, 4, 5, 6] {
                priority := "priority" slot
                priority := %priority%
                if (priority.Text = priorityNum) {
                    ; Skip if no units in this slot
                    hasUnitsInSlot := false
                    for coord in successfulCoordinates {
                        if (coord.slot = slot) {
                            hasUnitsInSlot := true
                            break
                        }
                    }
                    
                    if (!hasUnitsInSlot) {
                        continue
                    }

                    AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                    
                    ; Keep upgrading current slot until all its units are maxed
                    while true {
                        slotDone := true
                        
                        for index, coord in successfulCoordinates {
                            if (coord.slot = slot) {
                                slotDone := false
                                UpgradeUnit(coord.x, coord.y)

                                if CheckForXp() {
                                    AddToLog("Stage ended during upgrades, proceeding to results")
                                    successfulCoordinates := []
                                    MonitorStage()
                                    return
                                }

                                if CheckForPortalSelection() {
                                    AddToLog("Stage ended during upgrades, proceeding to results")
                                    successfulCoordinates := []
                                    MonitorStage()
                                    return
                                }

                                if MaxUpgrade() {
                                    upgradedCount[coord.slot]++
                                    AddToLog("Max upgrade reached for Unit " coord.slot " (" upgradedCount[coord.slot] "/" totalUnits[coord.slot] ")")
                                    successfulCoordinates.RemoveAt(index)
                                    FixClick(325, 185) ;Close upg menu
                                    break
                                }

                                Sleep(200)
                                CheckAbility()
                                FixClick(560, 560) ; Move Click
                                Reconnect()
                                CheckEndAndRoute()
                            }
                        }
                        
                        if (slotDone || successfulCoordinates.Length = 0) {
                            AddToLog("Finished upgrades for priority " priorityNum)
                            break
                        }
                    }
                }
            }
        }
        
        AddToLog("Priority upgrading completed")
        return MonitorStage()
    } else {
        ; Normal upgrade (no priority)
        while true {
            if (successfulCoordinates.Length == 0) {
                AddToLog("All units maxed, proceeding to monitor stage")
                return MonitorStage()
            }

            for index, coord in successfulCoordinates {
                UpgradeUnit(coord.x, coord.y)

                if CheckForXp() {
                    AddToLog("Stage ended during upgrades, proceeding to results")
                    successfulCoordinates := []
                    MonitorStage()
                    return
                }

                if CheckForPortalSelection() {
                    AddToLog("Stage ended during upgrades, proceeding to results")
                    successfulCoordinates := []
                    MonitorStage()
                    return
                }


                if MaxUpgrade() {
                    upgradedCount[coord.slot]++
                    AddToLog("Max upgrade reached for Unit " coord.slot " (" upgradedCount[coord.slot] "/" totalUnits[coord.slot] ")")
                    successfulCoordinates.RemoveAt(index)
                    FixClick(325, 185) ;Close upg menu
                    continue
                }

                Sleep(200)
                CheckAbility()
                FixClick(560, 560) ; Move Click
                Reconnect()
                CheckEndAndRoute()
            }
        }
    }
}

ChallengeMode() {    
    AddToLog("Moving to Challenge mode")
    ChallengeMovement()
    
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, Story)) {
        ChallengeMovement()
    }

    RestartStage()
}

StoryMode() {
    global SkipLobby
    global StoryDropdown
    
    ; Get current map and act
    currentStoryMap := StoryDropdown.Text
    if (!SkipLobby) {
        
        ; Execute the movement pattern
        AddToLog("Moving to position for " currentStoryMap)
        StoryMovement()
        
        ; Start stage
        while !(ok:=FindText(&X, &Y, 208-150000, 188-150000, 208+150000, 188+150000, 0, 0, Story)) {
            StoryMovement()
        }
        AddToLog("Starting " currentStoryMap)
        StartStory(currentStoryMap)
    
        ; Handle play mode selection
        PlayHere()
        RestartStage()
    } else {
        AddToLog("Starting " currentStoryMap)
        ; Handle play mode selection
        PlayHere()
        RestartStage()
    }
}


LegendMode() {
    global SkipLobby
    global LegendDropdown
    
    ; Get current map and act
    currentLegendMap := LegendDropdown.Text
    
    ; Execute the movement pattern
    AddToLog("Moving to position for " currentLegendMap)
    StoryMovement()
    
    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, Story)) {
        StoryMovement()
    }
    AddToLog("Starting " currentLegendMap)
    StartLegend(currentLegendMap)

    ; Handle play mode selection
    PlayHere()

    RestartStage()
}

RaidMode() {
    global SkipLobby
    global RaidDropdown
    
    ; Get current map and act
    currentRaidMap := RaidDropdown.Text
    currentRaidAct := RaidActDropdown.Text

    if (!SkipLobby.Value) {
        ; Execute the movement pattern
        AddToLog("Moving to position for " currentRaidMap)
        RaidMovement()
    
        ; Start stage
        while !(ok := FindText(&X, &Y, 175, 173, 245, 204, 0, 0, Raids)) {
            RaidMovement()
        }
        AddToLog("Starting " currentRaidMap " - " currentRaidAct)
        StartRaidNoUI(currentRaidMap, currentRaidAct)
        ; Handle play mode selection
        PlayHere()
        RestartStage()
    } else {
        ; Handle play mode selection
        PlayHere()
        RestartStage()
    }
}

CustomMode() {
    AddToLog("Starting Custom Mode")
    RestartCustomStage()
}

MonitorEndScreen() {
    global mode, StoryDropdown, ReturnLobbyBox

    Loop {
        Sleep(3000)  
        
        FixClick(560, 560)
        FixClick(560, 560)

        ; Now handle each mode
        if (ok := FindText(&X, &Y, 388-150000, 430-150000, 388+150000, 430+150000, 0, 0, Retry)) {
            AddToLog("Found Lobby Text - Current Mode: " mode)
            Sleep(2000)
            if (mode = "Story") {
                AddToLog("Handling Story mode end")
                    if (NextLevelBox.Value && lastResult = "win") {
                        AddToLog("Next level")
                        ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +260, -35, LobbyText2)
                    } else {
                        AddToLog("Replay level")
                        FixClick(389, 394)
                    }
                return RestartStage()
            }
            else if (mode = "Raid") {
                AddToLog("Handling Raid end")
                if (ReturnLobbyBox.Value) {
                    AddToLog("Return to lobby")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                } else {
                    AddToLog("Replay raid")
                    FixClick(389, 394)
                    return RestartStage()
                }
            }
            else {
                AddToLog("Handling end case")
                if (ReturnLobbyBox.Value) {
                    AddToLog("Return to lobby enabled")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                } else {
                    AddToLog("Replaying")
                    FixClick(404, 396)
                    FixClick(404, 396)
                    FixClick(404, 396)
                    if (ModeDropdown.Text = "Custom") {
                        if (!SeamlessToggle.Value) {
                            loop {
                                Sleep(1000) ; Check every second
                        
                                ; If Unit Manager is no longer found, break the loop
                                if (!FindText(&X, &Y, 15, 321, 97, 345, 0, 0, UnitManager)) {
                                    if (debugMessages) {
                                        AddToLog("Unit Manager not found, proceeding...")
                                    }
                                    break
                                }
                                if (debugMessages) {
                                    AddToLog("Unit Manager not found, proceeding...")
                                }
                            }
                        }
                        return RestartCustomStage()
                    } else {
                        return RestartStage()
                    }
                }
            }
        }
        
        Reconnect()
    }
}


MonitorStage() {
    global Wins, loss, mode

    lastClickTime := A_TickCount
    
    Loop {
        Sleep(1000)

        ; Click through drops until results screen (Portal or XP) appears
        while !(CheckForXp() || CheckForPortalSelection()) {
            ClickThroughDrops()
            Sleep (100)  ; Small delay to prevent high CPU usage while clicking
        }

        ; Check for XP screen
        AddToLog("Checking win/loss status")
            
        ; Calculate stage end time here, before checking win/loss
        stageEndTime := A_TickCount
        stageLength := FormatStageTime(stageEndTime - stageStartTime)
            
        ; Check for Victory or Defeat
        if (ok := FindText(&X, &Y, 405-150000, 268-150000, 405+150000, 268+150000, 0, 0, Victory)) {
            AddToLog("Victory detected - Stage Length: " stageLength)
            Wins += 1
            SendWebhookWithTime(true, stageLength)
            return MonitorEndScreen()  ; Original behavior for other modes
        }
        else if (ok := FindText(&X, &Y, 403-150000, 269-150000, 403+150000, 269+150000, 0, 0, Defeat)) {
            AddToLog("Defeat detected - Stage Length: " stageLength)
            loss += 1
            SendWebhookWithTime(false, stageLength) 
            return MonitorEndScreen()  ; Original behavior for other modes
        }
        Reconnect()
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
    if (ok:=FindText(&X, &Y, 348, 429, 454, 459, 0, 0, PortalSelection) or (ok:=FindText(&X, &Y, 348, 429, 454, 459, 0, 0, PortalSelection))) {
        FixClick(399, 299)
        Sleep (500)
        FixClick(402, 414)
        return true
    }
    return false
}

StoryMovement() {
    FixClick(35, 350) ; Click Teleport
    sleep (1000)
    FixClick(392, 333) ; Click Story & Infinite
    sleep (1000)
    FixClick(35, 350) ; Click Teleport to close
    sleep (1000)
    LookForStoryAngle()
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep(4500)
    SendInput ("{a up}")
    SendInput ("{w up}")
    Sleep(500)
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
    FixClick(35, 350) ; Click Teleport
    Sleep (1000)
    FixClick(270, 170) ; Click on side
    Sleep (1000)
    ; Scroll to bottom
    Loop 10 {
        Send "{WheelDown}"
        Sleep 50
    }
    FixClick(399, 367) ; Click Raids
    sleep (1000)
    FixClick(35, 350) ; Click Teleport to close
    sleep (1000)
    LookForRaidAngle()
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep(4500)
    SendInput ("{a up}")
    SendInput ("{w up}")
    Sleep(500)
}

LookForStoryAngle() {
    loop {
        if FindText(&X, &Y, 301, 61, 529, 168, 0, 0, StoryPillar) {
            AddToLog("Correct Angle")
            break
        }
        else {
            AddToLog("Incorrect Angle. Turning again.")
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
        }
    }
}

LookForRaidAngle() {
    loop {
        if FindText(&X, &Y, 360, 47, 457, 86, 0, 0, RaidPillar) {
            AddToLog("Correct Angle")
            break
        }
        else {
            AddToLog("Incorrect Angle. Turning again.")
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
        }
    }
}



StartStory(map) {
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    leftArrows := 4 ; Go Over To Story
    Loop leftArrows {
        SendInput("{Left}")
        Sleep(200)
    }

    downArrows := GetStoryDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select storymode
    Sleep(500)

    SendInput("{Right}") ; Go to act selection
    Sleep(1000)
    
    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartLegend(map) {
    
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)
    SendInput("{Down}")
    Sleep(500)
    SendInput("{Enter}") ; Opens Legend Stage

    downArrows := GetLegendDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }
    
    SendInput("{Enter}") ; Select LegendStage
    Sleep(500)

    Loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(1000)

    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartRaid(map) {
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    downArrows := GetRaidDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Raid

    Loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(500)
    
    SendInput("{Enter}") ; Select Act
    Sleep(300)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartRaidNoUI(map, RaidActDropdown) {
    FixClick(640, 70) ; Close Leaderboard
    Sleep(500)
    raidClickCoords := GetRaidClickCoords(map) ; Coords for Raid Map
    FixClick(raidClickCoords.x, raidClickCoords.y) ; Choose Raid
    Sleep(500)
    actClickCoords := GetRaidActClickCoords(RaidActDropdown) ; Coords for Raid Act
    FixClick(actClickCoords.x, actClickCoords.y) ; Choose Raid Act
}

PlayHere() {
    FixClick(400, 394)
    Sleep (300)
    FixClick(400, 394)
    Sleep (300)
}

GetStoryDownArrows(map) {
    switch map {
        case "Planet Greenie": return 0
    }
}

GetStoryActDownArrows(StoryActDropdown) {
    switch StoryActDropdown {
        case "Act 1": return 0
        case "Act 2": return 1
        case "Act 3": return 2
        case "Act 4": return 3
        case "Act 5": return 4
        case "Act 6": return 5
        case "Infinity": return 6
    }
}


GetLegendDownArrows(map) {
    switch map {
        case "Magic Hills": return 1
    }
}

GetLegendActDownArrows(LegendActDropdown) {
    switch LegendActDropdown {
        case "Act 1": return 1
    }
}

GetRaidDownArrows(map) {
    switch map {
        case "The Spider": return 1
    }
}

GetRaidActDownArrows(RaidActDropdown) {
    switch RaidActDropdown {
        case "Act 1": return 1
        case "Act 2": return 2
        case "Act 3": return 3
        case "Act 4": return 4
        case "Act 5": return 5
    }
}

GetStoryClickCoords(map) {
    switch map {
        case "Large Village": return { x: 235, y: 240 }
        case "Hollow Land": return { x: 235, y: 295 }
        case "Monster City": return { x: 235, y: 350 }
        case "Academy Demon": return { x: 235, y: 400 }
    }
}

GetStoryActClickCoords(StoryActDropdown) {
    switch StoryActDropdown {
        case "Act 1": return { x: 380, y: 230 }
        case "Act 2": return { x: 380, y: 260 }
        case "Act 3": return { x: 380, y: 290 }
        case "Act 4": return { x: 380, y: 320 }
        case "Act 5": return { x: 380, y: 350 }
        case "Act 6": return { x: 380, y: 380 }
        case "Infinity": return { x: 380, y: 405 }
    }
}

GetRaidClickCoords(map) {
    switch map {
        case "Marines Fort": return { x: 230, y: 200 }
        case "Hell City": return { x: 235, y: 220 }
        case "Snowy Capital": return { x: 235, y: 255 }
        case "Leaf Village": return { x: 235, y: 280 }
        case "Wanderniech": return { x: 235, y: 305 }
        case "Central City": return { x: 235, y: 330 }
        case "Giants District": return { x: 235, y: 355 }
        case "Flying Island": return { x: 235, y: 380 }
    }
}

GetRaidActClickCoords(RaidActDropdown) {
    switch RaidActDropdown {
        case "Act 1": return { x: 315, y: 200 }
        case "Act 2": return { x: 315, y: 230 }
        case "Act 3": return { x: 315, y: 260 }
        case "Act 4": return { x: 315, y: 290 }
        case "Act 5": return { x: 315, y: 320 }
        case "Act 6": return { x: 315, y: 350 }
    }
}

Zoom() {
    MouseMove(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Loop 10 {
        Send "{WheelUp}"
        Sleep 50
    }

    ; Look down
    Click
    MouseMove(400, 400)  ; Move mouse down to angle camera down
    
    ; Zoom back out smoothly
    Loop 20 {
        Send "{WheelDown}"
        Sleep 50
    }
    
    ; Move mouse back to center
    MouseMove(400, 300)
}

TpSpawn() {
    FixClick(233, 10) ;click settings
    Sleep 300
    FixClick(464, 219) ;click tp to spawn
    Sleep 300
    FixClick(233, 10) ;click settings
    Sleep 300
}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        AddToLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup() {
    SendInput("{Tab}") ; Closes Player leaderboard
    Sleep 300
    FixClick(564, 72) ; Closes Player leaderboard
    Sleep 300
    CloseChat()
    Sleep 300
    Zoom()
    Sleep 300
    TpSpawn()
}

DetectMap() {
    AddToLog("Determining Movement Necessity on Map...")
    startTime := A_TickCount
    
    Loop {
        ; Check if we waited more than 5 minute for votestart
        if (A_TickCount - startTime > 300000) {
            if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                AddToLog("Found in lobby - restarting selected mode")
                return StartSelectedMode()
            }
            AddToLog("Could not detect map after 5 minutes - proceeding without movement")
            return "no map found"
        }

        if (ModeDropdown.Text = "Raid") {
            AddToLog("Map detected: " RaidDropdown.Text)
            return RaidDropdown.Text
        }

        ; Check for in-game settings
        if (ok := FindText(&X, &Y, 15, 321, 97, 345, 0, 0, UnitManager)) {
            AddToLog("No Map Found or Movement Unnecessary")
            return "no map found"
        }

        Sleep 1000
        Reconnect()
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

MoveForWinterEvent() {
    loop {
        if FindAndClickColor() {
            break
        }
        else {
            AddToLog("Color not found. Turning again.")
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
            Sleep 200
        }
    }
}

    
RestartStage() {
    currentMap := DetectMap()
    
    ; Wait for loading
    CheckLoaded()

    ; Do initial setup and map-specific movement during vote timer
    BasicSetup()
    if (currentMap != "no map found") {
        HandleMapMovement(currentMap)
    }

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    PlacingUnits()
    
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
    PlacingUnits()
    
    ; Monitor stage progress
    MonitorStage()
}

Reconnect() {   
    ; Check for Disconnected Screen using FindText
    if (ok := FindText(&X, &Y, 330, 218, 474, 247, 0, 0, Disconnect)) {
        AddToLog("Lost Connection! Attempting To Reconnect To Private Server...")

        psLink := FileExist("Settings\PrivateServer.txt") ? FileRead("Settings\PrivateServer.txt", "UTF-8") : ""

        ; Reconnect to Ps
        if FileExist("Settings\PrivateServer.txt") && (psLink := FileRead("Settings\PrivateServer.txt", "UTF-8")) {
            AddToLog("Connecting to private server...")
            Run(psLink)
        } else {
            Run("roblox://placeID=12886143095")
        }

        Sleep(5000)  

        loop {
            AddToLog("Reconnecting to Roblox...")
            Sleep(15000)

            if WinExist(rblxID) {
                forceRobloxSize()
                moveRobloxWindow()
                Sleep(1000)
            }
            
            if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                AddToLog("Reconnected Successfully!")
                return StartSelectedMode()
            } else {
                Reconnect() 
            }
        }
    }
}

PlaceUnit(x, y, slot := 1) {
    SendInput(slot)
    Sleep 50
    FixClick(x, y)
    Sleep 50
    SendInput("x")
    Sleep 200
    FixClick(x, y)
    Sleep 50
    if UnitPlaced() {
        Sleep 15
        return true
    }
    return false
}

MaxUpgrade() {
    Sleep 500
    ; Check for max text
    if (ok := FindText(&X, &Y, 672-150000, 385-150000, 672+150000, 385+150000, 0, 0, NewMaxUpgaded)) {
        return true
    }
    return false
}

UnitPlaced() {
    if (WaitForUpgradeText(GetPlacementSpeed())) { ; Wait up to 4.5 seconds for the upgrade text to appear
        AddToLog("Unit Placed Successfully")
        FixClick(325, 185) ; Close upgrade menu
        return true
    }
    return false
}

WaitForUpgradeText(timeout := 4500) {
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        if (ok := FindText(&X, &Y, 662-150000, 365-150000, 662+150000, 365+150000, 0, 0, NewUpgrade)) {
            return true
        }
        Sleep 100  ; Check every 100ms
    }
    return false  ; Timed out, upgrade text was not found
}

CheckAbility() {
    global AutoAbilityBox  ; Reference your checkbox
    
    ; Only check ability if checkbox is checked
    if (AutoAbilityBox.Value) {
        if (ok := FindText(&X, &Y, 342, 253, 401, 281, 0, 0, AutoOff)) {
            FixClick(373, 237)  ; Turn ability on
            AddToLog("Auto Ability Enabled")
        }
    }
}

UpgradeUnit(x, y) {
    FixClick(x, y - 3)
    SendInput ("{T}")
    SendInput ("{T}")
    SendInput ("{T}")
}

CheckLobby() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
            break
        }
        Reconnect()
    }
    AddToLog("Returned to lobby, restarting selected mode")
    return StartSelectedMode()
}

CheckLoaded() {
    loop {
        Sleep(1000)
        
        ; Check for in-game settings
        if (ok := FindText(&X, &Y, 15, 321, 97, 345, 0, 0, UnitManager)) {
            AddToLog("Successfully Loaded In")
            Sleep(1000)
            break
        }

        Reconnect()
    }
}

StartedGame() {
    Sleep(1000)
    AddToLog("Game started")
    global stageStartTime := A_TickCount
}

StartSelectedMode() {
    FixClick(400,340)
    FixClick(400,390)
    if (ModeDropdown.Text = "Story") {
        StoryMode()
    }
    else if (ModeDropdown.Text = "Legend") {
        LegendMode()
    }
    else if (ModeDropdown.Text = "Raid") {
        RaidMode()
    }
    else if (ModeDropdown.Text = "Custom") {
        CustomMode()
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

GenerateCustomPoints() {
    global savedCoords  ; Access the global saved coordinates
    points := []

    ; Directly use savedCoords without generating new points
    for coord in savedCoords {
        points.Push({x: coord.x, y: coord.y})
    }

    return points
}

GenerateRandomPoints() {
    points := []
    gridSize := 40  ; Minimum spacing between units
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Define placement area boundaries (adjust these as needed)
    minX := centerX - 180  ; Left boundary
    maxX := centerX + 180  ; Right boundary
    minY := centerY - 140  ; Top boundary
    maxY := centerY + 140  ; Bottom boundary
    
    ; Generate 40 random points
    Loop 40 {
        ; Generate random coordinates
        x := Random(minX, maxX)
        y := Random(minY, maxY)
        
        ; Check if point is too close to existing points
        tooClose := false
        for existingPoint in points {
            ; Calculate distance to existing point
            distance := Sqrt((x - existingPoint.x)**2 + (y - existingPoint.y)**2)
            if (distance < gridSize) {
                tooClose := true
                break
            }
        }
        
        ; If point is not too close to others, add it
        if (!tooClose)
            points.Push({x: x, y: y})
    }
    
    ; Always add center point last (so it's used last)
    points.Push({x: centerX, y: centerY})
    
    return points
}

GenerateGridPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)
    
    ; Generate grid points row by row
    Loop squaresPerSide {
        currentRow := A_Index
        y := startY + ((currentRow - 1) * gridSize)
        
        ; Generate each point in the current row
        Loop squaresPerSide {
            x := startX + ((A_Index - 1) * gridSize)
            points.Push({x: x, y: y})
        }
    }
    
    return points
}

GenerateUpandDownPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)
    
    ; Generate grid points column by column (left to right)
    Loop squaresPerSide {
        currentColumn := A_Index
        x := startX + ((currentColumn - 1) * gridSize)
        
        ; Generate each point in the current column
        Loop squaresPerSide {
            y := startY + ((A_Index - 1) * gridSize)
            points.Push({x: x, y: y})
        }
    }
    
    return points
}

; circle coordinates
GenerateCirclePoints() {
    points := []
    
    ; Define each circle's radius
    radius1 := 45    ; First circle 
    radius2 := 90    ; Second circle 
    radius3 := 135   ; Third circle 
    radius4 := 180   ; Fourth circle 
    
    ; Angles for 8 evenly spaced points (in degrees)
    angles := [0, 45, 90, 135, 180, 225, 270, 315]
    
    ; First circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius1 * Cos(radians)
        y := centerY + radius1 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; second circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius2 * Cos(radians)
        y := centerY + radius2 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; third circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius3 * Cos(radians)
        y := centerY + radius3 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ;  fourth circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius4 * Cos(radians)
        y := centerY + radius4 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    return points
}

; Spiral coordinates (restricted to a rectangle)
GenerateSpiralPoints(rectX := 4, rectY := 123, rectWidth := 795, rectHeight := 433) {
    points := []
    
    ; Calculate center of the rectangle
    centerX := rectX + rectWidth // 2
    centerY := rectY + rectHeight // 2
    
    ; Angle increment per step (in degrees)
    angleStep := 30
    ; Distance increment per step (tighter spacing)
    radiusStep := 10
    ; Initial radius
    radius := 20
    
    ; Maximum radius allowed (smallest distance from center to edge)
    maxRadiusX := (rectWidth // 2) - 1
    maxRadiusY := (rectHeight // 2) - 1
    maxRadius := Min(maxRadiusX, maxRadiusY)

    ; Generate spiral points until reaching max boundary
    Loop {
        ; Stop if the radius exceeds the max boundary
        if (radius > maxRadius)
            break
        
        angle := A_Index * angleStep
        radians := angle * 3.14159 / 180
        x := centerX + radius * Cos(radians)
        y := centerY + radius * Sin(radians)
        
        ; Check if point is inside the rectangle
        if (x < rectX || x > rectX + rectWidth || y < rectY || y > rectY + rectHeight)
            break ; Stop if a point goes out of bounds
        
        points.Push({ x: Round(x), y: Round(y) })
        
        ; Increase radius for next point
        radius += radiusStep
    }
    
    return points
}

UseRecommendedPoints() {
    if (ModeDropdown.Text = "Raid") {
        if (RaidDropdown.Text = "Marines Fort") {
            return GenerateMarineFortPoints()
        }
        else if (RaidDropdown.Text = "Hell City") {
            return GenerateHellCityPoints()
        }
        else if (RaidDropdown.Text = "Snowy Capital") {
            return GenerateSnowyCapitalPoints()
        }
        else if (RaidDropdown.Text = "Leaf Village") {
            return GenerateLeafVillagePoints()
        }
        else if (RaidDropdown.Text = "Wanderniech") {
            return GenerateBleachPoints()
        }
        else if (RaidDropdown.Text = "Central City") {
            return GenerateCentralCityPoints2()
           ; return GenerateCentralCityPoints()
        }
    }
    return GenerateRandomPoints()
}

Generate3x3GridPoints() {
    points := []
    gridSize := 20  ; Space between points
    gridSizeHalf := gridSize // 2
    
    ; Center point coordinates
    centerX := GetWindowCenter(rblxID).x - 30
    centerY := GetWindowCenter(rblxID).y - 30
    
    ; Define movement directions: right, down, left, up
    directions := [[1, 0], [0, 1], [-1, 0], [0, -1]]
    
    ; Spiral logic for a 3x3 grid
    x := centerX
    y := centerY
    step := 1  ; Number of steps in the current direction
    dirIndex := 0  ; Current direction index
    moves := 0  ; Move count to switch direction
    
    points.Push({x: x, y: y})  ; Start at center
    
    Loop 8 {  ; Fill remaining 8 spots (3x3 grid has 9 total)
        dx := directions[dirIndex + 1][1] * gridSize
        dy := directions[dirIndex + 1][2] * gridSize
        x += dx
        y += dy
        points.Push({x: x, y: y})
        
        moves++
        if (moves = step) {  ; Change direction
            moves := 0
            dirIndex := Mod(dirIndex + 1, 4)  ; Rotate through 4 directions
            if (dirIndex = 0 || dirIndex = 2) {
                step++  ; Increase step size after every two direction changes
            }
        }
    }
    
    return points
}

; raid coordinates
GenerateMarineFortPoints() {
    points := []

    points.Push({ x: Round(218), y: Round(264) })
    points.Push({ x: Round(272), y: Round(244) })
    points.Push({ x: Round(373), y: Round(244) })
    
    return points
}

GenerateHellCityPoints() {
    points := []

    points.Push({ x: Round(101), y: Round(242) })
    points.Push({ x: Round(235), y: Round(202) })
    points.Push({ x: Round(176), y: Round(197) })
    
    return points
}

GenerateSnowyCapitalPoints() {
    points := []

    points.Push({ x: 772, y: 252 })
    points.Push({ x: Round(762), y: Round(457) })
    points.Push({ x: Round(623), y: Round(366) })
    
    return points
}

GenerateLeafVillagePoints() {
    points := []

    points.Push({ x: Round(386), y: Round(242) })
    points.Push({ x: Round(603), y: Round(330) })
    points.Push({ x: Round(481), y: Round(386) })
    
    return points
}

GenerateCentralCityPoints() {
    points := []
    points.Push({ x: Round(413), y: Round(114) })
    points.Push({ x: Round(419), y: Round(196) })
    points.Push({ x: Round(404), y: Round(27) })
    
    return points
}

GenerateCentralCityPoints2() {
    points := []
    points.Push({ x: Round(258), y: Round(312) }) ; Hill
    points.Push({ x: Round(167), y: Round(287) })
    points.Push({ x: Round(167), y: Round(242) })
    points.Push({ x: Round(147), y: Round(242) })
    
    return points
}

GenerateBleachPoints() {
    points := []

    points.Push({ x: Round(127), y: Round(580) }) ; Hill Placement
    points.Push({ x: Round(392), y: Round(507) }) ; Farm
    points.Push({ x: Round(341), y: Round(509) }) ; DPS Unit
    
    return points
}

CheckEndAndRoute() {
    if (ok := FindText(&X, &Y, 140, 130, 662, 172, 0, 0, LobbyText)) {
        AddToLog("Found end screen")
        return MonitorEndScreen()
    }
    return false
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