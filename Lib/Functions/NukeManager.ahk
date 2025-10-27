#Requires AutoHotkey v2.0

global alreadyNuked := false
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
    global successfulCoordinates, maxedCoordinates

    unitManagerWasOpen := false

    if (NukeUnitSlotEnabled.Value) {
        ; try to find in successfulCoordinates
        for index, coord in successfulCoordinates {
            if (coord.slot == NukeUnitSlot.Value) {
                if (isMenuOpen("Unit Manager")) {
                    unitManagerWasOpen := true
                }
                CloseMenu("Unit Manager")
                Sleep(150)
                SendInput("X")
                Sleep(150)
                while (!GetPixel(0x1034AC, 78, 362, 2, 2, 2)) {
                    CheckForCardSelection()

                    if (CheckForXp()) {
                        CloseMenu("Unit Manager")
                        ClearNuke()
                        return MonitorStage()
                    }

                FixClick(coord.x, coord.y)
                Sleep(250)
                }
                OpenMenu("Unit Manager")
                return true
            }
        }
        ; try to find in maxedCoordinates
        for index, coord in maxedCoordinates {
            if (isMenuOpen("Unit Manager")) {
                unitManagerWasOpen := true
            }
            if (coord.slot == NukeUnitSlot.Value) {
                CloseMenu("Unit Manager")
                Sleep(150)
                SendInput("X")
                Sleep(150)
                while (!GetPixel(0x1034AC, 78, 362, 2, 2, 2)) {
                    CheckForCardSelection()

                    if (CheckForXp()) {
                        CloseMenu("Unit Manager")
                        ClearNuke()
                        return MonitorStage()
                    }

                    FixClick(coord.x, coord.y)
                    Sleep(250)
                }
                OpenMenu("Unit Manager")
                return true
            }
        }

        SetTimer(Nuke, 2500)

        ; Not found in either list
        return false
    }

    return false  ; fallback if nothing is enabled
}

GetNukeDelay() {
    ms := NukeDelay.Value
    return Round(ms * 1000)
}

Nuke(lookingForWave := false, testing := false) {
    global nukeCoords, alreadyNuked, nukeScheduledTime, waitingToNuke

    if (alreadyNuked)
        return

    if (PrepareToNuke() || testing) {
        Sleep(150)

        if (isMenuOpen("End Screen")) {
            ClearNuke()
            return MonitorStage()
        }

        if (lookingForWave) {
            AddToLog("Waiting " GetNukeDelay() / 1000 "s before nuking...")
            Sleep(GetNukeDelay())
        }
        AddToLog("Nuking...")
        Sleep(750)
        FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
        Sleep(150)
        SendInput("X") ;close unit menu
        alreadyNuked := true
    } else {
        nukeScheduledTime := A_TickCount + GetNukeDelay() ; For logging purposes
    }
}

HandleNuke() {
    global alreadyNuked, nukeScheduledTime

    if (!NukeUnitSlotEnabled.Value)
        return false

    nukeScheduledTime := A_TickCount + GetNukeDelay()
    SetTimer(Nuke, GetNukeDelay())
    AddToLog("Nuke scheduled in " GetNukeDelay() " ms)")
}

ClearNuke() {
    global alreadyNuked, nukePaused
    alreadyNuked := false
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
    global alreadyNuked

    alreadyNuked := false

    if (NukeUnitSlotEnabled.Value) {
        if (NukeAtSpecificWave.Value) {
            ; Start checking for the wave every X ms
            SetTimer(WatchForTargetWave, 1000)  ; Adjust interval as needed
            AddToLog("Started watching for wave " NukeWave.Text "...")
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
            if (CheckForWave50())
                return true

        case "20":
            if (CheckForWave20())
                return true

        default:
            return true
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
        AddToLog("Wave " NukeWave.Text " found. Nuking...")
        Nuke(true, false)
        alreadyNuked := true
        SetTimer(WatchForTargetWave, 0) ; stop checking after nuke
    }
}
