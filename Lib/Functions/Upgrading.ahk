#Requires AutoHotkey v2.0

UpgradeUnits() {
    global stage
    global successfulCoordinates, maxedCoordinates

    if (ShouldOpenUnitManager()) {
        OpenMenu("Unit Manager")
    }

    ; Auto-upgrade logic
    if (UnitManagerAutoUpgrade.Value) {
        if (PriorityUpgrade.Value) {
            SetAutoUpgradeForAllUnits()
            return HandleUnitManager("Auto-upgrade enabled for all units. Entering monitoring stage.")
        } else {
            UpgradeAllUnits()
            return HandleUnitManager("Auto-upgrade enabled for all units. Entering monitoring stage.")
        }
    }

    if (PriorityUpgrade.Value) {
        upgradeWithPriority()
    } else {
        UpgradeWithoutPriority()
    }

    return MonitorStage()
}

UpgradeWithoutPriority() {
    global successfulCoordinates
    while (successfulCoordinates.Length > 0) {
        ProcessUpgrades(false, "")
    }
    AddToLog("All units maxed, proceeding to monitor stage")
}

UpgradeWithPriority() {
    global successfulCoordinates
    AddToLog("Using priority upgrade system")
    slotOrder := [1, 2, 3, 4, 5, 6]
    priorityOrder := [1, 2, 3, 4, 5, 6]

    if (UnitManagerUpgradeSystem.Value) {
        for priorityNum in priorityOrder {
            for slot in slotOrder {
                if (HasUnitsInSlot(slot, priorityNum, successfulCoordinates)) {
                    AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                    ProcessUpgrades(slot, priorityNum)
                }
            }
        }
    } else {
        for priorityNum in priorityOrder {
            for slot in slotOrder {
                if (HasUnitsInSlot(slot, priorityNum, successfulCoordinates)) {
                    AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                    ProcessUpgrades(slot, priorityNum)
                }
            }
        }
    }

    AddToLog("All units maxed, proceeding to monitor stage")
    CloseMenu("Unit Manager")
}

SetAutoUpgradeForAllUnits() {
    global successfulCoordinates

    ; Sort by placementIndex to get visual order
    sorted := successfulCoordinates.Clone()

    ; Simple bubble sort by placementIndex
    Loop sorted.Length {
        for i, val in sorted {
            if (i = sorted.Length)
                continue
            if (sorted[i].placementIndex > sorted[i + 1].placementIndex) {
                temp := sorted[i]
                sorted[i] := sorted[i + 1]
                sorted[i + 1] := temp
            }
        }
    }

    ; GUI positioning constants
    baseX := 610
    baseY := 215
    colSpacing := 80
    rowSpacing := 115
    maxCols := 3
    totalCount := sorted.Length

    fullRows := Floor(totalCount / maxCols)
    lastRowUnits := Mod(totalCount, maxCols)

    ; Loop through units in visual order
    for index, unit in sorted {
        slot := unit.slot
        priority := unit.upgradePriority

        ; Calculate click position based on visual index
        placementIndex := index - 1 ; zero-based
        row := Floor(placementIndex / maxCols)
        colInRow := Mod(placementIndex, maxCols)
        isLastRow := (row = fullRows)

        if (lastRowUnits != 0 && isLastRow) {
            rowStartX := baseX + ((maxCols - lastRowUnits) * colSpacing / 2)
            clickX := rowStartX + (colInRow * colSpacing)
        } else {
            clickX := baseX + (colInRow * colSpacing)
        }

        clickY := baseY + (row * rowSpacing)

        if (priority > 4 && priority != 7) {
            priority := 4
        }

        if (priority == 7) {
            priority := 0
        }

        AddToLog("Set slot: " slot " priority to " priority)

        Loop priority {
            FixClick(clickX, clickY)
            Sleep(150)
        }
    }
}

UpgradeAllUnits() {
    FixClick(648, 123) ; Clicks upgrade all
    Sleep(1000)
}

HandleUnitManager(msg) {
    AddToLog(msg)
    if (AutoAbilityBox.Value && UnitManagerAutoUpgrade.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
    }
    CloseMenu("Unit Manager")
    return MonitorStage()
}

GetUpgradePriority(slotNum) {
    global
    priorityVar := "upgradePriority" slotNum
    return %priorityVar%.Value
}

InitiateTheSystem() {
    if (!isMenuOpen("Unit Manager")) {
        OpenMenu("Unit Manager") ; Failsafe
        Sleep(500)
        ClickUnit(SJWSlot.Value)
        Sleep(500)
    }

    AddToLog("Initiating the system")

    FixClick(290, 290) ; Open the system
    Sleep(500)
    WaitForRebirth()
    Sleep (500)
    FixClick(617, 122) ; close the system
    Sleep (500)
}

WaitForRebirth() {
    rebirthCount := 0
    Loop {
        FixClick(370, 245) ; Click Attack
        Sleep(200)
        FixClick(551, 293) ; Click Range

        if (CheckForXp()) {
            AddToLog("Game over detected")
            break
        }

        if (ok := FindText(&X, &Y, 466, 445, 570, 491, 0.20, 0.80, Rebirth)) {
            Sleep(100)
            FixClick(X, Y - 35)
            rebirthCount++
            AddToLog("Rebirth count: " rebirthCount " / 3")
            if (rebirthCount >= 3) {
                break
            }
        }
        Sleep 500
    }
}

UnitManagerUpgrade(slot) {
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(slot)
        Sleep(500)
    }
    Loop 3 {
        SendInput("T")
    }
}

UnitManagerUpgradeWithLimit(coord, index, upgradeLimit) {
    if !(GetPixel(0x1643C5, 77, 357, 4, 4, 2)) {
        ClickUnit(coord.upgradePriority)
        Sleep(500)
    }
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
    
}

ProcessUpgrades(slot := false, priorityNum := false, singlePass := false) {
    global successfulCoordinates, UnitManagerUpgradeSystem

    if (singlePass) {
        for index, coord in successfulCoordinates {
            if ((!slot || coord.slot = slot) && (!priorityNum || coord.upgradePriority = priorityNum)) {
                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                UpgradeUnitWithLimit(coord, index)

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                PostUpgradeChecks(priorityNum)

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                }

                PostUpgradeChecks(priorityNum)

                if (!UnitManagerUpgradeSystem.Value) {
                    SendInput("X")
                }
            }
        }

        if (slot || priorityNum)
            AddToLog("Finished single-pass upgrades for slot " slot " priority " priorityNum)

        return
    }

    ; Full upgrade loop
    while (true) {
        slotDone := true  ; Assume done, set false if any upgrade performed

        for index, coord in successfulCoordinates {
            if ((!slot || coord.slot = slot) && (!priorityNum || coord.upgradePriority = priorityNum)) {
                slotDone := false  ; Found unit to upgrade => not done yet

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                UpgradeUnitWithLimit(coord, index)

                if (StageEndedDuringUpgrades()) {
                    return HandleStageEnd()
                }

                PostUpgradeChecks(priorityNum)

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                }

                SendInput("X")

                PostUpgradeChecks(priorityNum)
            }
        }

        if ((slot || priorityNum) && (slotDone || successfulCoordinates.Length = 0)) {
            AddToLog("Finished upgrades for priority " priorityNum)
            break
        }

        if (!slot && !priorityNum)
            break
    }
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

                if (priority.Text = priorityNum && HasUnitsInSlot(slot, priorityNum, successfulCoordinates)) {
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
            UnitManagerUpgrade(coord.placementIndex)
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

PostUpgradeChecks(slotNum) {
    HandleAutoAbility(slotNum)

    if (HasCards(ModeDropdown.Text)) {
        CheckForCardSelection()
    }

    CheckForPortalSelection()
    Reconnect()
}

StageEndedDuringUpgrades() {
    return CheckForXp()
}

IsUpgradeEnabled(slotNum) {
    setting := "upgradeEnabled" slotNum
    return %setting%.Value
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

ShouldOpenUnitManager() {
    if (UnitManagerAutoUpgrade.Value || UnitManagerUpgradeSystem.Value) {
        return true
    }
}

HasUnitsInSlot(slot, priorityNum, coordinates) {
    for coord in coordinates {
        if (coord.slot = slot && coord.upgradePriority = priorityNum)
            return true
    }
    return false
}