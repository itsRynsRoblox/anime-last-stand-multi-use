#Requires AutoHotkey v2.0

StartNukeCapture() {
    global waitingForClick, waitingState, nukeCoords

    ; Reset saved walk coordinates
    nukeCoords := []

    ; Activate Roblox window
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    waitingForClick := true
    waitingState := "Nuke"
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position every 50ms
}

CheckForWave50() {
    if (ok := FindText(&X, &Y, 259, 35, 294, 52, 0.10, 0.10, Wave50)) {
        return true
    }
    return false
}

PrepareToNuke() {
    global successfulCoordinates
    if (NukeUnitSlotEnabled.Value) {
        for index, coord in successfulCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index)
                break
            }
        } else {
            AddToLog("Nuke unit not found.")
        }
    }
}

CheckIfShouldNuke() {
    global nukeCoords
    if (!NukeUnitSlotEnabled.Value) {
        return
    }

    if (!CheckForWave50()) {
        return
    }

    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
    }

    AddToLog("Found Wave 50, sleeping for 15 seconds...")
    PrepareToNuke()
    Sleep (25000)
    AddToLog("Nuking...")
    FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
    Sleep(150)

    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer()) ; Resume auto ability checks
    }
}