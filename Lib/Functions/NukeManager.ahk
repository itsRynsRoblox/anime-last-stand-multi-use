#Requires AutoHotkey v2.0

global alreadyNuked := false
global nukeTimerActive := false
global nukePaused := false
global nukeScheduledTime := 0

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
                return true
            }
        }
        ; try to find in maxedCoordinates
        for index, coord in maxedCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index)
                return true
            }
        }
        ; Not found in either list
        return false
    }
}

CheckIfShouldNuke() {
    global nukeCoords, alreadyNuked, stageStartTime, nukeTimerActive

    if (!NukeUnitSlotEnabled.Value || alreadyNuked)
        return false

    nukeDelay := GetNukeDelay()

    ; --- Handle "Nuke at Specific Wave" Option ---
    if (NukeAtSpecificWave.Value)
        return HandleSpecificWaveNuke(nukeDelay)

    ; --- Fallback: Time-Based Nuke ---
    return true
}

HandleSpecificWaveNuke(nukeDelay) {
    wave := NukeWave.Text

    switch wave {
        case "50":
            if (!CheckForWave50())
                return false
            AddToLog("Found Wave 50, preparing to nuke after " nukeDelay / 1000 " seconds...")
            return true

        case "20":
            if (!CheckForWave20())
                return false
            AddToLog("Found Wave 20, preparing to nuke after " nukeDelay / 1000 " seconds...")
            return true

        default:
            AddToLog("Nuke at specific wave is set to unsupported wave: " wave)
            return false
    }
}

GetNukeDelay() {
    ms := NukeDelay.Value
    return Round(ms * 1000)
}

Nuke() {
    global nukeCoords, alreadyNuked, nukeTimerActive, nukeScheduledTime

    nukeTimerActive := true
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
        SendInput("X") ;close unit menu
    }

    if (PrepareToNuke()) {
        Sleep(150)
        FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
        Sleep(150)
        SendInput("X") ;close unit menu
        alreadyNuked := true
        nukeTimerActive := false  ; reset the flag
        if (AutoAbilityBox.Value) {
            SetTimer(CheckAutoAbility, GetAutoAbilityTimer()) ; Resume auto ability checks
        }
    } else {
        nukeScheduledTime := A_TickCount + GetNukeDelay() ; For logging purposes
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

HandleNuke() {
    global alreadyNuked, nukeTimerActive, nukeScheduledTime

    if (alreadyNuked || nukeTimerActive) {
        nukeScheduledTime := A_TickCount + GetNukeDelay()
        return
    }

    if CheckIfShouldNuke() {
        nukeScheduledTime := A_TickCount + GetNukeDelay()
        nukeTimerActive := true
        SetTimer(Nuke, (NukeAtSpecificWave.Value ? -GetNukeDelay() : GetNukeDelay()))
        AddToLog("Nuke scheduled for " nukeScheduledTime " (in " GetNukeDelay() " ms)")
    }
}

ClearNuke() {
    global alreadyNuked, nukeTimerActive
    alreadyNuked := false
    nukeTimerActive := false
    SetTimer(Nuke, 0)
}

GetRemainingNukeTime() {
    global nukeScheduledTime
    remaining := nukeScheduledTime - A_TickCount
    return (remaining > 0) ? remaining : 0
}

PauseNuke() {
    global nukeTimerActive, nukePaused, nukeResumeDelay

    if nukeTimerActive {
        SetTimer(Nuke, 0)
        nukeTimerActive := false
        nukePaused := true
        nukeResumeDelay := GetRemainingNukeTime()
        AddToLog("Nuke check paused with " Round(nukeResumeDelay / 1000, 1) " seconds remaining.")
    }
}

ResumeNuke() {
    global nukePaused, nukeTimerActive, nukeResumeDelay

    if nukePaused {
        SetTimer(Nuke, (NukeAtSpecificWave.Value ? -nukeResumeDelay : nukeResumeDelay))
        nukePaused := false
        nukeTimerActive := true
        AddToLog("Nuke check resumed, will check in " Round(nukeResumeDelay / 1000, 1) " seconds.")
    }
}