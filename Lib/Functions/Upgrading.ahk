#Requires AutoHotkey v2.0

UpgradeUnits() {

    SetTotalUnits()

    if (ShouldOpenUnitManager()) {
        OpenMenu("Unit Manager")
    }

    if (PriorityUpgrade.Value) {
        UpgradeWithPriority()
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

    for priorityNum in priorityOrder {
        for slot in slotOrder {
            if (HasUnitsInSlot(slot, priorityNum, successfulCoordinates)) {
                AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                ProcessUpgrades(slot, priorityNum)
            }
        }
    }

    AddToLog("All units maxed, proceeding to monitor stage")
    if (ActiveAbilityEnabled()) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
    }
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
    if (AutoAbilityBox.Value) {
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
        ClickUnit(coord.placementIndex)
        Sleep(500)
    }
    if (WaitForUpgradeLimitText(upgradeLimit + 1, 750)) {
        HandleMaxUpgrade(coord, index)
    } else {
        SendInput("T")
    }
}  

ProcessUpgrades(slot := false, priorityNum := false) {
    global successfulCoordinates

    ; Full upgrade loop
    while (true) {
        slotDone := true

        for index, coord in successfulCoordinates {

            if (coord.autoUpgrade) {
                continue
            }

            if ((!slot || coord.slot = slot) && (!priorityNum || coord.upgradePriority = priorityNum)) {
                slotDone := false  ; Found unit to upgrade => not done yet

                UpgradeUnitWithLimit(coord, index)

                PostUpgradeChecks(coord)

                if (MaxUpgrade()) {
                    HandleMaxUpgrade(coord, index)
                }

                if (!UnitManagerUpgradeSystem.Value) {
                    SendInput("X")
                }

                PostUpgradeChecks(coord)
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
    slot := coord.slot
    placementIndex := coord.placementIndex
    x := coord.x
    y := coord.y

    isLimitDisabled := !IsUpgradeLimitEnabled(slot) || unitUpgradeLimitDisabled
    useUnitManager := UnitManagerUpgradeSystem.Value

    if isLimitDisabled {
        if useUnitManager {
            UnitManagerUpgrade(placementIndex)
        } else {
            UpgradeUnit(x, y)
        }
        return
    }

    limit := GetUpgradeLimit(slot)
    if useUnitManager {
        UnitManagerUpgradeWithLimit(coord, index, limit)
    } else {
        UpgradeUnitLimit(coord, index, limit)
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

IsUpgradeLimitEnabled(slotNum) {
    setting := "upgradeLimitEnabled" slotNum
    return %setting%.Value
}

GetUpgradeLimit(slotNum) {
    setting := "upgradeLimit" slotNum
    return %setting%.Text
}

HandleMaxUpgrade(coord, index) {
    global successfulCoordinates, maxedCoordinates

    AddToLog("Max upgrade reached for Unit: " coord.slot)
    maxedCoordinates.Push(coord)
    successfulCoordinates.RemoveAt(index)
    SendInput("X")
}

PostUpgradeChecks(coord) {

    if (isMenuOpen("End Screen")) {
        return HandleStageEnd()
    }

    CheckShouldRestart()

    if ((!NukeUnitSlotEnabled.Value || coord.slot != NukeUnitSlot.Value) && coord.hasAbility) {
        HandleAutoAbility()
    }

    if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
        CheckForCardSelection()
    }

    if (isMenuOpen("End Screen")) {
        return HandleStageEnd()
    }

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
    if (UnitManagerUpgradeSystem.Value) {
        return true
    }
}

HasUnitsInSlot(slot, priorityNum, coordinates) {
    for coord in coordinates {
        if (coord.slot = slot && coord.upgradePriority = priorityNum && !coord.autoUpgrade)
            return true
    }
    return false
}

SetAutoUpgradeForSingleUnit(unitIndex := 1) {
    global successfulCoordinates

    ; Clone and sort by placementIndex
    sorted := successfulCoordinates.Clone()
    loop sorted.Length {
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

    if (unitIndex < 1 || unitIndex > totalCount) {
        return
    }

    fullRows := Floor(totalCount / maxCols)
    lastRowUnits := Mod(totalCount, maxCols)

    unit := sorted[unitIndex]
    slot := unit.slot
    priority := unit.upgradePriority

    placementIndex := unitIndex - 1
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

    ; Normalize priority values
    if (priority > 4 && priority != 7)
        priority := 4
    if (priority == 7)
        priority := 0

    if (priority = 0) {
        return
    }

    ; Perform upgrade clicks
    loop priority {
        AddToLog("🔹 Click " A_Index " at X" clickX ", Y" clickY)
        FixClick(clickX, clickY)
        Sleep(150)
    }
}

SetTotalUnits() {
    global totalUnits, successfulCoordinates

    for coord in successfulCoordinates {
        totalUnits[coord.slot] := (totalUnits.Has(coord.slot) ? totalUnits[coord.slot] + 1 : 1)
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

UpgradeUnit(x, y) {
    FixClick(x, y)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
    SendInput ("{T}")
    Sleep (50)
}