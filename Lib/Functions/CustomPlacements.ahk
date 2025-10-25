#Requires AutoHotkey v2.0

StartCoordinateCapture() {
    global savedCoords

    ; Make sure savedCoords exists
    if !IsSet(savedCoords) || !(savedCoords is Map)
        savedCoords := Map()

    ; Get current map from dropdown
    mapName := GetPlacementsForMode(ModeDropdown.Text)

    ; Clear only this map's data before capturing
    if mapName != ""
        savedCoords[mapName] := []

    ; Activate Roblox window
    if (WinExist(rblxID)) {
        WinActivate(rblxID)
    }

    AddWaitingFor("Placements")
    AddToLog("Press LShift to stop coordinate capture")
    SetTimer UpdateTooltip, 50  ; Update tooltip position
}

UseCustomPoints() {
    global savedCoords  ; Access the global saved coordinates
    points := []

    mapName := GetPlacementsForMode(ModeDropdown.Text)

    if (!savedCoords.Has(mapName) || savedCoords[mapName].Length = 0) {
        return
    }

    ; Use saved coordinates for the selected preset
    for coord in savedCoords[mapName] {
        points.Push({ x: coord.x, y: coord.y })
    }

    AddToLog("Points: " points.Length)

    return points
}

GetOrInitCustomCoords(mapName) {
    global savedCoords
    if !savedCoords.Has(mapName)
        savedCoords[mapName] := []
    return savedCoords[mapName]
}

SaveCustomPlacements() {
    global savedCoords

    filePath := A_ScriptDir "\Settings\CustomPlacements.txt"

    file := FileOpen(filePath, "w")  ; 'w' = write mode (clears file)
    if !IsObject(file) {
        AddToLog("❌ Failed to open file for writing: " filePath)
        return
    }

    for mapName, coords in savedCoords {
        for _, point in coords {
            line := mapName "," point.x "," point.y "`n"
            file.Write(line)
        }
    }

    file.Close()
}

LoadCustomPlacements() {
    global savedCoords
    savedCoords := Map()  ; clear before loading

    filePath := A_ScriptDir "\Settings\CustomPlacements.txt"

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
        if (parts.Length < 3)
            continue

        mapName := parts[1]
        x := parts[2] + 0
        y := parts[3] + 0

        if !savedCoords.Has(mapName)
            savedCoords[mapName] := []

        savedCoords[mapName].Push({ x: x, y: y, mapName: mapName })
    }
    file.Close()
}

PrintSavedCoords() {
    global savedCoords
    for mapName, coords in savedCoords {
        AddToLog("Map: " mapName " has " coords.Length " coordinates saved.")
    }
}

DeleteCustomCoordsForPreset(mapName) {
    global savedCoords

    if !(savedCoords is Map)
        savedCoords := Map()

    ; If the map exists and has coords, remove it
    if savedCoords.Has(mapName) && savedCoords[mapName].Length > 0 {
        savedCoords.Delete(mapName)
        AddToLog("🗑️ Removed all custom placements for map: " mapName)
        SaveCustomPlacements()
    } else {
        AddToLog("⚠️ No custom placements to remove for map: " mapName)
    }
}

GetPlacementsForMode(mode) {
    switch mode {
        case "Story":
            return StoryDropdown.Text
        case "Legend Stage":
            return LegendDropDown.Text
        case "Raid":
            return RaidDropdown.Text
        case "Portal":
            return PortalDropdown.Text
        case "Event":
            return EventDropdown.Text    
        case "Custom":
            return CustomPlacementMapDropdown.Text    
    }
    return CustomPlacementMapDropdown.Text
}

ExportCustomCoords(mapName) {
    global savedCoords

    mapName := Trim(mapName)
    if mapName = "" || !savedCoords.Has(mapName) || savedCoords[mapName].Length = 0 {
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

    for _, point in savedCoords[mapName] {
        line := mapName "," point.x "," point.y "`n"
        file.Write(line)
    }

    file.Close()
    AddToLog("📤 Exported " savedCoords[mapName].Length " coords to → Settings\Export")
}

ImportCustomCoords() {
    global savedCoords, MainUI

    ; Ensure savedCoords is initialized
    if !IsSet(savedCoords) || !(savedCoords is Map)
        savedCoords := Map()

    ; Temporarily disable AlwaysOnTop for file dialog
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    file := FileSelect(3, , "Select a file to import", "Text Documents (*.txt)")
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
        if parts.Length < 3
            continue

        mapName := Trim(parts[1])
        x := parts[2] + 0
        y := parts[3] + 0

        if importedMap = ""
            importedMap := mapName  ; Use map from first line

        coordList.Push({ x: x, y: y, mapName: mapName })
    }

    if coordList.Length = 0 {
        AddToLog("⚠️ No valid coordinates found in the file.")
        return
    }

    savedCoords[importedMap] := coordList
    AddToLog("📥 Imported " coordList.Length " placements for map: " importedMap)

    ; Optional: Save after importing
    SaveCustomPlacements()
}