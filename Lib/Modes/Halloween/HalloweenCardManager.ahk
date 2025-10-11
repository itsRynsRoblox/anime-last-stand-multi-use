#Requires AutoHotkey v2.0
#Include %A_ScriptDir%/Lib\RapidOcr\RapidOcr.ahk

global HalloweenCardSelector := Gui("+AlwaysOnTop")
HalloweenCardSelector.SetFont("s10 bold", "Segoe UI")
HalloweenCardSelector.BackColor := "0c000a"
HalloweenCardSelector.MarginX := 20
HalloweenCardSelector.MarginY := 20
HalloweenCardSelector.Title := "Card Priority"

PriorityOrder := HalloweenCardSelector.Add("GroupBox", "x30 y25 w190 h535 cWhite +Center", "Modifier Priority Order")

options := [
    "TrickorTreat",
    "ScorchingHell",
    "WeakenedResolve",
    "FierySurge",
    "HellMerchant",
    "FortuneFlow",
    "PowerReversal",
    "GrievousWounds",
    "FogofWar",
    "BulletBreaker",
    "GreedyVampires",
    "SeethingBloodlust",
    "LingeringFear",
    "HellishWarp",
    "HellishGravity",
    "CriticalDenial",
    "DeadlyStriker",
    "SoulLink",
    "DevilsSacrifice"
]

numDropDowns := 19
yStart := 50
ySpacing := 28

global dropDowns := []

For index, card in options {
    if (index > numDropDowns)
        Break
    yPos := yStart + ((index - 1) * ySpacing)
    HalloweenCardSelector.Add("Text", Format("x38 y{} w30 h17 +0x200 cWhite", yPos), index)
    dropDown := HalloweenCardSelector.Add("DropDownList", Format("x60 y{} w135 Choose{}", yPos, index), options)
    dropDowns.Push(dropDown)

    AttachDropDownEvent(dropDown, A_Index, OnDropDownChange)
}

OpenHalloweenPriorityPicker() {
    HalloweenCardSelector.Show()
}

global priorityOrder := [
    "TrickorTreat",
    "ScorchingHell",
    "WeakenedResolve",
    "FierySurge",
    "HellMerchant",
    "FortuneFlow",
    "PowerReversal",
    "GrievousWounds",
    "FogofWar",
    "BulletBreaker",
    "GreedyVampires",
    "SeethingBloodlust",
    "LingeringFear",
    "HellishWarp",
    "HellishGravity",
    "CriticalDenial",
    "DeadlyStriker",
    "SoulLink",
    "DevilsSacrifice" ; No Abilities
]

SaveCardConfig(*) {
    SaveCardLocal
    return
}

LoadCardConfig(*) {
    LoadCardLocal
    return
}

SaveCardConfigToFile(filePath) {
    global PlacementPatternDropdown
    directory := "Settings"

    if !DirExist(directory) {
        DirCreate(directory)
    }
    if !FileExist(filePath) {
        FileAppend("", filePath)
    }

    File := FileOpen(filePath, "w")
    if !File {
        AddToLog("Failed to save the card configuration.")
        return
    }

    File.WriteLine("[CardPriority]")
    for index, dropDown in dropDowns
    {
        File.WriteLine(Format("{}={}", dropDown.Text, index+1))
    }

    File.Close()
    if (debugMessages) {
        AddToLog("Card configuration saved successfully to " filePath "`n")
    }
}

LoadCardConfigFromFile(filePath) {
    global dropDowns

    if !FileExist(filePath) {
        AddToLog("No card configuration file found. Creating new local configuration.")
	SaveCardLocal
    } else {
        ; Open file for reading
        file := FileOpen(filePath, "r", "UTF-8")
        if !file {
            AddToLog("Failed to load the configuration.")
            return
        }

        section := ""
        ; Read settings from the file
        while !file.AtEOF {
            line := file.ReadLine()

            ; Detect section headers
            if RegExMatch(line, "^\[(.*)\]$", &match) {
                section := match.1
                continue
            }

            ; Process the lines based on the section
            if (section = "CardPriority") {
                if RegExMatch(line, "(\d+)=(\w+)", &match) {
                    value := match.1
                    slot := match.2

                    priorityOrder[slot - 1] := value

                    dropDown := dropDowns[slot - 1]

                    if (dropDown) {
                        dropDown.Text := value
                    }
		    
                }
            }
        }
        file.Close()
        if (debugMessages) {
            AddToLog("Card configuration loaded successfully.")
        }
    }
}

SaveCardLocal(*) {
    SaveCardConfigToFile("Settings\HalloweenCardPriority.txt")
}

LoadCardLocal(*) {
    LoadCardConfigFromFile("Settings\HalloweenCardPriority.txt")
}