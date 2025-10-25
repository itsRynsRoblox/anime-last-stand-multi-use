#Requires AutoHotkey v2.0

global movementKeys := ["w", "a", "s", "d"]
global activeHotkeys := []
global firstKeyPressed := false

Walk(direction, duration) {
    key := "{" . direction . " down}"
    SendInput(key)
    Sleep(duration)
    key := "{" . direction . " up}"
    SendInput(key)
    KeyWait direction
    Sleep(1000)  ; Optional pause after each movement
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
        case "Event":
            return EventDropdown.Text
        case "Custom":
            return WalkMapDropdown.Text
    }
    return ""
}

; === Start of new walk functions ===

StartRecordingWalk(*) {
    global recording, allWalks, keyDownTimes, lastActionTime, activeHotkeys, movementKeys, firstKeyPressed

    mapName := WalkMapDropdown.Text

    if !allWalks.Has(mapName)
        allWalks[mapName] := []
    allWalks[mapName] := [] ; clear old recording
    recording := true
    keyDownTimes := Map()
    lastActionTime := A_TickCount
    firstKeyPressed := false
    AddToLog("Starting map movement recording for: " mapName)
    AddToLog("Press LShift to stop recording")
    for key in movementKeys {
        downHK := Hotkey("~*" key, RecordKeyDown.Bind(key))
        upHK := Hotkey("~*" key " up", RecordKeyUp.Bind(key))
        activeHotkeys.Push(downHK)
        activeHotkeys.Push(upHK)
    }

    if (!WinActivate(rblxID)) {
        WinActivate(rblxID)
    }
}

StopRecordingWalk(*) {
    global recording, activeHotkeys

    if !recording
        return

    recording := false
    AddToLog("Movement recording stopped, saving...")

    for hk in activeHotkeys {
        try hk.Delete
    }
    activeHotkeys := []  ; clear list
    SaveAllMovements()
}

RecordKeyDown(key, *) {
    global recording, keyDownTimes
    if !recording
        return
    if !keyDownTimes.Has(key)
        keyDownTimes[key] := A_TickCount
}

RecordKeyUp(key, *) {
    global recording, allWalks, keyDownTimes, lastActionTime, firstKeyPressed
    if !recording || !keyDownTimes.Has(key)
        return

    currentMap := WalkMapDropdown.Text
    now := A_TickCount
    pressStart := keyDownTimes[key]
    duration := now - pressStart

    if !firstKeyPressed {
        delay := 0
        firstKeyPressed := true
    } else {
        delay := pressStart - lastActionTime
    }

    lastActionTime := now
    keyDownTimes.Delete(key)
    entry := { key: key, duration: duration, delay: delay }
    allWalks[currentMap].Push(entry)
    AddToLog("Registered Key: " key " (" duration " ms, +" delay " ms delay)")
}

StartWalk(testing := false) {
    global allWalks

    currentMap := testing ? WalkMapDropdown.Text : GetMapForMode(ModeDropdown.Text)

    if !allWalks.Has(currentMap) || allWalks[currentMap].Length = 0 {
        if (debugMessages) {
            AddToLog("No recording for map: " currentMap)
        }
        return false
    }

    if (!WinActivate(rblxID)) {
        WinActivate(rblxID)
    }

    data := allWalks[currentMap]

    for entry in data {
        AddToLog("[Walking] Sending Key: " entry.key ", Duration: " entry.duration "ms , Delay: " entry.delay "ms")
        Sleep(entry.delay)
        Send("{" entry.key " down}")
        Sleep(entry.duration)
        Send("{" entry.key " up}")
        KeyWait entry.key
    }
    return true
}

SaveAllMovements(*) {
    global allWalks
    try {
        folder := A_ScriptDir "\Settings"
        if !DirExist(folder)
            DirCreate(folder)

        file := FileOpen(folder "\CustomMovements.txt", "w", "UTF-8")
        for mapName, actions in allWalks {
            for entry in actions {
                line := Format("{},{},{},{}`n", mapName, entry.key, entry.duration, entry.delay)
                file.Write(line)
            }
        }
        file.Close()
    } catch Error {
        AddToLog("Error saving custom movements: " Error)
    }
}

LoadAllMovements(*) {
    global allWalks
    if !FileExist(A_ScriptDir "\Settings\CustomMovements.txt") {
        FileAppend("", A_ScriptDir "\Settings\CustomMovements.txt")
        return
    }

    allWalks := Map()
    for line in StrSplit(FileRead(A_ScriptDir "\Settings\CustomMovements.txt", "UTF-8"), "`n") {
        if (Trim(line) = "")
            continue
        parts := StrSplit(line, ",")
        if (parts.Length < 4)
            continue

        mapName := parts[1]
        key := parts[2]
        duration := parts[3]
        delay := parts[4]

        if !allWalks.Has(mapName)
            allWalks[mapName] := []

        allWalks[mapName].Push({ key: key, duration: duration, delay: delay })
    }
}

ExportMovements(mapName := "") {
    global allWalks

    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    ; Default: export all maps
    if (mapName = "") {
        filePath := exportDir "\Exported Movements - All.txt"
        AddToLog("Exporting all maps to " filePath)
        entries := allWalks
    } else if !allWalks.Has(mapName) {
        AddToLog("No recording found for map: " mapName)
        return
    } else {
        filePath := exportDir "\Exported Movements - " mapName ".txt"
        AddToLog("Exporting map '" mapName "' to " filePath)
        entries := Map()
        entries[mapName] := allWalks[mapName]
    }

    try {
        file := FileOpen(filePath, "w", "UTF-8")
        for mName, actions in entries {
            for entry in actions {
                line := Format("{},{},{},{}`n", mName, entry.key, entry.duration, entry.delay)
                file.Write(line)
            }
        }
        file.Close()
        AddToLog("✅ Export successful.")
    } catch Error {
        AddToLog("❌ Export failed: " Error)
    }
}

ImportMovements(*) {
    global allWalks

    ; Ensure allWalks exists
    if !IsObject(allWalks)
        allWalks := Map()

    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    ; Prompt user to select file
    filePath := FileSelect("Select a movement file to import", "", A_ScriptDir "\Settings", "Text Files (*.txt)")

    MainUI.Opt("+AlwaysOnTop")

    if filePath = ""
        return

    if !FileExist(filePath) {
        return
    }

    try {
        content := FileRead(filePath, "UTF-8")
        lines := StrSplit(content, "`n")
        importedCount := 0
        replacedMaps := Map()  ; keep track of which maps are replaced

        for line in lines {
            line := Trim(line, "`r`n ") ; remove CRLF and spaces
            if (line = "")
                continue

            parts := StrSplit(line, ",")
            if (parts.Length < 4) {
                AddToLog("⚠ Skipping malformed line: " line)
                continue
            }

            mapName := parts[1]
            key := parts[2]
            duration := parts[3]
            delay := parts[4]

            ; If this is the first time we see this map in this import, clear old data
            if !replacedMaps.Has(mapName) {
                allWalks[mapName] := []  ; replace existing map
                replacedMaps[mapName] := true
            }

            allWalks[mapName].Push({ key: key, duration: duration, delay: delay })
            importedCount++
        }

        AddToLog("✅ Imported " importedCount " movement(s)")
        SaveAllMovements()
    } catch Error {
        AddToLog("❌ Import failed")
    }
}

ClearMovement(*) {
    global allWalks
    mapName := WalkMapDropdown.Text

    if !allWalks.Has(mapName) {
        AddToLog("No recording found for map: " mapName)
        return
    }

    AddToLog("Clearing movements for map: " mapName)
    allWalks.Delete(mapName)
    SaveAllMovements()
}