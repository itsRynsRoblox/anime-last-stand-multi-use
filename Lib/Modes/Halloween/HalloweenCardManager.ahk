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
    "DevilsSacrifice",
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
    "SoulLink"
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
    "DevilsSacrifice",
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
    "SoulLink"
]

priority := []

OnDropDownChange(ctrl, index) {
    if (index >= 0 and index <= 19) {
        priorityOrder[index] := ctrl.Text
        AddToLog(Format("Priority {} set to {}", index, ctrl.Text))
        RemoveEmptyStrings(priorityOrder)
        SaveCardLocal
    } else {
        if (debugMessages) {
            AddToLog(Format("Invalid index {} for dropdown", index))
        }
    }
}

SelectCardsHalloween() {
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
    }
    AddToLog("Selecting Card for Halloween...")

    cardPrioFile := A_ScriptDir "\Settings\HalloweenCardPriority.txt"
    cardPriorities := Map()

    if (!FileExist(cardPrioFile)) {
        AddToLog("Error: HalloweenCardPriority.txt not found.")
        return false
    }

    try {
        loop read, cardPrioFile {
            line := Trim(A_LoopReadLine)
            if (line = "" || SubStr(line, 1, 1) = ";") {
                continue
            }
            parts := StrSplit(line, "=")
            if (parts.Length = 2) {
                cardName := Trim(parts[1])
                priority := Integer(Trim(parts[2]))
                if (priority > 0) {
                    cardPriorities[cardName] := priority
                }
            }
        }
    } catch Error as e {
        AddToLog("Error reading HalloweenCardPriority.txt: " e.Message)
        return false
    }

    if (cardPriorities.Count = 0) {
        AddToLog("No card priorities set in HalloweenCardPriority.txt. Cannot proceed.")
        return false
    }

    cardSlots := [
        { clickX: 169, clickY: 305, ocrX1: 123, ocrY1: 233, ocrX2: 218, ocrY2: 264 },
        { clickX: 328, clickY: 288, ocrX1: 273, ocrY1: 235, ocrX2: 371, ocrY2: 257 },
        { clickX: 486, clickY: 291, ocrX1: 439, ocrY1: 233, ocrX2: 530, ocrY2: 251 },
        { clickX: 642, clickY: 295, ocrX1: 582, ocrY1: 225, ocrX2: 689, ocrY2: 256 }
    ]

    foundCards := Map()
    for index, slot in cardSlots {
        MouseMove(slot.clickX, slot.clickY)
        Wiggle()
        Sleep(500)

        ocrResult := OcrBetter(slot.ocrX1, slot.ocrY1, slot.ocrX2, slot.ocrY2, 10, false)
        ocrCleaned := RegExReplace(ocrResult, "\\s+|!", "")
        ocrCleaned := RegExReplace(ocrCleaned, "[^a-zA-Z]", "")
        ocrCleaned := RegExReplace(ocrCleaned, "i)(IV|III|II|I)$", "")

        AddToLog("Slot " index " Found : " ocrCleaned)

        if (ocrCleaned != "") {
            for cardName, priority in cardPriorities {
                if (SubStr(ocrCleaned, 1, StrLen(cardName)) = cardName) {
                    foundCards[cardName] := { slot: slot, priority: priority }
                    AddToLog("Found card '" cardName "' with priority " priority)
                    break
                }
            }
        }
        Sleep(100)
    }

    if (foundCards.Count > 0) {
        highestPriority := 999
        bestCard := ""
        for cardName, cardInfo in foundCards {
            if (cardInfo.priority < highestPriority) {
                highestPriority := cardInfo.priority
                bestCard := cardName
            }
        }

        if (bestCard != "") {
            AddToLog("Selecting highest priority card: " bestCard)
            slot := foundCards[bestCard].slot
            FixClick(slot.clickX, slot.clickY)
            Sleep(500)
            FixClick(401, 382)
            return true
        }
    }

    AddToLog("No cards found....")
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer()) ; Resume auto ability checks
    }
}

OcrBetter(x1, y1, x2, y2, scale, debug := false) {
    try {
        WinGetPos(&winX, &winY, , , "ahk_exe RobloxPlayerBeta.exe")
        x1 += winX
        y1 += winY
        x2 += winX
        y2 += winY

        pToken := Gdip_Startup()

        width := x2 - x1
        height := y2 - y1
        pBitmap := Gdip_BitmapFromScreen(x1 "|" y1 "|" width "|" height)

        newWidth := width * scale
        newHeight := height * scale

        pScaled := Gdip_CreateBitmap(newWidth, newHeight)
        g := Gdip_GraphicsFromImage(pScaled)

        Gdip_SetSmoothingMode(g, 4)
        Gdip_SetInterpolationMode(g, 7)
        Gdip_SetPixelOffsetMode(g, 5)

        Gdip_DrawImage(g, pBitmap, 0, 0, newWidth, newHeight, 0, 0, width, height)

        filename := "OCR"
        fullPath := A_ScriptDir "\Images\" filename ".png"

        if FileExist(fullPath)
            FileDelete(fullPath)

        Gdip_SaveBitmapToFile(pScaled, fullPath, 100)

        Sleep 100

        if !FileExist(fullPath) {
            AddToLog("Failed to save OCR image")
            return ""
        }

        result := OCR.ocr_from_file(fullPath, , true)
        Sleep 100

        Gdip_DeleteGraphics(g)
        Gdip_DisposeImage(pBitmap)
        Gdip_DisposeImage(pScaled)
        Gdip_Shutdown(pToken)

        if FileExist(fullPath)
            FileDelete(fullPath)

        if debug {
            if IsObject(result) && result.Length > 0 {
                text := ""
                for block in result {
                    cleanedText := RegExReplace(block.text, "\s+", "")
                    text .= cleanedText
                }
                if text != ""
                    AddToLog("Found text: " text)
                else
                    AddToLog("No text found in result")
            } else {
                AddToLog("No result returned or result is empty")
            }
        }

        if IsObject(result) && result.Length > 0 {
            finalText := ""
            for block in result {
                cleaned := RegExReplace(block.text, "\s+", "")
                finalText .= cleaned
            }
            return finalText
        }
        return ""
    } catch as err {
        AddToLog("OCR Error: " err.Message)
        return ""
    }
}

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