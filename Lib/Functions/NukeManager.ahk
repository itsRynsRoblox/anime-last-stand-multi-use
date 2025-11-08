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

PrepareToNuke(force := false) {
    global successfulCoordinates, maxedCoordinates

    if !NukeUnitSlotEnabled.Value
        return false

    ; Try to find the target slot in both coordinate sets
    coord := GetNukeCoordinate()
    if !coord {
        AddToLog("⚠️ Nuke unit slot not found in coordinates.")
        SetTimer(Nuke, 2500)
        return false
    }

    AddToLog("Preparing to nuke at slot " coord.slot)

    unitManagerWasOpen := isMenuOpen("Unit Manager")

    CloseMenu("Unit Manager")
    Sleep(150)
    SendInput("X")
    Sleep(150)

    ; Try clicking until the slot is properly selected
    while (!GetPixel(0x1034AC, 78, 362, 2, 2, 2)) {

        HandleNukeChecks()

        FixClick(coord.x, coord.y)
        Sleep(250)
    }

    OpenMenu("Unit Manager")
    return true
}

GetNukeCoordinate() {
    global successfulCoordinates, maxedCoordinates
    for each, coord in successfulCoordinates {
        if (coord.slot == NukeUnitSlot.Value)
            return coord
    }
    for each, coord in maxedCoordinates {
        if (coord.slot == NukeUnitSlot.Value)
            return coord
    }
    return false
}

GetNukeDelay() {
    ms := NukeDelay.Value
    return Round(ms * 1000)
}

Nuke(lookingForWave := false, testing := false) {
    global nukeCoords, alreadyNuked

    if (alreadyNuked)
        return

    if (PrepareToNuke() || testing) {
        Sleep(150)

        HandleNukeChecks()

        if (lookingForWave) {
            while (!TimerManager.HasExpired("Nuke")) {
                HandleNukeChecks()
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

ClearNuke() {
    global alreadyNuked
    alreadyNuked := false
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
    global alreadyNuked

    if (alreadyNuked) {
        SetTimer(WatchForTargetWave, 0) ; stop checking
        return
    }

    if (CheckWaveText(NukeWave.Text)) {
        AddToLog("Wave " NukeWave.Text " found. Nuking...")
        TimerManager.Start("Nuke", GetNukeDelay())
        Nuke(true, false)
        alreadyNuked := true
        SetTimer(WatchForTargetWave, 0) ; stop checking after nuke
    }
}

HandleNukeChecks() {
    if (isMenuOpen("End Screen")) {
        ClearNuke()
        return MonitorStage()
    }
    CheckForCardSelection()
    Sleep(250)
}