#Requires AutoHotkey v2.0

ValueInArray(arr, value) {
    for _, v in arr
        if (v = value)
            return true
    return false
}

AddPlacementProfile(skipInput := false, profileName := "") {
    global placementProfiles
    if (!skipInput) {
        result := InputBox("Enter new profile name:", "Add New Placement Profile", "x200 h100")
        if (result.Result != "OK" || result.Value = "")
            return
        profileName := result.Value
    } else {
        if (profileName = "")
            return
    }

    if !placementProfiles.Has(GameName)
        placementProfiles[GameName] := []

    placementProfiles[GameName].Push(profileName)
    UpdatePlacementProfileDropdown()
    SavePlacementProfiles()
}

DeletePlacementProfile() {
    global placementProfiles

    selectedGame := GameName
    selectedIndex := CustomPlacementMapDropdown.Value
    if (selectedIndex = 0)
        return  ; Nothing selected

    profileName := CustomPlacementMapDropdown.Text

    ; Ensure the game's profile list exists and is an Array
    if !IsObject(placementProfiles[selectedGame])
        placementProfiles[selectedGame] := []

    profiles := placementProfiles[selectedGame]

    ; Remove matching profile
    for i, name in profiles {
        if (name = profileName) {
            AddToLog("Deleted placement profile: " name)
            profiles.RemoveAt(i)
            break
        }
    }

    SavePlacementProfiles()
    UpdatePlacementProfileDropdown()
}

UpdatePlacementProfileDropdown() {
    selectedGame := GameName
    CustomPlacementMapDropdown.Delete()

    if !placementProfiles.Has(selectedGame)
        placementProfiles[selectedGame] := []

    for _, profile in placementProfiles[selectedGame]
        CustomPlacementMapDropdown.Add([profile])

    if (placementProfiles[selectedGame].Length)
        CustomPlacementMapDropdown.Value := 1
}

SavePlacementProfiles() {
    global placementProfiles, placementProfileFile
    if !DirExist(A_ScriptDir "\Settings")
        DirCreate(A_ScriptDir "\Settings")

    if !DirExist(A_ScriptDir "\Settings\Profiles")
        DirCreate(A_ScriptDir "\Settings\Profiles")

    json := jsongo.Stringify(placementProfiles)
    if (FileExist(placementProfileFile)) {
        FileDelete(placementProfileFile)
    }
    FileAppend(json, placementProfileFile, "UTF-8")
}

LoadPlacementProfiles() {
    global placementProfiles, placementProfileFile, customDropdowns, GameName

    placementProfiles := Map()
    selectedGame := GameName

    ; Handle missing file
    if !FileExist(placementProfileFile) {
        placementProfiles[selectedGame] := customDropdowns
        try
            SavePlacementProfiles()
        catch
            AddToLog("⚠️ Failed to save placement profiles: ")

        AddToLog("No placement profiles found — added default profiles.")
        UpdatePlacementProfileDropdown()
        return
    }

    ; File exists — load it
    data := FileRead(placementProfileFile, "UTF-8")
    if (data != "") {
        try
            placementProfiles := jsongo.Parse(data)
        catch {
            AddToLog("⚠️ Error parsing placement profiles JSON: ")
            placementProfiles := Map()
        }

        ; Merge defaults and keep player-added profiles at the bottom
        UpdateDefaultProfiles()
    } else {
        placementProfiles[selectedGame] := customDropdowns
        try
            SavePlacementProfiles()
        catch
            AddToLog("⚠️ Failed to save placement profiles: ")
    }

    UpdatePlacementProfileDropdown()
}

UpdateDefaultProfiles() {
    global placementProfiles, movementProfiles, recordingProfiles
    ; Helper function to update a specific profile map
    UpdateProfiles(profileMap) {
        if !IsObject(profileMap)
            profileMap := Map()

        if !profileMap.Has(gameName) || !IsObject(profileMap[gameName])
            profileMap[gameName] := []

        oldProfiles := profileMap[gameName]
        newProfiles := []

        ; Step 1: Add defaults in order
        for _, defaultName in customDropdowns {
            if !ValueInArray(newProfiles, defaultName)
                newProfiles.Push(defaultName)
        }

        ; Step 2: Append player-added profiles not already in defaults
        for _, existingName in oldProfiles {
            if !ValueInArray(newProfiles, existingName)
                newProfiles.Push(existingName)
        }

        profileMap[gameName] := newProfiles
        return profileMap
    }

    ; Update both placement and movement profiles
    placementProfiles := UpdateProfiles(placementProfiles)
    movementProfiles := UpdateProfiles(movementProfiles)
    recordingProfiles := UpdateProfiles(recordingProfiles)

    ; Save changes
    try {
        SavePlacementProfiles()
        SaveMovementProfiles()
        SaveRecordingProfiles()
    } catch {
        AddToLog("⚠️ Failed to save profiles")
    }
}

AddMovementProfile(skipInput := false, profileName := "") {
    if (!skipInput) {
        result := InputBox("Enter new profile name:", "Add New Movement Profile", "x200 h100")
        if (result.Result != "OK" || result.Value = "")
            return
        profileName := result.Value
    } else {
        if (profileName = "")
            return
    }

    if !movementProfiles.Has(GameName)
        movementProfiles[GameName] := []

    movementProfiles[GameName].Push(profileName)
    UpdateMovementProfileDropdown()
    SaveMovementProfiles()
}

DeleteMovementProfile() {
    global movementProfiles

    selectedGame := GameName
    selectedIndex := WalkMapDropdown.Value
    if (selectedIndex = 0)
        return  ; Nothing selected

    profileName := WalkMapDropdown.Text

    ; Ensure the game's profile list exists and is an Array
    if !IsObject(movementProfiles[selectedGame])
        movementProfiles[selectedGame] := []

    profiles := movementProfiles[selectedGame]

    ; Remove matching profile
    for i, name in profiles {
        if (name = profileName) {
            AddToLog("Deleted movement profile: " name)
            profiles.RemoveAt(i)
            break
        }
    }

    SaveMovementProfiles()
    UpdateMovementProfileDropdown()
}

UpdateMovementProfileDropdown() {
    global movementProfiles
    selectedGame := GameName
    WalkMapDropdown.Delete()

    if !movementProfiles.Has(selectedGame)
        movementProfiles[selectedGame] := []

    for _, profile in movementProfiles[selectedGame]
        WalkMapDropdown.Add([profile])

    if (movementProfiles[selectedGame].Length)
        WalkMapDropdown.Value := 1
}

SaveMovementProfiles() {
    global movementProfiles, movementProfileFile
    if !DirExist(A_ScriptDir "\Settings")
        DirCreate(A_ScriptDir "\Settings")

    if !DirExist(A_ScriptDir "\Settings\Profiles")
        DirCreate(A_ScriptDir "\Settings\Profiles")

    json := jsongo.Stringify(movementProfiles)
    if (FileExist(movementProfileFile)) {
        FileDelete(movementProfileFile)
    }
    FileAppend(json, movementProfileFile, "UTF-8")
}

LoadMovementProfiles() {
    global movementProfiles, movementProfileFile, customDropdowns

    movementProfiles := Map()
    selectedGame := GameName

    ; Handle missing file
    if !FileExist(movementProfileFile) {
        movementProfiles[selectedGame] := customDropdowns
        try
            SaveMovementProfiles()
        catch
            AddToLog("⚠️ Failed to save movement profiles")

        AddToLog("No movement profiles found — added default profiles.")
        UpdateMovementProfileDropdown()
        return
    }

    ; File exists — load it
    data := FileRead(movementProfileFile, "UTF-8")
    if (data != "") {
        try
            movementProfiles := jsongo.Parse(data)
        catch {
            AddToLog("⚠️ Error parsing placement profiles JSON")
            movementProfiles := Map()
        }

        ; Merge defaults and keep player-added profiles at the bottom
        UpdateDefaultProfiles()
    } else {
        movementProfiles[selectedGame] := customDropdowns
        try
            SavemovementProfiles()
        catch
            AddToLog("⚠️ Failed to save placement profiles")
    }

    UpdateMovementProfileDropdown()
}

UpdateDefaultMovementProfiles() {
    global movementProfiles, customDropdowns

    ; Ensure movementProfiles exists
    if !IsObject(movementProfiles)
        movementProfiles := Map()

    ; Ensure the game's entry is an array
    if !movementProfiles.Has(gameName) || !IsObject(movementProfiles[gameName])
        movementProfiles[gameName] := []

    oldProfiles := movementProfiles[gameName]
    newProfiles := []

    ; Step 1: Add defaults in order
    for _, defaultName in customDropdowns {
        if !ValueInArray(newProfiles, defaultName)
            newProfiles.Push(defaultName)
    }

    ; Step 2: Append player-added profiles not already in defaults
    for _, existingName in oldProfiles {
        if !ValueInArray(newProfiles, existingName)
            newProfiles.Push(existingName)
    }

    movementProfiles[gameName] := newProfiles

    ; Save changes
    try
        SaveMovementProfiles()
    catch
        AddToLog("⚠️ Failed to save movement profiles")
}

; === Add a new recording profile ===
AddRecordingProfile(skipInput := false, profileName := "") {
    if (!skipInput) {
        result := InputBox("Enter new profile name:", "Add New Recording Profile", "x200 h100")
        if (result.Result != "OK" || result.Value = "")
            return
        profileName := result.Value
    } else {
        if (profileName = "")
            return
    }

    if !recordingProfiles.Has(GameName)
        recordingProfiles[GameName] := []

    recordingProfiles[GameName].Push(profileName)
    UpdateRecordingProfileDropdown()
    SaveRecordingProfiles()
}

DeleteRecordingProfile() {
    global recordingProfiles

    selectedGame := GameName
    selectedIndex := RecordMapDropdown.Value
    if (selectedIndex = 0)
        return  ; Nothing selected

    profileName := RecordMapDropdown.Text

    ; Ensure the game's profile list exists and is an Array
    if !IsObject(recordingProfiles[selectedGame])
        recordingProfiles[selectedGame] := []

    profiles := recordingProfiles[selectedGame]

    ; Remove matching profile
    for i, name in profiles {
        if (name = profileName) {
            AddToLog("Deleted recording profile: " name)
            profiles.RemoveAt(i)
            break
        }
    }

    SaveRecordingProfiles()
    UpdateRecordingProfileDropdown()
}

; === Update the dropdown for recording profiles ===
UpdateRecordingProfileDropdown() {
    global recordingProfiles
    selectedGame := GameName
    RecordMapDropdown.Delete()

    if !recordingProfiles.Has(selectedGame)
        recordingProfiles[selectedGame] := []

    for _, profile in recordingProfiles[selectedGame]
        RecordMapDropdown.Add([profile])

    if (recordingProfiles[selectedGame].Length)
        RecordMapDropdown.Value := 1
}

; === Save recording profiles to file ===
SaveRecordingProfiles() {
    global recordingProfiles, recordingProfileFile
    if !DirExist(A_ScriptDir "\Settings")
        DirCreate(A_ScriptDir "\Settings")

    if !DirExist(A_ScriptDir "\Settings\Profiles")
        DirCreate(A_ScriptDir "\Settings\Profiles")

    json := jsongo.Stringify(recordingProfiles)
    if (FileExist(recordingProfileFile)) {
        FileDelete(recordingProfileFile)
    }
    FileAppend(json, recordingProfileFile, "UTF-8")
}

; === Load recording profiles from file ===
LoadRecordingProfiles() {
    global recordingProfiles, recordingProfileFile, customDropdowns

    recordingProfiles := Map()
    selectedGame := GameName

    ; Handle missing file
    if !FileExist(recordingProfileFile) {
        recordingProfiles[selectedGame] := customDropdowns
        try
            SaveRecordingProfiles()
        catch
            AddToLog("⚠️ Failed to save recording profiles")

        AddToLog("No recording profiles found — added default profiles.")
        UpdateRecordingProfileDropdown()
        return
    }

    ; File exists — load it
    data := FileRead(recordingProfileFile, "UTF-8")
    if (data != "") {
        try
            recordingProfiles := jsongo.Parse(data)
        catch {
            AddToLog("⚠️ Error parsing recording profiles JSON")
            recordingProfiles := Map()
        }

        ; Merge defaults and keep player-added profiles at the bottom
        UpdateDefaultRecordingProfiles()
    } else {
        recordingProfiles[selectedGame] := customDropdowns
        try
            SaveRecordingProfiles()
        catch
            AddToLog("⚠️ Failed to save recording profiles")
    }

    UpdateRecordingProfileDropdown()
}

; === Merge default profiles with player-added ones ===
UpdateDefaultRecordingProfiles() {
    global recordingProfiles, customDropdowns

    ; Ensure recordingProfiles exists
    if !IsObject(recordingProfiles)
        recordingProfiles := Map()

    ; Ensure the game's entry is an array
    if !recordingProfiles.Has(gameName) || !IsObject(recordingProfiles[gameName])
        recordingProfiles[gameName] := []

    oldProfiles := recordingProfiles[gameName]
    newProfiles := []

    ; Step 1: Add defaults in order
    for _, defaultName in customDropdowns {
        if !ValueInArray(newProfiles, defaultName)
            newProfiles.Push(defaultName)
    }

    ; Step 2: Append player-added profiles not already in defaults
    for _, existingName in oldProfiles {
        if !ValueInArray(newProfiles, existingName)
            newProfiles.Push(existingName)
    }

    recordingProfiles[gameName] := newProfiles

    ; Save changes
    try
        SaveRecordingProfiles()
    catch
        AddToLog("⚠️ Failed to save recording profiles")
}

LoadAllProfiles() {
    LoadPlacementProfiles()
    LoadMovementProfiles()
    LoadRecordingProfiles()
}