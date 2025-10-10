#Include %A_ScriptDir%\Lib\GUI.ahk

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

SaveSettingsForMode(*) {

    try {
        ; Create the Settings directory if it doesn't exist
        settingsDir := A_ScriptDir "\Settings\Modes"
        if !DirExist(settingsDir)
            DirCreate(settingsDir)

        ; Use ModeDropdown.Text to determine the filename

        if (!ModeConfigurations.Value) {
            gameMode := "Default"
        } else {
            gameMode := ModeDropdown.Text
        }

        if !gameMode {
            gameMode := "Default"
        }

        ; Sanitize the game mode name to avoid illegal filename characters
        safeMode := RegExReplace(gameMode, '[\\/:*?"<>|]', "_")
        settingsFile := settingsDir "\" safeMode "_Configuration.txt"

        ; Delete the existing file for this mode (optional)
        if FileExist(settingsFile)
            FileDelete(settingsFile)

        ; Start building the content
        content := "[Unit Settings]"

        for settingType in ["Enabled", "Placement", "Priority", "UpgradePriority", "UpgradeEnabled", "UpgradeLimit", "UpgradeLimitEnabled"] {
            loop 6 {
                index := A_Index
                setting := %settingType%%index%
                value := (settingType = "UpgradeLimit" || settingType = "UpgradePriority") ? setting.Text : setting.Value
                content .= "`n" settingType index "=" value
            }
        }

        content .= "`n`n[Auto Ability Settings]"
        content .= "`nAutoAbility=" AutoAbilityBox.Value
        content .= "`nAutoAbilityTimer=" AutoAbilityTimer.Text

        content .= "`n`n[Zoom Settings]"
        content .= "`nZoomLevel=" ZoomBox.Value

        content .= "`n`n[Upgrade Settings]"
        content .= "`nUnit Manager Auto Upgrade=" UnitManagerAutoUpgrade.Value
        content .= "`nUnit Manager Upgrade System=" UnitManagerUpgradeSystem.Value
        content .= "`nPriority Upgrade=" PriorityUpgrade.Value

        content .= "`n`n[Portal Settings]"
        content .= "`nStart Portal In Lobby=" PortalLobby.Value

        content .= "`n`n[Unit Settings]"
        content .= "`nUse Sunwoo Nuke=" SJWNuke.Value
        content .= "`nSunwoo Nuke Slot=" SJWSlot.Value
        content .= "`nNuke Enabled=" NukeUnitSlotEnabled.Value
        content .= "`nNuke Slot=" NukeUnitSlot.Value
        content .= "`nNuke Coords=" nukeCoords.x "," nukeCoords.y
        content .= "`nSlot 1 Minion=" MinionSlot1.Value
        content .= "`nSlot 2 Minion=" MinionSlot2.Value
        content .= "`nSlot 3 Minion=" MinionSlot3.Value
        content .= "`nSlot 4 Minion=" MinionSlot4.Value
        content .= "`nSlot 5 Minion=" MinionSlot5.Value
        content .= "`nSlot 6 Minion=" MinionSlot6.Value

        FileAppend(content, settingsFile)
        SaveCustomPlacements()
        SaveCustomWalk()
        SaveUniversalSettings()
        AddToLog("✅ Saved settings for mode: " gameMode)
        SaveCardLocal()
    }
}

LoadUnitSettingsByMode() {
    global nukeCoords
    local mode := ModeDropdown.Text

    if !mode {
        mode := "Default"
    }

    ; Step 2: Sanitize mode and get mode-specific config file path
    safeMode := RegExReplace(mode, '[\\/:*?"<>|]', "_")
    settingsFile := A_ScriptDir "\Settings\Modes\" safeMode "_Configuration.txt"

    if !FileExist(settingsFile) {
        AddToLog("⚠️ No configuration found for mode: " mode)
        return
    }

    ; Step 3: Read and parse the mode-specific config file
    content := FileRead(settingsFile)
    lines := StrSplit(content, "`n")

    for line in lines {
        line := Trim(line)
        if line = "" || InStr(line, "[")
            continue

        parts := StrSplit(line, "=")

        key := parts[1], value := parts[2]

        switch key {
            case "Enabled1": enabled1.Value := value
            case "Enabled2": enabled2.Value := value
            case "Enabled3": enabled3.Value := value
            case "Enabled4": enabled4.Value := value
            case "Enabled5": enabled5.Value := value
            case "Enabled6": enabled6.Value := value

            case "UpgradeEnabled1": upgradeEnabled1.Value := value
            case "UpgradeEnabled2": upgradeEnabled2.Value := value
            case "UpgradeEnabled3": upgradeEnabled3.Value := value
            case "UpgradeEnabled4": upgradeEnabled4.Value := value
            case "UpgradeEnabled5": upgradeEnabled5.Value := value
            case "UpgradeEnabled6": upgradeEnabled6.Value := value

            case "UpgradeLimitEnabled1": upgradeLimitEnabled1.Value := value
            case "UpgradeLimitEnabled2": upgradeLimitEnabled2.Value := value
            case "UpgradeLimitEnabled3": upgradeLimitEnabled3.Value := value
            case "UpgradeLimitEnabled4": upgradeLimitEnabled4.Value := value
            case "UpgradeLimitEnabled5": upgradeLimitEnabled5.Value := value
            case "UpgradeLimitEnabled6": upgradeLimitEnabled6.Value := value

            case "UpgradeLimit1": UpgradeLimit1.Text := value
            case "UpgradeLimit2": UpgradeLimit2.Text := value
            case "UpgradeLimit3": UpgradeLimit3.Text := value
            case "UpgradeLimit4": UpgradeLimit4.Text := value
            case "UpgradeLimit5": UpgradeLimit5.Text := value
            case "UpgradeLimit6": UpgradeLimit6.Text := value

            case "Placement1": placement1.Text := value
            case "Placement2": placement2.Text := value
            case "Placement3": placement3.Text := value
            case "Placement4": placement4.Text := value
            case "Placement5": placement5.Text := value
            case "Placement6": placement6.Text := value

            case "Priority1": priority1.Text := value
            case "Priority2": priority2.Text := value
            case "Priority3": priority3.Text := value
            case "Priority4": priority4.Text := value
            case "Priority5": priority5.Text := value
            case "Priority6": priority6.Text := value

            case "UpgradePriority1": UpgradePriority1.Text := value
            case "UpgradePriority2": UpgradePriority2.Text := value
            case "UpgradePriority3": UpgradePriority3.Text := value
            case "UpgradePriority4": UpgradePriority4.Text := value
            case "UpgradePriority5": UpgradePriority5.Text := value
            case "UpgradePriority6": UpgradePriority6.Text := value

            case "AutoAbility": AutoAbilityBox.Value := value
            case "AutoAbilityTimer": AutoAbilityTimer.Text := value

            case "ZoomLevel": ZoomBox.Text := value
            case "Unit Manager Auto Upgrade": UnitManagerAutoUpgrade.Value := value
            case "Unit Manager Upgrade System": UnitManagerUpgradeSystem.Value := value
            case "Priority Upgrade": PriorityUpgrade.Value := value
            case "Start Portal In Lobby": PortalLobby.Value := value

            case "Use Sunwoo Nuke": SJWNuke.Value := value
            case "Sunwoo Nuke Slot": SJWSlot.Value := value

            case "Nuke Enabled": NukeUnitSlotEnabled.Value := value
            case "Nuke Slot": NukeUnitSlot.Value := value
            case "Nuke Coords":
            {
                coords := StrSplit(value, ",")
                if coords.Length >= 2 {
                    nukeCoords := {x: coords[1], y: coords[2]}
                }
            }

            case "Slot 1 Minion": MinionSlot1.Value := value
            case "Slot 2 Minion": MinionSlot2.Value := value
            case "Slot 3 Minion": MinionSlot3.Value := value
            case "Slot 4 Minion": MinionSlot4.Value := value
            case "Slot 5 Minion": MinionSlot5.Value := value
            case "Slot 6 Minion": MinionSlot6.Value := value

        }
    }
    LoadCustomPlacements()
    InitControlGroups()
    AddToLog("✅ Settings successfully loaded for mode: " mode)
    LoadUniversalSettings()
    LoadCustomWalk()
    LoadCardLocal()
}


SaveCustomPlacements() {
    global savedCoords

    ; Ensure Settings folder exists
    settingsDir := A_ScriptDir "\Settings"
    if !DirExist(settingsDir)
        DirCreate(settingsDir)

    placementFile := settingsDir "\CustomPlacements.txt"

    ; Optionally delete the old file first
    if FileExist(placementFile)
        FileDelete(placementFile)

    placementData := "[SavedCoordinates]`n"

    for presetIndex, _ in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] {
        placementData .= Format("[Preset {1}]`n", presetIndex)

        if (IsSet(savedCoords) && savedCoords.Length >= presetIndex && savedCoords[presetIndex].Length > 0) {
            for coord in savedCoords[presetIndex] {
                placementData .= Format("X={1}, Y={2}`n", coord.x, coord.y)
            }
        } else {
            placementData .= "NoCoordinatesSaved`n"
        }
    }
    FileAppend(placementData, placementFile)
}

LoadCustomPlacements() {
    global savedCoords

    savedCoords := []  ; Reinitialize
    placementFile := A_ScriptDir "\Settings\CustomPlacements.txt"

    ; Create the file with a default header if it doesn't exist
    if !FileExist(placementFile) {
        ; Ensure the directory exists
        if !DirExist(A_ScriptDir "\Settings")
            DirCreate(A_ScriptDir "\Settings")
        SaveCustomPlacements()
    }

    content := FileRead(placementFile)
    lines := StrSplit(content, "`n")

    currentPreset := 0

    for line in lines {
        line := Trim(line)
        if (line = "" || line = "[SavedCoordinates]")
            continue

        ; Detect preset header
        if RegExMatch(line, "^\[Preset (\d+)\]$", &match) {
            currentPreset := match[1] + 0

            ; Ensure array size
            while (savedCoords.Length < currentPreset)
                savedCoords.Push([])

            continue
        }

        if (line = "NoCoordinatesSaved") {
            savedCoords[currentPreset] := []
            continue
        }

        ; Parse "X=..., Y=..." format
        coordParts := StrSplit(line, ", ")
        x := StrReplace(coordParts[1], "X=")
        y := StrReplace(coordParts[2], "Y=")

        savedCoords[currentPreset].Push({ x: x, y: y })
    }
}

LoadUniversalSettings() {
    universalFile := A_ScriptDir "\Settings\Modes\Universal_Configuration.txt"
    if !FileExist(universalFile) {
        AddToLog("⚠️ No universal settings found.")
        return
    }

    content := FileRead(universalFile)
    lines := StrSplit(content, "`n")

    for line in lines {
        line := Trim(line)
        if line = "" || InStr(line, "[")
            continue

        parts := StrSplit(line, "=")

        key := parts[1], value := parts[2]

        switch key {
            case "Return To Lobby": ReturnLobbyBox.Value := value
            case "Next Level": NextLevelBox.Value := value
            case "Seamless Replay": SeamlessToggle.Value := value
            case "Using Mode Configurations": ModeConfigurations.Value := value
            case "Webhook Enabled": WebhookEnabled.Value := value
            case "Webhook URL": WebhookURLBox.Text := value
            case "Webhook Logs Enabled": WebhookLogsEnabled.Value := value
            case "Private Server Enabled": PrivateServerEnabled.Value := value
            case "Private Server URL": PrivateServerURLBox.Text := value
            case "Nightmare Difficulty": NightmareDifficulty.Value := value
            case "Placement Pattern": PlacementPatternDropdown.Value := value
            case "Placement Order": PlacementSelection.Value := value
            case "Placement Profile": PlacementProfiles.Value := value
            case "Placement Speed": PlaceSpeed.Value := value
        }
    }
}


SaveUniversalSettings() {
    try {
        universalFile := A_ScriptDir "\Settings\Modes\Universal_Configuration.txt"
        if FileExist(universalFile)
            FileDelete(universalFile)

        content .= "[Universal Settings]"
        content .= "`nNext Level=" NextLevelBox.Value
        content .= "`nReturn To Lobby=" ReturnLobbyBox.Value
        content .= "`nSeamless Replay=" SeamlessToggle.Value
        content .= "`nUsing Mode Configurations=" ModeConfigurations.Value

        content .= "`n`n[Webhook Settings]"
        content .= "`nWebhook Enabled=" WebhookEnabled.Value
        content .= "`nWebhook URL=" WebhookURLBox.Text
        content .= "`nWebhook Logs Enabled=" WebhookLogsEnabled.Value

        content .= "`n`n[Private Server Settings]"
        content .= "`nPrivate Server Enabled=" PrivateServerEnabled.Value
        content .= "`nPrivate Server URL=" PrivateServerURLBox.Text

        content .= "`n`n[Story Settings]"
        content .= "`nNightmare Difficulty=" NightmareDifficulty.Value

        content .= "`n`n[Placement Settings]"
        content .= "`nPlacement Pattern=" PlacementPatternDropdown.Value
        content .= "`nPlacement Order=" PlacementSelection.Value
        content .= "`nPlacement Profile=" PlacementProfiles.Value
        content .= "`nPlacement Speed=" PlaceSpeed.Value

        FileAppend(content, universalFile)
    }
}

SaveCustomWalk() {
    global savedWalkCoords

    ; Ensure Settings folder exists
    settingsDir := A_ScriptDir "\Settings"
    if !DirExist(settingsDir)
        DirCreate(settingsDir)

    placementFile := settingsDir "\CustomWalk.txt"

    ; Optionally delete the old file first
    if FileExist(placementFile)
        FileDelete(placementFile)

    placementData := "[SavedWalkCoordinates]`n"

    for presetIndex, _ in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] {
        placementData .= Format("[Preset {1}]`n", presetIndex)

        if (IsSet(savedWalkCoords) && savedWalkCoords.Length >= presetIndex && savedWalkCoords[presetIndex].Length > 0) {
            for coord in savedWalkCoords[presetIndex] {
                placementData .= Format("X={1}, Y={2}, Delay={3}`n", coord.x, coord.y, coord.delay)
            }
        } else {
            placementData .= "NoCoordinatesSaved`n"
        }
    }
    FileAppend(placementData, placementFile)
}

LoadCustomWalk() {
    global savedWalkCoords

    savedWalkCoords := []  ; Reinitialize
    placementFile := A_ScriptDir "\Settings\CustomWalk.txt"

    ; Create the file with a default header if it doesn't exist
    if !FileExist(placementFile) {
        ; Ensure the directory exists
        if !DirExist(A_ScriptDir "\Settings")
            DirCreate(A_ScriptDir "\Settings")
        SaveCustomWalk()
    }

    content := FileRead(placementFile)
    lines := StrSplit(content, "`n")

    currentPreset := 0

    for line in lines {
        line := Trim(line)
        if (line = "" || line = "[SavedWalkCoordinates]")
            continue

        ; Detect preset header
        if RegExMatch(line, "^\[Preset (\d+)\]$", &match) {
            currentPreset := match[1] + 0

            ; Ensure array size
            while (savedWalkCoords.Length < currentPreset)
                savedWalkCoords.Push([])

            continue
        }

        if (line = "NoCoordinatesSaved") {
            savedWalkCoords[currentPreset] := []
            continue
        }

        ; Parse "X=..., Y=..." format
        coordParts := StrSplit(line, ", ")
        x := StrReplace(coordParts[1], "X=")
        y := StrReplace(coordParts[2], "Y=")
        delay := StrReplace(coordParts[3], "Delay=")
        savedWalkCoords[currentPreset].Push({ x: x, y: y, delay: delay })
    }
}