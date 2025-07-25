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
     content := "`n==" GameTitle "" version "==`n  Start Time: [" currentTime "]`n"
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
    selected := ModeDropdown.Text

    ; Array of all dropdowns to hide
    dropdowns := [
        StoryDropdown,
        StoryActDropdown,
        LegendDropDown,
        RaidDropdown,
        RaidActDropdown,
        DungeonDropdown,
        PortalDropdown,
        PortalRoleDropdown
    ]

    ; Hide all
    for ctrl in dropdowns
        ctrl.Visible := false

    ; Show based on selection
    switch selected {
        case "Story":
            StoryDropdown.Visible := true
        case "Legend":
            LegendDropDown.Visible := true
        case "Raid":
            RaidDropdown.Visible := true
            RaidActDropdown.Visible := true
        case "Dungeon":
            DungeonDropdown.Visible := true
        case "Portal":
            PortalDropdown.Visible := true
            PortalRoleDropdown.Visible := true
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

OnConfirmClick(*) {
    if (ModeDropdown.Text = "") {
        AddToLog("Please select a gamemode before confirming")
        return
    }

    ; For Story mode, check if both Story and Act are selected
    if (ModeDropdown.Text = "Story") {
        if (StoryDropdown.Text = "" || StoryActDropdown.Text = "") {
            AddToLog("Please select both Story and Act before confirming")
            return
        }
        AddToLog("Selected " StoryDropdown.Text)
    }
    ; For Legend mode, check if both Legend and Act are selected
    else if (ModeDropdown.Text = "Legend") {
        if (LegendDropDown.Text = "") {
            AddToLog("Please select both Legend Stage and Act before confirming")
            return
        }
        AddToLog("Selected " LegendDropDown.Text)
    }
    ; For Custom mode, check if coords are empty
    else if (ModeDropdown.Text = "Custom") {
        AddToLog("Selected Custom")
    }
    ; For Raid mode, check if both Raid and RaidAct are selected
    else if (ModeDropdown.Text = "Raid") {
        if (RaidDropdown.Text = "") {
            AddToLog("Please select both Raid and Act before confirming")
            return
        }
        AddToLog("Selected " RaidDropdown.Text)
    } else {
        AddToLog("Selected " ModeDropdown.Text " mode")
    }

    ; Hide all controls if validation passes
    ModeDropdown.Visible := false
    StoryDropdown.Visible := false
    StoryActDropdown.Visible := false
    LegendDropDown.Visible := false
    RaidDropdown.Visible := false
    RaidActDropdown.Visible := false
    DungeonDropdown.Visible := false
    PortalDropdown.Visible := false
    PortalRoleDropdown.Visible := false
    ConfirmButton.Visible := false
    modeSelectionGroup.Visible := false
    Hotkeytext.Visible := true
    Hotkeytext2.Visible := true
    Hotkeytext3.Visible := true
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
    Run("https://discord.gg/6DWgB9XMTV")
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
    Send("{Tab}") ; Close any open popups
    FixClick(623, 147) ; Update UI
    Sleep(500)
    FixClick(400,340)
    Sleep(500)
    FixClick(400,390)

}

; === ClickUnit unchanged but passed totalUnits explicitly ===
ClickUnit(slot, totalUnits) {
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

    FixClick(clickX, clickY)
    Sleep(150)
}

GetAutoAbilityTimer() {
    seconds := AutoAbilityTimer.Value
    return Round(seconds * 1000)
}

ToggleMenu(name := "") {
    if (!name)
        return

    key := ""
    if (name = "Unit Manager")
        key := "F"
    else if (name = "Ability Manager")
        key := "Z"

    if (!key)
        return

    if (isMenuOpen(name)) {
        AddToLog("Closing " name)
        Send(key)
        Sleep(300)
    } else {
        Send(key)
        AddToLog("Opening " name)
        Sleep(300)
    }
}

CloseMenu(name := "") {
    if (!name)
        return

    key := ""
    if (name = "Unit Manager")
        key := "F"
    else if (name = "Ability Manager")
        key := "Z"

    if (!key)
        return

    if (isMenuOpen(name)) {
        AddToLog("Closing " name)
        Send(key)  ; Close menu if it's open
        Sleep(300)
    }
}

OpenMenu(name := "") {
    if (!name)
        return

    key := ""
    if (name = "Unit Manager")
        key := "F"
    else if (name = "Ability Manager")
        key := "Z"

    if (!key)
        return  ; Unknown menu name

    if (!isMenuOpen(name)) {
        AddToLog("Opening " name)
        Send(key)
        Sleep(1000)
    }
}

CheckAutoAbility() {
    global successfulCoordinates
    global totalUnits

    AddToLog("Checking for unactive abilities...")
    OpenMenu("Ability Manager")
    Sleep (1000)

    if (CheckForXP()) {
        AddToLog("Stopping auto ability check because the game ended")
        CloseMenu("Ability Manager")
        SetTimer(CheckAutoAbility, 0)  ; Stop the timer
        return
    }

    HandleAutoAbilityUnitManager()
    Sleep (1000)
    CloseMenu("Ability Manager")
    AddToLog("Finished looking for abilities")
}

CleanString(str) {
    ; Remove emojis and any adjacent spaces (handles gaps)
    return RegExReplace(str, "\s*[^\x00-\x7F]+\s*", " ")
}

SortArrayOfObjects(arr, key, ascending := true) {
    len := arr.Length
    if (len < 2)
        return arr

    Loop len {
        i := 1
        while (i < len) {
            a := arr[i][key]
            b := arr[i + 1][key]

            if (ascending ? (a > b) : (a < b)) {
                temp := arr[i]
                arr[i] := arr[i + 1]
                arr[i + 1] := temp
            }
            i++
        }
    }
    return arr
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