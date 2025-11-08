#Requires AutoHotkey v2.0

global recordingActions := false
global lastActionTime := 0
global activeActionHotkeys := []
global firstAction := true
global loopPlayback := false
global keyPressStart := Map()
global shouldLoop := false


GetValidKeyList() {
    return ["w", "a", "s", "d", "space", "f", "v", "1", "2", "3", "4", "5", "6", "i", "o"]
}

StartRecordingActionsForMap(*) {
    global allRecordings, firstAction, lastActionTime, activeActionHotkeys, recordingActions

    RemoveActiveHotkeys()

    recordingMap := RecordMapDropdown.Text

    if !allRecordings.Has(recordingMap)
        allRecordings[recordingMap] := []
    allRecordings[recordingMap] := []

    firstAction := true
    recordingActions := true
    lastActionTime := 0
    activeActionHotkeys := []

    ; Register hotkeys dynamically
    for btn in ["LButton", "RButton", "MButton"] {
        activeActionHotkeys.Push(Hotkey("~*" btn, RecordMouseDown.Bind(btn), "On"))
        activeActionHotkeys.Push(Hotkey("~*" btn " up", RecordMouseUp.Bind(btn), "On"))
    }

    for key in GetValidKeyList() { ; your list of keys
        activeActionHotkeys.Push(Hotkey("~*" key, RecordKeyDownAction.Bind(key), "On"))
        activeActionHotkeys.Push(Hotkey("~*" key " up", RecordKeyUpAction.Bind(key), "On"))
    }

    ; Stop hotkey
    activeActionHotkeys.Push(Hotkey("~LShift", StopRecordingActions, "On"))

    if (!WinActive(rblxID)) {
        WinActivate(rblxID)
    }

    AddToLog("Started recording actions for map: " recordingMap)
    AddToLog("Press LShift to stop recording")
}

StopRecordingActions(*) {
    global allRecordings, recordingActions

    recordingMap := RecordMapDropdown.Text

    if !recordingActions
        return

    recordingActions := false
    
    AddToLog("⏹️ Recording stopped for map: " recordingMap)
    RemoveActiveHotkeys()
    SaveAllRecordings()
}

RecordKeyDownAction(key, *) {
    global recordingActions, keyPressStart
    if !recordingActions
        return
    if !keyPressStart.Has(key)
        keyPressStart[key] := A_TickCount
}

RecordKeyUpAction(key, *) {
    global recordingActions, keyPressStart, lastActionTime, firstAction, allRecordings
    if !recordingActions || !keyPressStart.Has(key)
        return

    currentMap := RecordMapDropdown.Text

    now := A_TickCount
    pressStart := keyPressStart[key]
    duration := now - pressStart

    ; --- Handle first action ---
    if firstAction {
        delay := 0
        firstAction := false
    } else {
        delay := pressStart - lastActionTime
    }

    lastActionTime := now
    keyPressStart.Delete(key)

    allRecordings[currentMap].Push({ type: "key", key: key, delay: delay, duration: duration })
    AddToLog("⌨️ Recorded key: " key " (" duration " ms, +" delay " ms delay)")
}

RecordMouseDown(btn, *) {
    global recordingActions, keyPressStart
    if !recordingActions
        return
    keyPressStart[btn] := A_TickCount
}

RecordMouseUp(btn, *) {
    global recordingActions, keyPressStart, lastActionTime, firstAction, allRecordings
    if !recordingActions || !keyPressStart.Has(btn)
        return

    currentMap := RecordMapDropdown.Text

    now := A_TickCount
    pressStart := keyPressStart[btn]
    duration := now - pressStart

    if firstAction {
        delay := 0
        firstAction := false
    } else {
        delay := pressStart - lastActionTime
    }

    lastActionTime := now
    keyPressStart.Delete(btn)

    MouseGetPos(&x, &y)
    allRecordings[currentMap].Push({ type: "mouse", btn: btn, x: x, y: y, delay: delay, duration: duration })
    AddToLog("🖱️ Recorded " btn " click at (" x ", " y ") (" duration " ms, +" delay " ms delay)")
}

PlayRecordedActions() {
    global allRecordings, activeActionHotkeys, shouldLoop

    mapName := GetRecordingMap(ModeDropdown.Text)

    if !allRecordings.Has(mapName) || allRecordings[mapName].Length = 0 {
        AddToLog("⚠️ No recorded actions found for map: " mapName)
        return
    }

    RemoveActiveHotkeys()

    actions := allRecordings[mapName]

    ; Stop hotkey
    activeActionHotkeys.Push(Hotkey("~LShift", StopPlayback))

    AddToLog("Press LShift to stop playback")
    AddToLog("▶️ Playing back " actions.Length " recorded actions for map: " mapName)

    if (!WinActivate(rblxID))
        WinActivate(rblxID)

    shouldLoop := ShouldLoopRecording.Value

    while (shouldLoop) {
        for action in actions {

            HandlePlaybackChecks()

            Sleep(action.delay)

            HandlePlaybackChecks()

            if (action.type = "key") {
                Send("{" action.key " down}")
                Sleep(action.duration)
                Send("{" action.key " up}")
            } else if (action.type = "mouse") {
                Click action.x, action.y, "Down"
                Sleep(action.duration)
                Click action.x, action.y, "Up"
            }
        }
    } else {
        for action in actions {

            HandlePlaybackChecks()
            Sleep(action.delay)
            HandlePlaybackChecks()

            if (action.type = "key") {
                Send("{" action.key " down}")
                Sleep(action.duration)
                Send("{" action.key " up}")
            } else if (action.type = "mouse") {
                Click action.x, action.y, "Down"
                Sleep(action.duration)
                Click action.x, action.y, "Up"
            }
        }
        if (ShouldHandleGameEnd.Value) {
            AddToLog("Finished playback for map: " mapName ", waiting for game end...")
            return MonitorStage()
        }
    }
}

StopPlayback(*) {
    global shouldLoop

    shouldLoop := false

    RemoveActiveHotkeys()
    AddToLog("⏹️ Playback loop stopped.")
}

SaveAllRecordings(*) {
    global allRecordings
    try {
        folder := A_ScriptDir "\Settings"
        if !DirExist(folder)
            DirCreate(folder)

        file := FileOpen(folder "\CustomRecordings.txt", "w", "UTF-8")

        for mapName, actions in allRecordings {
            for action in actions {
                if (action.type = "key") {
                    duration := action.duration
                    delay := action.delay
                    line := Format("{},{},{},{},{}`n", mapName, action.type, action.key, duration, delay)
                } else if (action.type = "mouse") {
                    duration := action.duration
                    delay := action.delay
                    line := Format("{},{},{},{},{},{},{}`n", mapName, action.type, action.btn, action.x, action.y,
                        duration, delay)
                }
                file.Write(line)
            }
        }

        file.Close()
    } catch Error {
        AddToLog("⚠️ Error saving recordings")
    }
}

LoadAllRecordings(*) {
    global allRecordings
    allRecordings := Map()

    filePath := A_ScriptDir "\Settings\CustomRecordings.txt"
    if !FileExist(filePath) {
        FileAppend("", filePath)
        return
    }

    lines := StrSplit(FileRead(filePath, "UTF-8"), "`n")

    for line in lines {
        if (Trim(line) = "")
            continue

        parts := StrSplit(line, ",")
        mapName := parts[1]
        type := parts[2]

        if !allRecordings.Has(mapName)
            allRecordings[mapName] := []

        if (type = "key") {
            recorded := { type: "key", key: parts[3], duration: parts[4], delay: parts[5] }
        } else if (type = "mouse") {
            recorded := { type: "mouse", btn: parts[3], x: parts[4], y: parts[5], duration: parts[6], delay: parts[7] }
        }
        allRecordings[mapName].Push(recorded)
    }
}

ExportRecordings(mapName := "") {
    global allRecordings

    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    ; If no map name provided -> export ALL
    if (mapName = "") {
        filePath := exportDir "\Exported Recordings - All.txt"
        AddToLog("Exporting all recordings to " filePath)
        entries := allRecordings
    } else if !allRecordings.Has(mapName) {
        AddToLog("❌ No recordings found for map: " mapName)
        return
    } else {
        filePath := exportDir "\Exported Recordings - " mapName ".txt"
        AddToLog("Exporting recordings for '" mapName "' to " filePath)
        entries := Map()
        entries[mapName] := allRecordings[mapName]
    }

    try {
        file := FileOpen(filePath, "w", "UTF-8")

        for mName, actions in entries {
            for action in actions {

                ; Handle key actions
                if (action.type = "key") {
                    line := Format("{},{},{},{},{}`n"
                        , mName, action.type, action.key, action.duration, action.delay)
                    file.Write(line)
                }

                ; Handle mouse actions
                else if (action.type = "mouse") {
                    line := Format("{},{},{},{},{},{},{}`n"
                        , mName, action.type, action.btn, action.x, action.y, action.duration, action.delay)
                    file.Write(line)
                }

            }
        }

        file.Close()
        AddToLog("✅ Recording export complete.")
    } catch Error {
        AddToLog("❌ Export failed: " Error)
    }
}

ImportRecordings(*) {
    global allRecordings

    ; Ensure allRecordings exists
    if !IsObject(allRecordings)
        allRecordings := Map()

    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    ; Prompt user to select file
    filePath := FileSelect("", A_ScriptDir "\Settings", "Select a recording file to import", "Text Files (*.txt)")

    MainUI.Opt("+AlwaysOnTop")

    if filePath = ""
        return

    if !FileExist(filePath) {
        AddToLog("❌ File does not exist: " filePath)
        return
    }

    try {
        content := FileRead(filePath, "UTF-8")
        lines := StrSplit(content, "`n")
        importedCount := 0
        replacedMaps := Map()  ; track maps replaced in this import

        for line in lines {
            line := Trim(line, "`r`n ")
            if (line = "")
                continue

            parts := StrSplit(line, ",")
            if (parts.Length < 5) {
                AddToLog("⚠ Skipping malformed line: " line)
                continue
            }

            mapName := parts[1]
            type := parts[2]

            ; Initialize map array if first time
            if !replacedMaps.Has(mapName) {
                allRecordings[mapName] := []
                replacedMaps[mapName] := true
                if (!recordingProfiles.Has(mapName))
                    AddRecordingProfile(true, mapName)
            }

            if (type = "key") {
                if (parts.Length < 5) {
                    AddToLog("⚠ Skipping malformed key line: " line)
                    continue
                }
                key := parts[3]
                duration := parts[4]
                delay := parts[5]
                allRecordings[mapName].Push({ type: type, key: key, duration: duration, delay: delay })

            } else if (type = "mouse") {
                if (parts.Length < 7) {
                    AddToLog("⚠ Skipping malformed mouse line: " line)
                    continue
                }
                btn := parts[3]
                x := parts[4]
                y := parts[5]
                duration := parts[6]
                delay := parts[7]
                allRecordings[mapName].Push({ type: type, btn: btn, x: x, y: y, duration: duration, delay: delay })
            } else {
                AddToLog("⚠ Unknown action type: " type)
                continue
            }

            importedCount++
        }

        AddToLog("✅ Imported " importedCount " recording(s)")
        SaveAllRecordings()
    } catch Error {
        AddToLog("❌ Import failed: " Error)
    }
}


HandlePlaybackChecks() {
    global shouldLoop
    if (!shouldLoop) {
        return
    }

    if (isMenuOpen("End Screen") && ShouldHandleGameEnd.Value) {
        AddToLog("Found end screen, stopping playback")
        StopPlayback()
        return MonitorStage()
    }
}

ClearRecordings(*) {
    global allRecordings
    mapName := RecordMapDropdown.Text

    if !allRecordings.Has(mapName) {
        AddToLog("No recording found for map: " mapName)
        return
    }

    AddToLog("Cleared recordings for map: " mapName)
    allRecordings.Delete(mapName)
    SaveAllRecordings()
}

RemoveActiveHotkeys() {
    global activeActionHotkeys

    for hk in activeActionHotkeys {
        try hk.Delete()
    }

    activeActionHotkeys := []
}

GetRecordingMap(mode) {
    switch mode {
        case "Story":
            return StoryDropdown.Text
        case "Raid":
            return RaidDropdown.Text
        case "Portal":
            return PortalDropdown.Text
        case "Event":
            return EventDropdown.Text
        case "Custom":
            return RecordMapDropdown.Text
    }
    return RecordMapDropdown.Text
}