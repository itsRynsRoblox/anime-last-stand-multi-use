#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\GUI.ahk
global confirmClicked := false

SavePsSettings(*) {
    AddToLog("Saving Private Server")
    
    if FileExist("Settings\PrivateServer.txt")
        FileDelete("Settings\PrivateServer.txt")
    
    FileAppend(PsLinkBox.Value, "Settings\PrivateServer.txt", "UTF-8")
}

SaveUINavSettings(*) {
    AddToLog("Saving UI Navigation Key")
    
    if FileExist("Settings\UINavigation.txt")
        FileDelete("Settings\UINavigation.txt")
    
    FileAppend(UINavBox.Value, "Settings\UINavigation.txt", "UTF-8")
}

;Opens discord Link
OpenDiscordLink() {
    Run("https://discord.gg/mistdomain")
 }
 
 ;Minimizes the UI
 minimizeUI(*){
    aaMainUI.Minimize()
 }
 
 Destroy(*){
    aaMainUI.Destroy()
    ExitApp
 }

 ;Login Text
 setupOutputFile() {
     content := "`n==" aaTitle "" version "==`n  Start Time: [" currentTime "]`n"
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
    global mode
    selected := ModeDropdown.Text
    
    ; Hide all dropdowns first
    StoryDropdown.Visible := false
    LegendDropDown.Visible := false
    RaidDropdown.Visible := false
    RaidActDropdown.Visible := false
    NextLevelBox.Visible := false
    
    if (selected = "Story") {
        StoryDropdown.Visible := true
        mode := "Story"
    } else if (selected = "Legend") {
        LegendDropDown.Visible := true
        mode := "Legend"
    } else if (selected = "Raid") {
        RaidDropdown.Visible := true
        RaidActDropdown.Visible := true
        NextLevelBox.Visible := true
        mode := "Raid"
    } else if (selected = "Custom") {
        mode := "Custom"
        NextLevelBox.Visible := true
    } else if (selected = "Dungeon") {
        mode := "Dungeon"
    }
}

OnStoryChange(*) {
    if (StoryDropdown.Text != "") {

    } else {

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
        if (StoryDropdown.Text = "") {
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

    AddToLog("Don't forget to enable Click to Move! (I forget sometimes too!)")

    ; Hide all controls if validation passes
    ModeDropdown.Visible := false
    StoryDropdown.Visible := false
    LegendDropDown.Visible := false
    RaidDropdown.Visible := false
    RaidActDropdown.Visible := false
    ConfirmButton.Visible := false
    modeSelectionGroup.Visible := false
    Hotkeytext.Visible := true
    Hotkeytext2.Visible := true
    Hotkeytext3.Visible := true
    global confirmClicked := true
}


FixClick(x, y, LR := "Left") {
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep(50)
}

TogglePriorityDropdowns(*) {
    global PriorityUpgrade, priority1, priority2, priority3, priority4, priority5, priority6
    shouldShow := PriorityUpgrade.Value

    priority1.Visible := shouldShow
    priority2.Visible := shouldShow
    priority3.Visible := shouldShow
    priority4.Visible := shouldShow
    priority5.Visible := shouldShow
    priority6.Visible := shouldShow

    for unit in UnitData {
        unit.PriorityText.Visible := shouldShow
    }
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
