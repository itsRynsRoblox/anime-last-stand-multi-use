#Requires AutoHotkey v2.0

;Custom Walk
global waitingForWalk := false
global walkStartTime := 0

StartWalkCapture() {
    global savedWalkCoords

    ; Make sure savedWalkCoords exists
    if !IsSet(savedWalkCoords) || !(savedWalkCoords is Map)
        savedWalkCoords := Map()

    ; Get current map from dropdown
    mapName := WalkMapDropdown.Text

    ; Clear only this map's data before capturing
    if mapName != ""
        savedWalkCoords[mapName] := []

    ; Activate Roblox window
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    AddWaitingFor("Walk")
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position
}

WalkToCoords() {
    global savedWalkCoords

    mapName := GetMapForMode(ModeDropdown.Text)

    if (waitingForClick) {
        AddToLog("⚠️ Cannot test walk while capturing coordinates.")
        return
    }

    if (!savedWalkCoords.Has(mapName) || savedWalkCoords[mapName].Length = 0) {
        return
    }

    for coord in savedWalkCoords[mapName] {
        Sleep(coord.delay)
        AddToLog("Walking to: x: " coord.x ", y: " coord.y ", delay: " coord.delay "ms")
        FixClick(coord.x, coord.y, "Right")
    }
}

GetOrInitWalkCoords(mapName) {
    global savedWalkCoords
    if !savedWalkCoords.Has(mapName)
        savedWalkCoords[mapName] := []
    return savedWalkCoords[mapName]
}

Walk(direction, duration) {
    key := "{" . direction . " down}"
    SendInput(key)
    Sleep(duration)
    key := "{" . direction . " up}"
    SendInput(key)
    KeyWait direction
    Sleep(1000)  ; Optional pause after each movement
}

SaveCustomWalk() {
    global savedWalkCoords

    filePath := A_ScriptDir "\Settings\CustomWalk.txt"

    file := FileOpen(filePath, "w")  ; 'w' = write mode (clears file)
    if !IsObject(file) {
        AddToLog("❌ Failed to open file for writing: " filePath)
        return
    }

    for mapName, coords in savedWalkCoords {
        for _, point in coords {
            line := mapName "," point.x "," point.y "," point.delay "`n"
            file.Write(line)
        }
    }

    file.Close()
}

LoadCustomWalk() {
    global savedWalkCoords
    savedWalkCoords := Map()  ; clear before loading

    filePath := A_ScriptDir "\Settings\CustomWalk.txt"

    if !FileExist(filePath) {
        AddToLog("❌ Save file not found: " filePath)
        return
    }

    file := FileOpen(filePath, "r")
    if !IsObject(file) {
        AddToLog("❌ Failed to open file: " filePath)
        return
    }

    while !file.AtEOF {
        line := file.ReadLine()
        if (line = "")  ; skip blank lines
            continue

        parts := StrSplit(line, ",")
        if (parts.Length < 4)
            continue

        mapName := parts[1]
        x := parts[2] + 0
        y := parts[3] + 0
        delay := parts[4] + 0

        if !savedWalkCoords.Has(mapName)
            savedWalkCoords[mapName] := []

        savedWalkCoords[mapName].Push({ x: x, y: y, delay: delay, mapName: mapName })
    }
    file.Close()
}

PrintSavedCoordsSummary() {
    global savedWalkCoords
    for mapName, coords in savedWalkCoords {
        AddToLog("Map: " mapName " has " coords.Length() " coordinates saved.")
    }
}

DeleteWalkCoordsForPreset(mapName) {
    global savedWalkCoords

    if !(savedWalkCoords is Map)
        savedWalkCoords := Map()

    ; If the map exists and has coords, remove it
    if savedWalkCoords.Has(mapName) && savedWalkCoords[mapName].Length > 0 {
        savedWalkCoords.Delete(mapName)
        AddToLog("🗑️ Removed all walk data for map: " mapName)
        SaveCustomWalk()
    } else {
        AddToLog("⚠️ No walk coordinates to remove for map: " mapName)
    }
}

GetMapForMode(mode) {
    switch mode {
        case "Story":
            return StoryDropdown.Text
        case "Legend Stage":
            return LegendDropDown.Text
        case "Raid":
            return RaidDropdown.Text
        case "Portal":
            return PortalDropdown.Text
        case "Custom":
            return "Custom" 
    }
    return ""
}

ExportWalkCoords(mapName) {
    global savedWalkCoords

    mapName := Trim(mapName)
    if mapName = "" || !savedWalkCoords.Has(mapName) || savedWalkCoords[mapName].Length = 0 {
        AddToLog("⚠️ No coordinates found for map: " mapName)
        return
    }

    exportDir := A_ScriptDir "\Settings\Export"
    exportFile := exportDir "\" mapName " Coords.txt"

    file := FileOpen(exportFile, "w")
    if !IsObject(file) {
        AddToLog("❌ Failed to export file for map: " mapName)
        return
    }

    for _, point in savedWalkCoords[mapName] {
        line := mapName "," point.x "," point.y "," point.delay "`n"
        file.Write(line)
    }

    file.Close()
    AddToLog("📤 Exported " savedWalkCoords[mapName].Length " coords to → Settings\Export")
}

ImportWalkCoordsFromFile() {
    global savedWalkCoords, MainUI

    ; Ensure savedWalkCoords is initialized
    if !IsSet(savedWalkCoords) || !(savedWalkCoords is Map)
        savedWalkCoords := Map()

    ; Temporarily disable AlwaysOnTop for file dialog
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    file := FileSelect(3, , "Select a walk path to import", "Text Documents (*.txt)")
    MainUI.Opt("+AlwaysOnTop")

    if !file
        return

    content := FileRead(file)
    lines := StrSplit(content, "`n")

    importedMap := ""
    coordList := []

    for line in lines {
        line := Trim(line)
        if (line = "")
            continue

        parts := StrSplit(line, ",")
        if parts.Length < 4
            continue

        mapName := Trim(parts[1])
        x := parts[2] + 0
        y := parts[3] + 0
        delay := parts[4] + 0

        if importedMap = ""
            importedMap := mapName  ; Use map from first line

        coordList.Push({ x: x, y: y, delay: delay, mapName: mapName })
    }

    if coordList.Length = 0 {
        AddToLog("⚠️ No valid coordinates found in the file.")
        return
    }

    savedWalkCoords[importedMap] := coordList
    AddToLog("📥 Imported " coordList.Length " coords for map: " importedMap)

    ; Optional: Save after importing
    SaveCustomWalk()
}