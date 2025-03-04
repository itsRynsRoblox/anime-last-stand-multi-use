#Include %A_ScriptDir%\Lib\GUI.ahk
global settingsFile := "" 


setupFilePath() {
    global settingsFile
    
    if !DirExist(A_ScriptDir "\Settings") {
        DirCreate(A_ScriptDir "\Settings")
    }

    settingsFile := A_ScriptDir "\Settings\Configuration.txt"
    return settingsFile
}

readInSettings() {
    global enabled1, enabled2, enabled3, enabled4, enabled5, enabled6
    global placement1, placement2, placement3, placement4, placement5, placement6
    global priority1, priority2, priority3, priority4, priority5, priority6
    global mode
    global PlacementPatternDropdown, PlaceSpeed, SkipLobby, ReturnLobbyBox
    global savedCoords

    try {
        settingsFile := setupFilePath()
        if !FileExist(settingsFile) {
            return
        }

        content := FileRead(settingsFile)
        lines := StrSplit(content, "`n")
        
        savedCoords := []  ; Ensure it's initialized
        isReadingCoords := false  ; Track if we are in the [SavedCoordinates] section
        
        for line in lines {
            if line = "" {
                continue
            }
        
            parts := StrSplit(line, "=")
        
            ; Check if we're entering the [SavedCoordinates] section
            if (line = "[SavedCoordinates]") {
                isReadingCoords := true
                continue  ; Skip this line
            }
        
            ; If in [SavedCoordinates] section, parse coordinates
            if (isReadingCoords) {
                if (line = "NoCoordinatesSaved") {
                    savedCoords := []  ; Clear the list if no coordinates were saved
                    continue
                }
        
                ; Extract X and Y values from "X=val, Y=val" format
                coordParts := StrSplit(line, ", ")
                x := StrReplace(coordParts[1], "X=")  ; Remove "X="
                y := StrReplace(coordParts[2], "Y=")  ; Remove "Y="
                
                savedCoords.Push({x: x, y: y})  ; Store as an object
                continue
            }
        
            ; Normal setting assignments
            switch parts[1] {
                case "Mode": mode := parts[2]
                case "Enabled1": enabled1.Value := parts[2]
                case "Enabled2": enabled2.Value := parts[2]
                case "Enabled3": enabled3.Value := parts[2]
                case "Enabled4": enabled4.Value := parts[2]
                case "Enabled5": enabled5.Value := parts[2]
                case "Enabled6": enabled6.Value := parts[2]
                case "Placement1": placement1.Text := parts[2]
                case "Placement2": placement2.Text := parts[2]
                case "Placement3": placement3.Text := parts[2]
                case "Placement4": placement4.Text := parts[2]
                case "Placement5": placement5.Text := parts[2]
                case "Placement6": placement6.Text := parts[2]
                case "Priority1": priority1.Text := parts[2]
                case "Priority2": priority2.Text := parts[2]
                case "Priority3": priority3.Text := parts[2]
                case "Priority4": priority4.Text := parts[2]
                case "Priority5": priority5.Text := parts[2]
                case "Priority6": priority6.Text := parts[2]
                case "Speed": PlaceSpeed.Value := parts[2]  ; Set dropdown value
                case "Logic": PlacementPatternDropdown.Value := parts[2]  ; Set dropdown value
                case "Skipping": SkipLobby.Value := parts[2]  ; Set checkbox value
                case "Lobby": ReturnLobbyBox.Value := parts[2]  ; Set checkbox value
            }
        }
        
        AddToLog("✅ Settings loaded successfully. " savedCoords.Length " placement(s) successfully restored!")
    } 
}


SaveSettings(*) {
    global enabled1, enabled2, enabled3, enabled4, enabled5, enabled6
    global placement1, placement2, placement3, placement4, placement5, placement6
    global priority1, priority2, priority3, priority4, priority5, priority6
    global mode
    global PlacementPatternDropdown, PlaceSpeed, SkipLobby, ReturnLobbyBox
    global savedCoords

    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.txt"
        if FileExist(settingsFile) {
            FileDelete(settingsFile)
        }

        ; Save mode and map selection
        content := "Mode=" mode "`n"
        if (mode = "Story") {
            content .= "Map=" StoryDropdown.Text
        } else if (mode = "Raid") {
            content .= "Map=" RaidDropdown.Text
        }
        
        ; Save settings for each unit
        content .= "`n`nEnabled1=" enabled1.Value
        content .= "`nEnabled2=" enabled2.Value
        content .= "`nEnabled3=" enabled3.Value
        content .= "`nEnabled4=" enabled4.Value
        content .= "`nEnabled5=" enabled5.Value
        content .= "`nEnabled6=" enabled6.Value

        content .= "`n`nPlacement1=" placement1.Text
        content .= "`nPlacement2=" placement2.Text
        content .= "`nPlacement3=" placement3.Text
        content .= "`nPlacement4=" placement4.Text
        content .= "`nPlacement5=" placement5.Text
        content .= "`nPlacement6=" placement6.Text

        content .= "`nPriority1=" priority1.Text
        content .= "`nPriority2=" priority2.Text
        content .= "`nPriority3=" priority3.Text
        content .= "`nPriority4=" priority4.Text
        content .= "`nPriority5=" priority5.Text
        content .= "`nPriority6=" priority6.Text

        content .= "`n[PlacementLogic]"
        content .= "`nLogic=" PlacementPatternDropdown.Value "`n"

        content .= "`n[PlaceSpeed]"
        content .= "`nSpeed=" PlaceSpeed.Value "`n"

        content .= "`n[SkipLobby]"
        content .= "`nSkipping=" SkipLobby.Value "`n"

        content .= "`n[ReturnToLobby]"
        content .= "`nLobby=" ReturnLobbyBox.Value "`n"

        ; Save the stored coordinates
        content .= "`n[SavedCoordinates]`n"
        if (IsSet(savedCoords) && savedCoords.Length > 0) {
            for coord in savedCoords {
                content .= Format("X={1}, Y={2}`n", coord.x, coord.y)
            }
        } else {
            content .= "NoCoordinatesSaved`n"
        }

        FileAppend(content, settingsFile)
        AddToLog("✅ Configuration settings and custom placements saved successfully!")
    }
}

LoadSettings() {
    global UnitData, mode
    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.txt"
        if !FileExist(settingsFile) {
            return
        }

        content := FileRead(settingsFile)
        sections := StrSplit(content, "`n`n")
        
        for section in sections {
            if (InStr(section, "PlacementLogic")) {
                if RegExMatch(line, "Logic=(\w+)", &match) {
                    PlacementPatternDropdown.Value := match.1 ; Set the dropdown value
                }
            }
            else if (InStr(section, "PlaceSpeed")) {
                if RegExMatch(line, "Speed=(\w+)", &match) {
                    PlaceSpeed.Value := match.1 ; Set the dropdown value
                }
            }
            else if (InStr(section, "SkipLobby")) {
                if RegExMatch(line, "Skipping=(\w+)", &match) {
                    SkipLobby.Value := match.1 ; Set the dropdown value
                }
            }
            else if (InStr(section, "ReturnToLobby")) {
                if RegExMatch(line, "Return=(\w+)", &match) {
                    ReturnLobbyBox.Value := match.1 ; Set the dropdown value
                }
            }
            else if (InStr(section, "Index=")) {
                lines := StrSplit(section, "`n")
                
                for line in lines {
                    if line = "" {
                        continue
                    }
                    
                    parts := StrSplit(line, "=")
                    if (parts[1] = "Index") {
                        index := parts[2]
                    } else if (index && UnitData.Has(Integer(index))) {
                        switch parts[1] {
                            case "Enabled": UnitData[index].Enabled.Value := parts[2]
                            case "Placement": UnitData[index].PlacementBox.Value := parts[2]
                        }
                    }
                }
            }
        }
        AddToLog("Auto settings loaded successfully")
    }
}

SaveKeybindSettings(*) {
    AddToLog("Saving Keybind Configuration")
    
    if FileExist("Settings\Keybinds.txt")
        FileDelete("Settings\Keybinds.txt")
        
    FileAppend(Format("F1={}`nF2={}`nF3={}`nF4={}", F1Box.Value, F2Box.Value, F3Box.Value, F4Box.Value), "Settings\Keybinds.txt", "UTF-8")
    
    ; Update globals
    global F1Key := F1Box.Value
    global F2Key := F2Box.Value
    global F3Key := F3Box.Value
    global F4Key := F4Box.Value
    
    ; Update hotkeys
    Hotkey(F1Key, (*) => moveRobloxWindow())
    Hotkey(F2Key, (*) => StartMacro())
    Hotkey(F3Key, (*) => Reload())
    Hotkey(F4Key, (*) => TogglePause())
}

LoadKeybindSettings() {
    if FileExist("Settings\Keybinds.txt") {
        AddToLog("Loaded Keybinds")
        fileContent := FileRead("Settings\Keybinds.txt", "UTF-8")
        Loop Parse, fileContent, "`n" {
            parts := StrSplit(A_LoopField, "=")
            if (parts[1] = "F1")
                global F1Key := parts[2]
            else if (parts[1] = "F2")
                global F2Key := parts[2]
            else if (parts[1] = "F3")
                global F3Key := parts[2]
            else if (parts[1] = "F4")
                global F4Key := parts[2]
        }
    }
}