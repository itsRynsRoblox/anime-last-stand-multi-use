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
        settingsFile := settingsDir "\" gameMode "_Configuration.txt"

        ; Delete the existing file for this mode (optional)
        if FileExist(settingsFile)
            FileDelete(settingsFile)

        ; Start building the content
        content := "[Unit Settings]"

        for settingType in ["Enabled", "Placement", "Priority", "UpgradePriority", "UpgradeEnabled", "AbilityEnabled", "UpgradeLimit", "UpgradeLimitEnabled"] {
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
        content .= "`nUse Zoom Tech=" ZoomTech.Value
        content .= "`nZoom In Then Out=" ZoomInOption.Value
        content .= "`nTeleport To Spawn=" ZoomTeleport.Value

        content .= "`n`n[Upgrade Settings]"
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
        content .= "`nNuke At Specific Wave=" NukeAtSpecificWave.Value
        content .= "`nNuke Wave=" NukeWave.Value
        content .= "`nNuke Delay=" NukeDelay.Value
        content .= "`nSlot 1 Minion=" MinionSlot1.Value
        content .= "`nSlot 2 Minion=" MinionSlot2.Value
        content .= "`nSlot 3 Minion=" MinionSlot3.Value
        content .= "`nSlot 4 Minion=" MinionSlot4.Value
        content .= "`nSlot 5 Minion=" MinionSlot5.Value
        content .= "`nSlot 6 Minion=" MinionSlot6.Value

        content .= "`n`n[Halloween Settings]"
        content .= "`nHalloween Restart Enabled=" HalloweenRestart.Value
        content .= "`nHalloween Restart Timer=" HalloweenRestartTimer.Value

        content .= "`n`n[Failsafe Settings]"
        content .= "`nTeleport Failsafe Enabled=" TeleportFailsafe.Value
        content .= "`nTeleport Failsafe Timer=" TeleportFailsafeTimer.Value

        FileAppend(content, settingsFile)
        SaveCustomPlacements()
        SaveAllMovements()
        SaveUniversalSettings()
        AddToLog("✅ Saved settings for mode: " gameMode)
        SaveAllConfigs()
    }
}

LoadUnitSettingsByMode() {
    global UnitConfigMap, nukeCoords

    InitSettings()

    local mode := ModeDropdown.Text
    if !mode
        mode := "Default"

    ; Sanitize mode for filename safety
    safeMode := RegExReplace(mode, '[\\/:*?"<>|]', "_")
    settingsFile := A_ScriptDir "\Settings\Modes\" safeMode "_Configuration.txt"

    if !FileExist(settingsFile) {
        AddToLog("⚠️ No configuration found for mode: " mode)
        SaveSettingsForMode()  ; Save default settings if missing
        return
    }

    content := FileRead(settingsFile)
    lines := StrSplit(content, "`n")

    for line in lines {
        line := Trim(line)
        if line = "" || InStr(line, "[")
            continue

        parts := StrSplit(line, "=")
        if (parts.Length < 2)
            continue

        key := Trim(parts[1])
        value := Trim(parts[2])

        if UnitConfigMap.Has(key) {
            ctrl := UnitConfigMap[key].control
            prop := UnitConfigMap[key].prop
            try ctrl.%prop% := value
        } else if (key = "Nuke Coords") {
            coords := StrSplit(value, ",")
            if coords.Length >= 2
                nukeCoords := { x: coords[1], y: coords[2] }
        }
    }

    LoadCustomPlacements()
    InitControlGroups()
    LoadUniversalSettings()
    LoadAllMovements()
    LoadAllCardConfig()

    AddToLog("✅ Settings successfully loaded for mode: " mode)
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
        key := parts[1]
        value := ""

        if (key = "Private Server URL") {
            ; Join everything after the first '=' back together for the URL
            for index, part in parts {
                if (index > 1)
                    value .= (value = "" ? "" : "=") . part
            }
        } else {
            ; For other keys, take only the part after first '='
            value := parts[2]
        }

        switch key {
            case "Return To Lobby": ReturnLobbyBox.Value := value
            case "Next Level": NextLevelBox.Value := value
            case "Seamless Replay": SeamlessToggle.Value := value
            case "Using Mode Configurations": ModeConfigurations.Value := value
            case "Webhook Enabled": WebhookEnabled.Value := value
            case "Webhook URL": WebhookURLBox.Text := value
            case "Webhook Logs Enabled": WebhookLogsEnabled.Value := value
            case "Private Server Enabled": PrivateServerEnabled.Value := value
            case "Private Server URL": PrivateServerURLBox.Value := value
            case "Nightmare Difficulty": NightmareDifficulty.Value := value
            case "Placement Pattern": PlacementPatternDropdown.Value := value
            case "Placement Order": PlacementSelection.Value := value
            case "Placement Speed": PlaceSpeed.Value := value
            case "Check For Updates": UpdateChecker.Value := value
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
        content .= "`nPrivate Server URL=" PrivateServerURLBox.Value

        content .= "`n`n[Story Settings]"
        content .= "`nNightmare Difficulty=" NightmareDifficulty.Value

        content .= "`n`n[Placement Settings]"
        content .= "`nPlacement Pattern=" PlacementPatternDropdown.Value
        content .= "`nPlacement Order=" PlacementSelection.Value
        content .= "`nPlacement Speed=" PlaceSpeed.Value

        content .= "`n`n[Update Settings]"
        content .= "`nCheck For Updates=" UpdateChecker.Value

        FileAppend(content, universalFile)
    }
}

ImportSettingsFromFile() {
    global MainUI, UnitConfigMap, nukeCoords

    ; Temporarily disable AlwaysOnTop for file dialog
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    file := FileSelect(3, , "Select a configuration file to import", "Text Documents (*.txt)")
    MainUI.Opt("+AlwaysOnTop")

    if !file
        return

    content := FileRead(file)
    lines := StrSplit(content, "`n")

    for line in lines {
        line := Trim(line)
        if (line = "" || InStr(line, "["))
            continue

        parts := StrSplit(line, "=")
        if parts.Length < 2
            continue

        key := Trim(parts[1])
        value := Trim(parts[2])

        if UnitConfigMap.Has(key) {
            ctrl := UnitConfigMap[key].control
            prop := UnitConfigMap[key].prop
            try ctrl.%prop% := value
        } else if (key = "Nuke Coords") {
            coords := StrSplit(value, ",")
            if coords.Length >= 2
                nukeCoords := { x: coords[1], y: coords[2] }
        }
    }

    ; Finalize
    AddToLog("📥 Imported settings from external file!")
}

ExportCoordinatesPreset(presetIndex) {
    global savedCoords

    if !IsSet(savedCoords) || savedCoords.Length < presetIndex || savedCoords[presetIndex].Length = 0 {
        AddToLog("⚠️ No coordinates saved for Preset " presetIndex)
        return
    }

    ; Ensure export directory
    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    file := exportDir "\Preset" presetIndex ".txt"

    exportData := Format("[Preset {1}]`n", presetIndex)
    for coord in savedCoords[presetIndex] {
        exportData .= Format("X={1}, Y={2}`n", coord.x, coord.y)
    }

    try {
        if FileExist(file)
            FileDelete(file)
        FileAppend(exportData, file)
    } catch {
        AddToLog "❌ Failed to save preset"
        return
    }

    AddToLog("✅ Preset " presetIndex " exported to: Settings\Export\Preset" presetIndex ".txt")
}

ImportCoordinatesPreset1() {
    global savedCoords, MainUI

    ; Allow file dialog to appear
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    file := FileSelect(3, , "Import a custom placement preset", "Text Documents (*.txt)")

    if !file
        return

    content := FileRead(file)
    lines := StrSplit(content, "`n")

    newPresetCoords := []

    for line in lines {
        line := Trim(line)
        if (line = "" || InStr(line, "[Preset"))
            continue

        if (line = "NoCoordinatesSaved") {
            break
        }

        coordParts := StrSplit(line, ", ")
        if coordParts.Length < 2
            continue

        x := StrReplace(coordParts[1], "X=")
        y := StrReplace(coordParts[2], "Y=")
        newPresetCoords.Push({ x: x + 0, y: y + 0 })  ; Convert to numbers
    }

    if newPresetCoords.Length = 0 {
        MsgBox "❌ No coordinates found in file."
        return
    }

    ; Prompt user for target slot using AHK v2 InputBox
    result := InputBox("Enter preset slot (1–10) to import into:", "Import Custom Placements", "h95 w250")

    MainUI.Opt("+AlwaysOnTop")

    if result.Result = "Cancel" {
        AddToLog("❌ Import canceled.")
        return
    }

    targetSlot := Trim(result.Value)

    if !RegExMatch(targetSlot, "^\d+$") || targetSlot < 1 || targetSlot > 10 {
        MsgBox "❌ Invalid input. Please enter a number between 1 and 10."
        return
    }

    targetSlot := targetSlot + 0

    ; Ensure array is large enough
    while (savedCoords.Length < targetSlot)
        savedCoords.Push([])

    savedCoords[targetSlot] := newPresetCoords

    AddToLog("✅ Imported preset into slot " targetSlot "!")
}

ExportUnitConfig() {
    global UnitConfigMap, nukeCoords

    ; Set export directory and default file name
    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    file := exportDir "\Exported_Unit_Config.txt"
    configData := ""

    ; Export all mapped settings
    for key, obj in UnitConfigMap {
        ctrl := obj.control
        prop := obj.prop
        try configData .= key "=" ctrl.%prop% "`n"
    }

    ; Nuke coordinates (handled separately)
    if IsSet(nukeCoords) {
        configData .= "Nuke Coords=" nukeCoords.x "," nukeCoords.y "`n"
    }

    ; Save to file
    try {
        if FileExist(file)
            FileDelete(file)
        FileAppend(configData, file)
        AddToLog("✅ Unit configuration exported to Export\Exported_Unit_Config.txt")
    } catch {
        AddToLog("❌ Failed to export unit config.")
    }
}


InitSettings() {
    loop 6 {
        i := A_Index
        UnitConfigMap["Enabled" i] := { control: enabled%i%, prop: "Value" }
        UnitConfigMap["UpgradeEnabled" i] := { control: upgradeEnabled%i%, prop: "Value" }
        UnitConfigMap["AbilityEnabled" i] := { control: abilityEnabled%i%, prop: "Value" }
        UnitConfigMap["UpgradeLimitEnabled" i] := { control: upgradeLimitEnabled%i%, prop: "Value" }
        UnitConfigMap["UpgradeLimit" i] := { control: UpgradeLimit%i%, prop: "Text" }
        UnitConfigMap["Placement" i] := { control: placement%i%, prop: "Text" }
        UnitConfigMap["Priority" i] := { control: priority%i%, prop: "Text" }
        UnitConfigMap["UpgradePriority" i] := { control: UpgradePriority%i%, prop: "Text" }
    }

    ; Other controls
    UnitConfigMap["AutoAbility"] := { control: AutoAbilityBox, prop: "Value" }
    UnitConfigMap["AutoAbilityTimer"] := { control: AutoAbilityTimer, prop: "Text" }

    ; Zoom Tech Settings
    UnitConfigMap["ZoomLevel"] := { control: ZoomBox, prop: "Text" }
    UnitConfigMap["Use Zoom Tech"] := { control: ZoomTech, prop: "Value" }
    UnitConfigMap["Zoom In Then Out"] := { control: ZoomInOption, prop: "Value" }
    UnitConfigMap["Teleport To Spawn"] := { control: ZoomTeleport, prop: "Value" }

    UnitConfigMap["Unit Manager Upgrade System"] := { control: UnitManagerUpgradeSystem, prop: "Value" }
    UnitConfigMap["Priority Upgrade"] := { control: PriorityUpgrade, prop: "Value" }
    UnitConfigMap["Start Portal In Lobby"] := { control: PortalLobby, prop: "Value" }

    UnitConfigMap["Use Sunwoo Nuke"] := { control: SJWNuke, prop: "Value" }
    UnitConfigMap["Sunwoo Nuke Slot"] := { control: SJWSlot, prop: "Value" }
    UnitConfigMap["Nuke Enabled"] := { control: NukeUnitSlotEnabled, prop: "Value" }
    UnitConfigMap["Nuke Slot"] := { control: NukeUnitSlot, prop: "Value" }

    UnitConfigMap["Nuke At Specific Wave"] := { control: NukeAtSpecificWave, prop: "Value" }
    UnitConfigMap["Nuke Wave"] := { control: NukeWave, prop: "Value" }
    UnitConfigMap["Nuke Delay"] := { control: NukeDelay, prop: "Value" }

    UnitConfigMap["Slot 1 Minion"] := { control: MinionSlot1, prop: "Value" }
    UnitConfigMap["Slot 2 Minion"] := { control: MinionSlot2, prop: "Value" }
    UnitConfigMap["Slot 3 Minion"] := { control: MinionSlot3, prop: "Value" }
    UnitConfigMap["Slot 4 Minion"] := { control: MinionSlot4, prop: "Value" }
    UnitConfigMap["Slot 5 Minion"] := { control: MinionSlot5, prop: "Value" }
    UnitConfigMap["Slot 6 Minion"] := { control: MinionSlot6, prop: "Value" }

    UnitConfigMap["Halloween Restart Enabled"] := { control: HalloweenRestart, prop: "Value" }
    UnitConfigMap["Halloween Restart Timer"] := { control: HalloweenRestartTimer, prop: "Value" }

    UnitConfigMap["Teleport Failsafe Enabled"] := { control: TeleportFailsafe, prop: "Value" }
    UnitConfigMap["Teleport Failsafe Timer"] := { control: TeleportFailsafeTimer, prop: "Value" }
}