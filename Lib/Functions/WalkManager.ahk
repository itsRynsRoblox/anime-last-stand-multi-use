#Requires AutoHotkey v2.0

;Custom Walk
global waitingForWalk := false
global walkStartTime := 0

StartWalkCapture() {
    global savedWalkCoords

    ; Reset saved walk coordinates
    savedWalkCoords := []

    ; Activate Roblox window
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    AddWaitingFor("Walk")
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position every 50ms
}

WalkToCoords() {
    global savedWalkCoords

    presetIndex := PlacementProfiles.Value

    if waitingForClick {
        AddToLog("⚠️ Cannot test walk while capturing coordinates. Please stop capture first.")
        return
    }

    ; Ensure presetIndex is valid
    if (presetIndex < 1 || !savedWalkCoords.Has(presetIndex)) {
        AddToLog("⚠️ No coordinates set for Preset: " PlacementProfiles.Text)
        return  ; Return empty list if invalid index
    }

    ; Use saved coordinates for the selected preset
    for coord in savedWalkCoords[presetIndex] {
        Sleep(coord.delay)
        AddToLog("Walking to: " coord.x ", " coord.y ", Delay: " coord.delay "ms")
        FixClick(coord.x, coord.y, "Right")
    }
}

GetOrInitWalkCoords(index) {
    global savedWalkCoords
    if !IsObject(savedWalkCoords)
        savedWalkCoords := []

    ; Extend the array up to the index if needed
    while (savedWalkCoords.Length < index)
        savedWalkCoords.Push([])

    if !IsObject(savedWalkCoords[index])
        savedWalkCoords[index] := []

    return savedWalkCoords[index]
}

DeleteWalkCoordsForPreset(index) {
    global savedWalkCoords

    ; Ensure savedCoords is initialized as an object
    if !IsObject(savedWalkCoords)
        savedWalkCoords := []

    ; Extend the array up to the index if needed
    while (savedWalkCoords.Length < index)
        savedWalkCoords.Push([])

    ; Check if the preset has coordinates (i.e., non-empty)
    if (savedWalkCoords[index].Length > 0) {
        savedWalkCoords[index] := []  ; Clear the coordinates for the specified preset
        AddToLog("🗑️ Cleared walk coordinates for Preset: " PlacementProfiles.Text)
    } else {
        AddToLog("⚠️ No walk coordinates to clear for Preset: " PlacementProfiles.Text)
    }
}