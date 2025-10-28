#Requires AutoHotkey v2.0

CheckAutoAbility() {
    if (!HasUnitForAbilityCheck()) {
        return  ; No units to check
    }

    AddToLog("Checking auto abilities of placed units...")
    CloseMenu("Unit Manager")
    global successfulCoordinates, maxedCoordinates

    ; Process successfulCoordinates
    for index, coord in successfulCoordinates {
        if (!coord.hasAbility)
            continue

        if (ProcessAbility(coord)) {
            successfulCoordinates[index].hasAbility := false
        }
    }

    ; Process maxedCoordinates
    for index, coord in maxedCoordinates {
        if (!coord.hasAbility)
            continue

        if (ProcessAbility(coord)) {
            maxedCoordinates[index].hasAbility := false
        }
    }

    AddToLog("Finished looking for abilities")
    if (ShouldOpenUnitManager()) {
        OpenMenu("Unit Manager")
    }
}

HasUnitForAbilityCheck() {
    global successfulCoordinates, maxedCoordinates

    for coord in successfulCoordinates {
        if (coord.hasAbility)
            return true
    }

    for coord in maxedCoordinates {
        if (coord.hasAbility)
            return true
    }

    return false
}

ProcessAbility(coord) {

    slot := coord.slot

    if (isMenuOpen("End Screen")) {
        AddToLog("Stopping auto ability check because the game ended")
        MonitorStage()
        return false
    }

    if (HasCards(ModeDropdown.Text) || HasCards(EventDropdown.Text)) {
        CheckForCardSelection()
    }

    if (NukeUnitSlotEnabled.Value && slot = NukeUnitSlot.Value) {
        return false
    }

    FixClick(coord.x, coord.y)
    Sleep(500)

    if (HandleAutoAbility()) {
        return true
    }

    return false
}

GetAutoAbilityTimer() {
    seconds := AutoAbilityTimer.Value
    return Round(seconds * 1000)
}

ActiveAbilityEnabled() {
    if (autoAbilityDisabled) {
        return false
    }

    if (AutoAbilityBox.Value) {
        return true
    }
    return false
}

HandleAutoAbility() {
    if (!ActiveAbilityEnabled()) {
        return
    }

    wiggle()

    pixelChecks := [
        {color: 0xC82521, x: 326, y: 284},
        {color: 0xC82521, x: 326, y: 265},
        {color: 0xC82521, x: 326, y: 303}
    ]

    foundAbility := false

    for pixel in pixelChecks {
        if GetPixel(pixel.color, pixel.x, pixel.y, 2, 2, 20) {
            FixClick(pixel.x, pixel.y)
            Sleep(500)
            foundAbility := true
        }
    }

    return foundAbility
}

HandleAutoAbilityUnitManager() {
    if !AutoAbilityBox.Value
        return

    wiggle()

    ; Grid configuration
    baseX := 675            ; Left column starting X
    xOffset := 95             ; Distance between columns
    baseY := 130            ; Top row starting Y
    yStep := 60             ; Vertical gap between rows
    numRows := 8              ; Total rows to scan
    numCols := 2              ; Columns per row
    color := 0xC22725       ; Target pixel color

    ; Scan grid
    loop numRows {
        rowIndex := A_Index - 1
        rowY := baseY + rowIndex * yStep

        loop numCols {
            colIndex := A_Index - 1
            colX := baseX + colIndex * xOffset

            if GetPixel(color, colX, rowY, 4, 4, 20) {
                FixClick(colX, rowY)
                Sleep(100)
            }
        }
    }
}