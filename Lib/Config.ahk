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
        currentPreset := 0  ; Track the current preset
        
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
                ; Check for a new preset start line (e.g., [Preset 1], [Preset 2], etc.)
                if (RegExMatch(line, "^\[Preset (\d+)\]$")) {
                    currentPreset := RegExReplace(line, "^\[Preset (\d+)\]$", "$1")  ; Extract preset number
                    currentPreset := currentPreset + 0  ; Convert to integer
        
                    ; Ensure the correct index exists for the preset in savedCoords
                    while (savedCoords.Length < currentPreset) {
                        savedCoords.Push([])  ; Add empty list for new preset if needed
                    }
        
                    continue
                }
        
                ; If we encounter "NoCoordinatesSaved", reset the current preset's coordinates
                if (line = "NoCoordinatesSaved") {
                    savedCoords[currentPreset] := []  ; Clear coordinates for the current preset
                    continue
                }
        
                ; Extract X and Y values from "X=val, Y=val" format
                coordParts := StrSplit(line, ", ")
                x := StrReplace(coordParts[1], "X=")  ; Remove "X="
                y := StrReplace(coordParts[2], "Y=")  ; Remove "Y="
        
                ; Store the coordinates for the current preset
                savedCoords[currentPreset].Push({x: x, y: y})  ; Push to the correct preset index
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
                case "UpgradeEnabled1": upgradeEnabled1.Value := parts[2]
                case "UpgradeEnabled2": upgradeEnabled2.Value := parts[2]
                case "UpgradeEnabled3": upgradeEnabled3.Value := parts[2]
                case "UpgradeEnabled4": upgradeEnabled4.Value := parts[2]
                case "UpgradeEnabled5": upgradeEnabled5.Value := parts[2]
                case "UpgradeEnabled6": upgradeEnabled6.Value := parts[2]
                case "UpgradeLimitEnabled1": upgradeLimitEnabled1.Value := parts[2]
                case "UpgradeLimitEnabled2": upgradeLimitEnabled2.Value := parts[2]
                case "UpgradeLimitEnabled3": upgradeLimitEnabled3.Value := parts[2]
                case "UpgradeLimitEnabled4": upgradeLimitEnabled4.Value := parts[2]
                case "UpgradeLimitEnabled5": upgradeLimitEnabled5.Value := parts[2]
                case "UpgradeLimitEnabled6": upgradeLimitEnabled6.Value := parts[2]
                case "UpgradeLimit1": UpgradeLimit1.Text := parts[2]
                case "UpgradeLimit2": UpgradeLimit2.Text := parts[2]
                case "UpgradeLimit3": UpgradeLimit3.Text := parts[2]
                case "UpgradeLimit4": UpgradeLimit4.Text := parts[2]
                case "UpgradeLimit5": UpgradeLimit5.Text := parts[2]
                case "UpgradeLimit6": UpgradeLimit6.Text := parts[2]
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
                case "Pattern": PlacementPatternDropdown.Value := parts[2]  ; Set dropdown value
                case "Setting": PlacementSelection.Value := parts[2]  ; Set dropdown value
                case "Profile": PlacementProfiles.Value := parts[2]  ; Set dropdown value
                case "PriorityUpgrade": PriorityUpgrade.Value := parts[2] ; Set the checkbox value
                case "Skipping": SkipLobby.Value := parts[2]  ; Set checkbox value
                case "Lobby": ReturnLobbyBox.Value := parts[2]  ; Set checkbox value
                case "AutoAbility": AutoAbilityBox.Value := parts[2] ; Set the checkbox value
                case "isSeamless": SeamlessToggle.Value := parts[2] ; Set the checkbox value
                case "WebhookEnabled": WebhookEnabled.Value := parts[2] ; Set the checkbox value
                case "WebhookURL": WebhookURLBox.Text := parts[2] ; Set the URL box text
                case "WebhookLogsEnabled": WebhookLogsEnabled.Value := parts[2] ; Set the checkbox value
                case "PrivateServerEnabled": PrivateServerEnabled.Value := parts[2] ; Set the checkbox value
                case "PrivateServerURL": PrivateServerURLBox.Text := parts[2] ; Set the URL box text
                case "UnitManagerLeft": LeftSideUnitManager.Value := parts[2] ; Set the checkbox value
                case "ZoomLevel": ZoomBox.Text := parts[2] ; Set the zoom level
                case "UnitManagerAutoUpgrade": UnitManagerAutoUpgrade.Value := parts[2]
                case "UnitManagerUpgradeSystem": UnitManagerUpgradeSystem.Value := parts[2]
                case "AutoAbilityTimer": AutoAbilityTimer.Text := parts[2] ; Set the zoom level
            }
        }
        AddToLog("✅ Loaded settings successfully")
        InitControlGroups()
    } 
}


SaveSettings(*) {
    global savedCoords

    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.txt"
        if FileExist(settingsFile) {
            FileDelete(settingsFile)
        }

        content .= "`n[Unit Settings]"

        for settingType in ["Enabled", "Placement", "Priority", "UpgradeEnabled", "UpgradeLimitEnabled"] {
            loop 6 {
                index := A_Index
                setting := %settingType%%index%
                content .= "`n" settingType index "=" setting.Value
            }
        }

        content .= "`n`n[PlacementSettings]"
        content .= "`nSetting=" PlacementSelection.Value
        content .= "`nPattern=" PlacementPatternDropdown.Value
        content .= "`nSpeed=" PlaceSpeed.Value
        content .= "`nProfile=" PlacementProfiles.Value

        content .= "`n`n[General Settings]"
        content .= "`nSkipping=" SkipLobby.Value
        content .= "`nLobby=" ReturnLobbyBox.Value
        content .= "`nisSeamless=" SeamlessToggle.Value
        content .= "`nPriorityUpgrade=" PriorityUpgrade.Value
        content .= "`nAutoAbility=" AutoAbilityBox.Value

        content .= "`n`n[WebhookSettings]"
        content .= "`nWebhookEnabled=" WebhookEnabled.Value
        content .= "`nWebhookURL=" WebhookURLBox.Text
        content .= "`nWebhookLogsEnabled=" WebhookLogsEnabled.Value

        content .= "`n`n[PrivateServerSettings]"
        content .= "`nPrivateServerEnabled=" PrivateServerEnabled.Value
        content .= "`nPrivateServerURL=" PrivateServerURLBox.Text

        content .= "`n`n[MiscSettings]"
        content .= "`nUnitManagerLeft=" LeftSideUnitManager.Value

        content .= "`n`n[ZoomSettings]"
        content .= "`nZoomLevel=" ZoomBox.Value

        content .= "`n`n[Upgrade Settings]"
        content .= "`nUnitManagerAutoUpgrade=" UnitManagerAutoUpgrade.Value
        content .= "`nUnitManagerUpgradeSystem=" UnitManagerUpgradeSystem.Value
        content .= "`nAutoAbilityTimer=" AutoAbilityTimer.Text

        ; Save the stored coordinates
        content .= "`n`n[SavedCoordinates]`n"

        ; Iterate through each preset in savedCoords
        for presetIndex, _ in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] {
            content .= Format("[Preset {1}]`n", presetIndex)  ; Add preset header

            if (IsSet(savedCoords) && savedCoords.Length >= presetIndex && savedCoords[presetIndex].Length > 0) {
                for coord in savedCoords[presetIndex] {
                    content .= Format("X={1}, Y={2}`n", coord.x, coord.y)
                }
            } else {
                content .= "NoCoordinatesSaved`n"
            }
        }

        FileAppend(content, settingsFile)
        AddToLog("✅ Saved settings successfully")
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