#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\GUI.ahk
global confirmClicked := false
 
 ;Minimizes the UI
 minimizeUI(*){
    MainUI.Minimize()
 }
 
 Destroy(*){
    MainUI.Destroy()
    ExitApp
 }

 ;Login Text
 setupOutputFile() {
     content := "`n==" GameTitle "" version "==`nStart Time: [" currentTime "]`n"
     FileAppend(content, currentOutputFile)
 }
 
; Gets the current time in 12-hour format
getCurrentTime() {
    currentHour := A_Hour
    currentMinute := A_Min
    currentSecond := A_Sec
    amPm := (currentHour >= 12) ? "PM" : "AM"
    
    ; Convert to 12-hour format
    currentHour := Mod(currentHour - 1, 12) + 1

    return Format("{:d}:{:02}:{:02} {}", currentHour, currentMinute, currentSecond, amPm)
}

OnModeChange(*) {
    ; Hide all
    for ctrl in [StoryDropdown, StoryActDropdown, BossRushDropdown, LegendDropDown, RaidDropdown, RaidActDropdown, DungeonDropdown, PortalDropdown, PortalRoleDropdown, SiegeDropdown, SurvivalDropdown, EventDropdown]
        ctrl.Visible := false

    if (ActiveControlGroup = "Mode") {
        ToggleControlGroup(ModeDropdown.Text)
    }

    ; Show based on selection
    switch ModeDropdown.Text {
        case "Event":
            EventDropdown.Visible := true
        case "Story":
            StoryDropdown.Visible := true
            StoryActDropdown.Visible := true
        case "Boss Rush":
            BossRushDropdown.Visible := true    
        case "Legend":
            LegendDropDown.Visible := true
        case "Raid":
            RaidDropdown.Visible := RaidActDropdown.Visible := true
        case "Dungeon":
            DungeonDropdown.Visible := true
        case "Portal":
            PortalDropdown.Visible := PortalRoleDropdown.Visible := true
        case "Siege":
            SiegeDropdown.Visible := true
        case "Survival":
            SurvivalDropdown.Visible := true
        case "Dungeon":
            AddToLog("[Dungeon] Make sure you have enabled your modifiers!")
            DungeonDropdown.Visible := true
        case "Custom":
            ; Add handling if needed
    }

    if (ModeConfigurations.Value) {
        LoadUnitSettingsByMode()
    }
}

OnStoryChange(*) {
    if (StoryDropdown.Text != "") {
        StoryActDropdown.Visible := true
    } else {
        StoryActDropdown.Visible := false
    }
}

OnLegendChange(*) {
    if (LegendDropDown.Text != "") {

    } else {

    }
}

OnRaidChange(*) {
    if (RaidDropdown.Text != "") {
        RaidActDropdown.Visible := true
    } else {
        RaidActDropdown.Visible := false
    }
}

OnPlacementChange(*) {
    if (PlacementPatternDropdown.Text = "Custom") {
        enabledPlacements := UseCustomPoints()
        if (!enabledPlacements) {
            AddToLog("No placements set, please set at least one placement!")
        }
    }
}

OnConfirmClick(*) {
    mode := ModeDropdown.Text
    if (mode = "") {
        AddToLog("Please select a gamemode before confirming")
        return
    }

    ; Validation per mode
    missing := ""
    switch mode {
        case "Story":
            if (StoryDropdown.Text = "" || StoryActDropdown.Text = "")
                missing := "both Story and Act"
            else
                AddToLog("Selected " StoryDropdown.Text)

        case "Legend":
            if (LegendDropDown.Text = "")
                missing := "both Legend Stage and Act"
            else
                AddToLog("Selected " LegendDropDown.Text)

        case "Raid":
            if (RaidDropdown.Text = "")
                missing := "both Raid and Act"
            else
                AddToLog("Selected " RaidDropdown.Text)

        case "Custom":
            AddToLog("Selected Custom")

        default:
            AddToLog("Selected " mode " mode")
    }

    if (missing) {
        AddToLog("Please select " missing " before confirming")
        return
    }

    ; Hide all dropdowns and confirm button
    for ctrl in [ModeDropdown, StoryDropdown, StoryActDropdown, LegendDropDown,
        RaidDropdown, RaidActDropdown, DungeonDropdown, PortalDropdown,
        PortalRoleDropdown, BossRushDropdown, SiegeDropdown,
        SurvivalDropdown, EventDropdown, ConfirmButton, modeSelectionGroup] {
        ctrl.Visible := false
    }

    ; Show hotkey texts
    for ctrl in [Hotkeytext, Hotkeytext2, Hotkeytext3]
        ctrl.Visible := true

    global confirmClicked := true
}


FixClick(x, y, LR := "Left", shouldWiggle := false) {
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    Sleep(50)
    if (shouldWiggle) {
        wiggle()
    }
    MouseClick(LR, -1, 0, , , , "R")
}

GetWindowCenter(WinTitle) {
    x := 0 y := 0 Width := 0 Height := 0
    WinGetPos(&X, &Y, &Width, &Height, WinTitle)

    centerX := X + (Width / 2)
    centerY := Y + (Height / 2)

    return { x: centerX, y: centerY, width: Width, height: Height }
}

FindAndClickColor(targetColor := 0xFAFF4D, searchArea := [0, 0, GetWindowCenter(rblxID).Width, GetWindowCenter(rblxID).Height]) {
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        FixClick(foundX, foundY, "Right")
        AddToLog("Color found and clicked at: X" foundX " Y" foundY)
        return true

    }
}

FindAndClickImage(imagePath, searchArea := [0, 0, A_ScreenWidth, A_ScreenHeight]) {

    AddToLog(imagePath)

    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the image search
    if (ImageSearch(&foundX, &foundY, x1, y1, x2, y2, imagePath)) {
        ; Image found, click on the detected coordinates
        FixClick(foundX, foundY, "Right")
        AddToLog("Image found and clicked at: X" foundX " Y" foundY)
        return true
    }
}

FindAndClickText(textToFind, searchArea := [0, 0, GetWindowCenter(rblxID).Width, GetWindowCenter(rblxID).Height]) {
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the text search
    if (FindText(&foundX, &foundY, x1, y1, x2, y2, textToFind)) {
        ; Text found, click on the detected coordinates
        FixClick(foundX, foundY, "Right")
        AddToLog("Text found and clicked at: X" foundX " Y" foundY)
        return true
    }
}

OpenGithub() {
    Run("https://github.com/itsRynsRoblox?tab=repositories")
}

OpenDiscord() {
    Run("https://discord.gg/rynsrealm")
}

StringJoin(array, delimiter := ", ") {
    result := ""
    ; Convert the array to an Object to make it enumerable
    for index, value in array {
        if (index > 1)
            result .= delimiter
        result .= value
    }
    return result
}

CopyMouseCoords(withColor := false) {
    MouseGetPos(&x, &y)
    color := PixelGetColor(x, y, "RGB")  ; Correct usage in AHK v2

    A_Clipboard := ""  ; Clear clipboard
    ClipWait(0.5)

    if (withColor) {
        A_Clipboard := x ", " y " | Color: " color
    } else {
        A_Clipboard := x ", " y
    }

    ClipWait(0.5)

    ; Check if the clipboard content matches the expected format

    if (withColor) {
        if (A_Clipboard = x ", " y " | Color: " color) {
            AddToLog("Copied: " x ", " y " | Color: " color)
        }
    } 
    else {
        if (A_Clipboard = x ", " y) {
            AddToLog("Copied: " x ", " y)
        }
    }
}

CalculateElapsedTime(startTime) {
    elapsedTimeMs := A_TickCount - startTime
    elapsedTimeSec := Floor(elapsedTimeMs / 1000)
    elapsedHours := Floor(elapsedTimeSec / 3600)
    elapsedMinutes := Floor(Mod(elapsedTimeSec, 3600) / 60)
    elapsedSeconds := Mod(elapsedTimeSec, 60)
    return Format("{:02}:{:02}:{:02}", elapsedHours, elapsedMinutes, elapsedSeconds)
}

GetPixel(color, x1, y1, extraX, extraY, variation) {
    global foundX, foundY
    try {
        if PixelSearch(&foundX, &foundY, x1, y1, x1 + extraX, y1 + extraY, color, variation) {
            return [foundX, foundY] AND true
        }
        return false
    }
}

Teleport(mode := "") {
    FixClick(33, 340) ; Open teleport menu
    Sleep 500
    switch mode {
        case "Dungeon":
            FixClick(407, 382) ; Click on Dungeon
        case "Story":
            FixClick(393, 329) ; Click on Story
        case "Raid":
            FixClick(531, 206) ; Move mouse to scroll down
            Sleep (500)
            Scroll(20, 'WheelDown', 5)
            Sleep 1000
            FixClick(407, 382)
        default:
            AddToLog("Invalid teleport mode specified")
    }
    Sleep 500
    FixClick(33, 340) ; Close the teleport menu
    Sleep(1000)
}

Scroll(times, direction, delay) {
    if (times < 1) {
        if (debugMessages) {
            AddToLog("Invalid number of times")
        }
        return
    }
    if (direction != "WheelUp" and direction != "WheelDown") {
        if (debugMessages) {
            AddToLog("Invalid scroll direction: " direction)
        }
        return
    }
    if (delay < 0) {
        if (debugMessages) {
            AddToLog("Invalid delay: " delay)
        }
        return
    }
    loop times {
        Send("{" direction "}")
        Sleep(delay)
    }
}

RotateCameraAngle() {
    Send("{Right down}")
    Sleep 800
    Send("{Right up}")
}

CloseLobbyPopups() {
    CloseLeaderboard(true)
    Sleep(500)
    FixClick(632, 150) ; Update UI
    Sleep(500)
    FixClick(400,340)
    Sleep(500)
    FixClick(400,390)

}

ClickUnit(slot, forNuke := false) {
    global totalUnits
    baseX := 585
    baseY := 175
    colSpacing := 80
    rowSpacing := 115
    maxCols := 3

    totalCount := 0
    for _, count in totalUnits {
        totalCount += count
    }

    fullRows := Floor(totalCount / maxCols)
    lastRowUnits := Mod(totalCount, maxCols)

    index := slot - 1
    row := Floor(index / maxCols)
    colInRow := Mod(index, maxCols)
    isLastRow := (row = fullRows)

    if (lastRowUnits != 0 && isLastRow) {
        rowStartX := baseX + Floor((maxCols - lastRowUnits) * colSpacing / 2)
        clickX := rowStartX + (colInRow * colSpacing)
    } else {
        clickX := baseX + (colInRow * colSpacing)
    }

    clickY := baseY + (row * rowSpacing)

    OpenMenu("Unit Manager")
    Sleep(500)

    if (CheckForXp()) {
        CloseMenu("Unit Manager")
        return MonitorStage()
    }

    if (forNuke) {
        while (!GetPixel(0x1034AC, 78, 362, 2, 2, 2)) {
            CheckForCardSelection()

            if (CheckForXp()) {
                CloseMenu("Unit Manager")
                ClearNuke()
                return MonitorStage()
            }

            FixClick(clickX, clickY)
            Sleep(250)
        }
    } else {
        FixClick(clickX, clickY)
        Sleep(150)
    }
}

CloseMenu(name := "") {
    if (!name)
        return

    key := ""
    clickX := 0, clickY := 0
    if (name = "Unit Manager")
        key := "F"
    else if (name = "Ability Manager")
        key := "Z"

    if (!key)
        return  ; Unknown menu name

    if (isMenuOpen(name)) {
        AddToLog("Closing " name)
        Send(key)  ; Close menu if it's open
        Sleep(300)
    }
}

OpenMenu(name := "") {
    static menuKeys := Map(
        "Unit Manager", "F",
        "Ability Manager", "Z"
    )

    if !name || !menuKeys.Has(name)
        return  ; Invalid or unknown menu

    key := menuKeys[name]

    if isMenuOpen(name)
        return true  ; Already open

    AddToLog("Opening " name)

    maxAttempts := 3
    delay := 700  ; ms between checks

    loop maxAttempts {
        Send(key)
        if WaitForMenuOpen(name, delay) {
            AddToLog("✅ " name " opened after " A_Index " attempt(s).")
            return true
        }
        Sleep(150)  ; small pause before retrying
    }

    AddToLog("⚠️ Failed to open " name " after " maxAttempts " attempts.")
    return false
}

WaitForMenuOpen(name, timeout := 700) {
    start := A_TickCount
    while (A_TickCount - start < timeout) {
        if isMenuOpen(name)
            return true
        Sleep(50)
    }
    return false
}

CleanString(str) {
    ; Remove emojis and any adjacent spaces (handles gaps)
    return RegExReplace(str, "\s*[^\x00-\x7F]+\s*", "")
}

OnPriorityChange(type, priorityNumber, newPriorityNumber) {
    if (newPriorityNumber == "") {
        newPriorityNumber := "Disabled"
    }
    if (type == "Placement") {
        AddToLog("Placement priority changed: Slot " priorityNumber " → " newPriorityNumber)
    } else {
        AddToLog("Upgrade priority changed: Slot " priorityNumber " → " newPriorityNumber)
    }
}

CheckForCardSelection() {
    if GetPixel(0x4A4747, 436, 383, 2, 2, 5) {
        SelectCardsByMode()
        return true
    }
    return false
}

SearchForImage(X1, Y1, X2, Y2, image) {
    if !WinExist(rblxID) {
        AddToLog("Roblox window not found.")
        return false
    }

    WinActivate(rblxID)

    return ImageSearch(&FoundX, &FoundY, X1, Y1, X2, Y2, image)
}

OpenCardConfig() {
    if (EventDropdown.Text = "Halloween") {
        SwitchCardMode("Halloween")
    }
    else if (ModeDropdown.Text = "Boss Rush") {
        SwitchCardMode("BossRush")
    }
    else {
        AddToLog("No card configuration available for mode: " (ModeDropdown.Text = "" ? "None" : ModeDropdown.Text))
    }
}

AddWaitingFor(action) {
    global waitingState, waitingForClick
    waitingState := action
    waitingForClick := true
}

WaitingFor(action) {
    global waitingState
    if (waitingState = action) {
        return true
    }
    return false
}

RemoveWaiting() {
    global waitingState, waitingForClick
    waitingForClick := false
    waitingState := ""
}

HasMinionInSlot(slot) {
    if (slot = 1)
        return !!MinionSlot1.Value
    else if (slot = 2)
        return !!MinionSlot2.Value
    else if (slot = 3)
        return !!MinionSlot3.Value
    else if (slot = 4)
        return !!MinionSlot4.Value
    else if (slot = 5)
        return !!MinionSlot5.Value
    else if (slot = 6)
        return !!MinionSlot6.Value
    return false
}

CheckUnitAbilities() {
    global successfulCoordinates, maxedCoordinates

    AddToLog("Checking auto abilities of placed units...")

    for coord in successfulCoordinates {

        slot := coord.slot

        if (CheckForXp()) {
            AddToLog("Stopping auto ability check because the game ended")
            return MonitorStage()
        }

        if (CheckForCardSelection()) {
            SelectCardsByMode()
        }

        if (NukeUnitSlotEnabled.Value && slot = NukeUnitSlot.Value) {
            AddToLog("Skipping nuke unit in slot " slot)
            continue
        }

        FixClick(coord.x, coord.y)
        Sleep(500)

        HandleAutoAbility()
    }
}

; Global variable to track current coordinate mode (default is Screen)
global currentCoordMode := "Screen"
global oldCoordMode := ""

; Wrapper function to set coord mode and save state
SetCoordModeTracked(mode) {
    global currentCoordMode, oldCoordMode
    oldCoordMode := currentCoordMode
    CoordMode("Mouse", mode)
    currentCoordMode := mode
}

isConnectedToInternet() {
    return DllCall("Wininet.dll\InternetGetConnectedState", "int*", 0, "int", 0)
}

GetPrivateServerCode(link) {
    if RegExMatch(link, "privateServerLinkCode=([\w-]+)", &m)
        return m[1]
    return ""
}

isInLobby() {
    return FindText(&X, &Y, 7, 590, 37, 618, 0, 0, LobbySettings)
}

UpdateActiveConfiguration(*) {
    ToggleControlGroup(ConfigurationDropdown.Text)
}

CloseLeaderboard(inLobby := true) {
    if (inLobby) {
        if (ok := FindText(&X, &Y, 632, 93, 656, 115, 0.15, 0.15, OpenLeaderboard)) {
            SendInput("{Tab}")
        } else {
            FixClick(641, 72)
        }
    } else {
        if (ok := FindText(&X, &Y, 482, 97, 499, 111, 0.15, 0.15, OpenLeaderboard)) {
            SendInput("{Tab}")
        } else {
            FixClick(487, 71)
        }
    }
}

ClaimBingo() {
    ; Base starting coordinate
    startX := 190
    startY := 420

    ; Number of clicks in each direction
    horizontalClicks := 6
    verticalClicks := 6

    ; Spacing in pixels between clicks
    spacing := 50

    while (true) {
        ; --- Redeem Stamp ---
        loop 25 {
            FixClick(543, 423)
        }

        ; --- Horizontal row ---
        loop horizontalClicks {
            FixClick(startX + (A_Index - 1) * spacing, startY)
        }

        ; --- Vertical column ---
        finalX := startX + (horizontalClicks - 1) * spacing
        loop verticalClicks {
            FixClick(finalX, startY - (A_Index - 1) * spacing)
        }

        ; --- Claim Bingo ---
        FixClick(543, 423)
        Sleep(1500)
    }
}