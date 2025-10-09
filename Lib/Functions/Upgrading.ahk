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
        for slot in slotOrder {
            for priorityNum in priorityOrder {
                if (HasUnitsInSlot(slot, successfulCoordinates)) {
                    AddToLog("Upgrading slot " slot " with priority " priorityNum)
                    ProcessUpgrades(slot, priorityNum)
                }
            }
        }
    } else {
        for priorityNum in priorityOrder {
            for slot in slotOrder {
                if (HasUnitsInSlot(slot, successfulCoordinates)) {
                    AddToLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                    ProcessUpgrades(slot, priorityNum)
                }
            }
        }
    }
    AddToLog("All units maxed, proceeding to monitor stage")
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
    if (SJWNuke.Value) {
        ClickUnit(SJWSlot.Value)
        Sleep(2000)
        InitiateTheSystem()
    } else {
        if (AutoAbilityBox.Value) {
            SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
        }
    }
    return MonitorStage()
}

GetUpgradePriority(slotNum) {
    global
    priorityVar := "upgradePriority" slotNum
    return %priorityVar%.Value
}

InitiateTheSystem() {
    global totalUnits
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
    ;WaitForWave50()
    WaitForGilgamesh()
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

WaitForWave50() {
    Loop {

        if (CheckForXp()) {
            AddToLog("Game over detected")
            break
        }

        if (ok := FindText(&X, &Y, 259, 35, 294, 52, 0.10, 0.10, Wave50)) {
            AddToLog("Found Wave 50, sleeping for 28 seconds...")
            Sleep (28000)
            AddToLog("Nuking...")
            loop 15 {
                FixClick(282, 328) ; click nuke
                Sleep(150)
            }
            break
        }
        Sleep 500
    }
}