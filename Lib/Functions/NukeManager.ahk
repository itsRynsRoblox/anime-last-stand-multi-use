#Requires AutoHotkey v2.0

global alreadyNuked := false

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
    global nukeCoords, alreadyNuked

    if (!NukeUnitSlotEnabled.Value || alreadyNuked) {
        return
    }

    nukeDelay := GetNukeDelay()

    ; --- Specific Wave Logic ---
    if (NukeAtSpecificWave.Value) {
        if (NukeWave.Text = 50) {
            if (!CheckForWave50()) {
                return
            }

            AddToLog("Found Wave 50, preparing to nuke after " nukeDelay / 1000 " seconds...")

            if (AutoAbilityBox.Value) {
                SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
            }

            PrepareToNuke()
            Sleep(nukeDelay)
            Nuke()
        } else {
            AddToLog("Nuke at specific wave is set to unsupported wave: " NukeWave.Text)
        }

        return
    }

    ; --- Time-based Nuke Logic ---
    if (A_TickCount - stageStartTime >= nukeDelay) {
        AddToLog("Nuke time reached, nuking immediately...")
        PrepareToNuke()
        Sleep (150)
        Nuke()
    }
}


GetNukeDelay() {
    ms := NukeDelay.Value
    return Round(ms * 1000)
}

Nuke() {
    global nukeCoords, alreadyNuked
    FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
    Sleep(150)
    SendInput("X") ;close unit menu
    alreadyNuked := true
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer()) ; Resume auto ability checks
    }
}