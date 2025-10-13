#Requires AutoHotkey v2.0

global alreadyNuked := false

StartNukeCapture() {
    global nukeCoords

    ; Reset saved walk coordinates
    nukeCoords := []

    ; Activate Roblox window
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    AddWaitingFor("Nuke")
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position every 50ms
}

CheckForWave50() {
    if (ok := FindText(&X, &Y, 259, 35, 294, 52, 0.10, 0.10, Wave50)) {
        return true
    }
    return false
}

CheckForWave20() {
    if (ok := FindText(&X, &Y, 259, 35, 294, 52, 0.10, 0.10, Wave20)) {
        return true
    }
    return false
}

PrepareToNuke() {
    global successfulCoordinates, maxedCoordinates
    if (NukeUnitSlotEnabled.Value) {
        ; try to find in successfulCoordinates
        for index, coord in successfulCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index)
                return
            }
        }
        ; try to find in maxedCoordinates
        for index, coord in maxedCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index)
                return
            }
        }
        ; Not found in either list
        AddToLog("Nuke unit not found.")
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
        } else if (NukeWave.Text = 20) {
            if (!CheckForWave20()) {
                return
            }

            AddToLog("Found Wave 20, preparing to nuke after " nukeDelay / 1000 " seconds...")

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

WaitForGilgamesh() {
    loop {

        if (CheckForXp()) {
            AddToLog("Game over detected")
            break
        }

        if (ok := FindText(&X, &Y, 362, 117, 445, 134, 0, 0.10, Gilgamesh)) {
            AddToLog("Using Cup of Rebirth...")
            loop 15 {
                FixClick(282, 328) ; click nuke
                Sleep(150)
            }
            break
        }
        Sleep 500
    }
}