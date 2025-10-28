#Requires AutoHotkey v2.0

global alreadyNuked := false
global waitingToNuke := false

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
    global nukeCoords, alreadyNuked, waitingToNuke

    if (alreadyNuked)
        return

    if (PrepareToNuke() || testing) {
        Sleep(150)

        if (isMenuOpen("End Screen")) {
            ClearNuke()
            return MonitorStage()
        }

        if (lookingForWave) {
            while (!TimerManager.HasExpired("Nuke")) {
                Sleep(100)
            }
        }
        AddToLog("Nuking...")
        Sleep(150)
        FixClick(nukeCoords.x, nukeCoords.y) ; click nuke
        Sleep(150)
        SendInput("X") ;close unit menu
        alreadyNuked := true
        TimerManager.Clear("Nuke")
    }
}

HandleNuke() {
    global alreadyNuked

    if (!NukeUnitSlotEnabled.Value)
        return false

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
    static coord := [{ x1: 265, y1: 32, x2: 299, y2: 55 }]

    for coords in coord {
        ocrText := ReadText(coords.x1, coords.y1, coords.x2, coords.y2, 3.0, false)
        if (debugMessages) {
            AddToLog("OCR: " ocrText)
        }

        if (InStr(ocrText, waveNumber)) {
            AddToLog("Wave " waveNumber " found")
            return true
        }
        Sleep 50
    }
    return false
}

StartNukeTimer() {
    global alreadyNuked
    alreadyNuked := false

    if (!NukeUnitSlotEnabled.Value)
        return

    if (NukeAtSpecificWave.Value) {
        AddToLog("Watching for wave " NukeWave.Text)
        SetTimer(WatchForTargetWave, 1000)
    } else {
        delay := GetNukeDelay()
        AddToLog("Nuke scheduled in " delay " ms")
        SetTimer(Nuke, delay)
    }
}

WatchForTargetWave() {
    global alreadyNuked, waitingToNuke

    if (alreadyNuked) {
        SetTimer(WatchForTargetWave, 0) ; stop checking
        return
    }

    if (CheckWaveText(NukeWave.Text) && !waitingToNuke) {
        AddToLog("Wave " NukeWave.Text " found. Nuking...")
        TimerManager.Start("Nuke", GetNukeDelay())
        Nuke(true, false)
        alreadyNuked := true
        SetTimer(WatchForTargetWave, 0) ; stop checking after nuke
    }
}