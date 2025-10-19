#Requires AutoHotkey v2.0

global alreadyNuked := false
global nukeTimerActive := false
global waitingToNuke := false
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

PrepareToNuke(force := false) {
    global successfulCoordinates, maxedCoordinates, NukeUnitSlotEnabled, NukeUnitSlot

    if (force) {
        ClickUnit(1, true)
        return true
    }

    if (NukeUnitSlotEnabled.Value) {
        ; try to find in successfulCoordinates
        for index, coord in successfulCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index, true)
                return true
            }
        }
        ; try to find in maxedCoordinates
        for index, coord in maxedCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                ClickUnit(index, true)
                return true
            }
        }
        ; Not found in either list
        return false
    }

    return false  ; fallback if nothing is enabled
}

GetNukeDelay() {
    ms := NukeDelay.Value
    return Round(ms * 1000)
}

Nuke() {
    global nukeCoords, alreadyNuked, nukeTimerActive, nukeScheduledTime, waitingToNuke

    nukeTimerActive := true

    if (nukeTimerActive)
        return

    if (PrepareToNuke()) {
        Sleep(150)

        if (isMenuOpen("End Screen")) {
            ClearNuke()
            return MonitorStage()
        }

        FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
        Sleep(150)
        SendInput("X") ;close unit menu
        alreadyNuked := true
        nukeTimerActive := false  ; reset the flag
    } else {
        nukeScheduledTime := A_TickCount + GetNukeDelay() ; For logging purposes
    }
}



HandleNuke() {
    global alreadyNuked, nukeTimerActive, nukeScheduledTime

    if (!NukeUnitSlotEnabled.Value)
        return false

    if (nukeTimerActive) {
        nukeScheduledTime := A_TickCount + GetNukeDelay()
        return
    }

    nukeScheduledTime := A_TickCount + GetNukeDelay()
    nukeTimerActive := true
    SetTimer(Nuke, GetNukeDelay())
    AddToLog("Nuke scheduled for " nukeScheduledTime " (in " GetNukeDelay() " ms)")
}

ClearNuke() {
    global alreadyNuked, nukeTimerActive
    alreadyNuked := false
    nukeTimerActive := false
    nukePaused := false
    SetTimer(WatchForTargetWave, 0)
    SetTimer(Nuke, 0)
}

CheckWaveText(waveNumber) {
    static coord := [{ x1: 255, y1: 52, x2: 310, y2: 70 }]

    for coords in coord {
        ocrText := OCRFromFile(coords.x1, coords.y1, coords.x2, coords.y2, 2.0, true)
        ocrText := RegExReplace(ocrText, "[^\d\w\s]", "")
        if (debugMessages) {
            AddToLog("Wave Text: " ocrText)
        }

        if (InStr(ocrText, "Wave " waveNumber) || InStr(ocrText, "WAVE " waveNumber) || InStr(ocrText, "wave " waveNumber
        ) | InStr(ocrText, "Wave" waveNumber) || RegExMatch(ocrText, "Wave\s*" waveNumber)) {
            AddToLog("Wave " waveNumber " found.")
            return true
        }
        Sleep 50
    }
    return false
}

StartNukeTimer() {
    global nukeTimerActive, alreadyNuked

    alreadyNuked := false
    nukeTimerActive := false

    if (NukeUnitSlotEnabled.Value) {
        if (NukeAtSpecificWave.Value) {
            ; Start checking for the wave every X ms
            SetTimer(WatchForTargetWave, 1000)  ; Adjust interval as needed
            AddToLog("Started watching for wave " NukeWave.Value "...")
        } else {
            ; Schedule regular time-based nuke
            HandleNuke()
        }
    }
}

HandleSpecificWaveNuke() {
    NukeDelay := GetNukeDelay()
    wave := NukeWave.Text

    switch wave {
        case "50":
            if (!CheckForWave50())
                return false
            return true

        case "20":
            if (!CheckForWave20())
                return false
            return true

        default:
            AddToLog("Nuke at specific wave is set to unsupported wave: " wave)
            return false
    }
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

WatchForTargetWave() {
    global alreadyNuked, waitingToNuke

    if (alreadyNuked) {
        SetTimer(WatchForTargetWave, 0) ; stop checking
        return
    }

    if (HandleSpecificWaveNuke() && !waitingToNuke) {
        AddToLog("Wave " NukeWave.Value " found. Nuking...")
        Nuke()
        alreadyNuked := true
        SetTimer(WatchForTargetWave, 0) ; stop checking after nuke
    }
}
