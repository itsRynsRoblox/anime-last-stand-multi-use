#Requires AutoHotkey v2.0

CreateCardPriorityGui(config) {
    global CardGUI := Gui("+AlwaysOnTop")
    CardGUI.SetFont("s10 bold", "Segoe UI")
    CardGUI.BackColor := "0c000a"
    CardGUI.MarginX := 25
    CardGUI.MarginY := 20
    CardGUI.Title := config["title"]

    global dropDowns := []
    global priorityOrder := []

    yStart := 50
    ySpacing := 28

    loop config["options"].Length {
        yPos := yStart + ((A_Index - 1) * ySpacing)
        CardGUI.Add("Text", Format("x38 y{} w30 h17 +0x200 cWhite", yPos + 3), A_Index)
        dropDown := CardGUI.Add("DropDownList", Format("x60 y{} w135", yPos), config["options"])
        dropDowns.Push(dropDown)
        AttachDropDownEvent(dropDown, A_Index, OnDropDownChange)
    }

    groupBoxHeight := yStart + (config["options"].Length * ySpacing - 15)

    CardGUI.Add("GroupBox", Format("x30 y25 w190 h{} cWhite +Center", groupBoxHeight), "Modifier Priority Order")

    return CardGUI
}


OpenCardPriorityPicker() {
    CardGUI.Show()
}


SelectCardsByMode() {
    if (ModeDropdown.Text = "Halloween Event") {
        return SelectCards("Halloween")
    }
    else if (ModeDropdown.Text = "Boss Rush") {
        return SelectCards("BossRush")
    }
    return false
}

SelectCards(eventName) {
    global cachedCardPriorities

    if (!cachedCardPriorities.Has(eventName)) {
        cardPriorityFile := A_ScriptDir "\Settings\" eventName "CardPriority.txt"
        priorities := Map()

        if (!FileExist(cardPriorityFile)) {
            AddToLog("Error: " eventName "CardPriority.txt not found.")
            return false
        }

        loop read, cardPriorityFile {
            line := Trim(A_LoopReadLine)
            if (line = "" || SubStr(line, 1, 1) = ";")
                continue

            parts := StrSplit(line, "=")
            if (parts.Length = 2) {
                cardName := Trim(parts[1])
                priority := Integer(Trim(parts[2]))
                if (priority > 0)
                    priorities[cardName] := priority
            }
        }

        if (priorities.Count = 0) {
            AddToLog("No card priorities set in " eventName "CardPriority.txt.")
            return false
        }

        cachedCardPriorities[eventName] := priorities
    }

    cardPriorities := cachedCardPriorities[eventName]

    ; Default card slots 571, 219, 701, 246
    cardSlots:= [
        { clickX: 169, clickY: 305, ocrX1: 100, ocrY1: 214, ocrX2: 238, ocrY2: 257 },
        { clickX: 328, clickY: 288, ocrX1: 256, ocrY1: 214, ocrX2: 394, ocrY2: 256 },
        { clickX: 486, clickY: 291, ocrX1: 410, ocrY1: 224, ocrX2: 550, ocrY2: 271 },
        { clickX: 642, clickY: 295, ocrX1: 571, ocrY1: 224, ocrX2: 701, ocrY2: 256 }
    ]

    foundCards := Map()
    for index, slot in cardSlots {
        MouseMove(slot.clickX, slot.clickY)
        Wiggle()
        ;FixClick(slot.clickX, slot.clickY)
        Sleep(500)

        ; OCR
        orcResult := OCRFromFile(slot.ocrX1, slot.ocrY1, slot.ocrX2, slot.ocrY2, 10.0, true)
        ocrCleaned := RegExReplace(orcResult, "\\s+|!", "")
        ocrCleaned := RegExReplace(ocrCleaned, "[^a-zA-Z]", "")
        ocrCleaned := RegExReplace(ocrCleaned, "i)(IV|III|II|I)$", "")

        ;ocrCleaned := DetectText(slot.ocrX1, slot.ocrY1, slot.ocrX2, slot.ocrY2) ; Alternative OCR method that works better with no image preprocessing might use elsewhere

        if (ocrCleaned != "") {
            for cardName, priority in cardPriorities {
                matchScore := 1.0 - (Levenshtein(ocrCleaned, cardName) / Max(StrLen(ocrCleaned), StrLen(cardName)))
                if (matchScore >= 0.5) {  ; Accept matches with at least 50% similarity
                    foundCards[cardName] := { slot: slot, priority: priority }
                    AddToLog("Found card '" cardName "' with priority " priority)
                    if (debugMessages) {
                        AddToLog("Exact or close match: OCR='" ocrCleaned "' matched with '" cardName)
                    }
                    break
                }
            }
        }
        Sleep(50)
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
            Sleep(300)
            FixClick(400, 395)
            return true
        }
    }

    AddToLog("No cards found...")

    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
    }
    return false
}


OCRFromFile(x1, y1, x2, y2, scale, keepImage := false) {
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
        dir := A_ScriptDir "\Images\"
        fullPath := dir filename ".png"

        if (keepImage) {
            index := 1
            while FileExist(fullPath) {
                fullPath := dir filename "-" index ".png"
                index++
            }
        } else {
            if FileExist(fullPath)
                FileDelete(fullPath)
        }

        Gdip_SaveBitmapToFile(pScaled, fullPath, 100)
        
        ; Wait up to 500ms for file to be ready
        Loop 10 {
            if FileExist(fullPath)
                break
            Sleep 50
        }

        if !FileExist(fullPath) {
            AddToLog("Failed to save OCR image")
            return ""
        }

        result := OCR.FromFile(fullPath, true)
        Sleep 100

        Gdip_DeleteGraphics(g)
        Gdip_DisposeImage(pBitmap)
        Gdip_DisposeImage(pScaled)
        Gdip_Shutdown(pToken)

        ; Only delete if keepImage is false
        if !keepImage && FileExist(fullPath)
            FileDelete(fullPath)

        if IsObject(result) && result.Text {
            finalText := RegExReplace(result.Text, "\s+", "")
            return finalText
        }
        return ""
    } catch as err {
        AddToLog("OCR Error: " err.Message)
        return ""
    }
}

SaveNewCardConfigToFile(filePath) {
    global priorityOrder

    if !DirExist("Settings")
        DirCreate("Settings")

    file := FileOpen(filePath, "w", "UTF-8")
    if !file {
        AddToLog("Failed to save card configuration.")
        return
    }

    file.WriteLine("[CardPriority]")

    for index, card in priorityOrder {
        if card != ""
            file.WriteLine(Format("{}={}", card, index))
    }

    file.Close()

    if (debugMessages)
        AddToLog("Card configuration saved to: " filePath)
}



LoadNewCardConfigFromFile(filePath) {
    global dropDowns, currentConfig, priorityOrder

    config := currentConfig

    if !FileExist(filePath) {
        AddToLog("No configuration file found for this mode. Creating new one.")
        priorityOrder := config["options"].Clone()
        SaveNewCardConfigToFile(filePath)
        return
    }

    ; Initialize priorityOrder with blank slots
    priorityOrder := []
    Loop dropDowns.Length
        priorityOrder.Push("")

    file := FileOpen(filePath, "r", "UTF-8")
    if !file {
        AddToLog("Failed to open config file for reading.")
        return
    }

    section := ""
    while !file.AtEOF {
        line := file.ReadLine()

        if RegExMatch(line, "^\[(.*)\]$", &match) {
            section := match.1
            continue
        }

        if (section = "CardPriority") {
            if RegExMatch(line, "^(.+)=(\d+)$", &match) {
                card := match.1
                slot := match.2 + 0

                if (slot >= 1 && slot <= dropDowns.Length && ArrayHasValue(config["options"], card)) {
                    dropDowns[slot].Text := card
                    priorityOrder[slot] := card
                }
            }
        }
    }

    file.Close()

    if (debugMessages) {
        AddToLog("Card configuration loaded from: " filePath)
    }
}

SwitchCardMode(newMode) {
    global currentCardMode := newMode
    global currentConfig := CardModeConfigs[newMode]

    if CardGUI {
        CardGUI.Destroy()
    }

    CreateCardPriorityGui(currentConfig)

    if FileExist(currentConfig["filePath"]) {
        LoadNewCardConfigFromFile(currentConfig["filePath"])
    } else {
        priorityOrder := currentConfig["options"].Clone()
        SaveNewCardConfigToFile(currentConfig["filePath"])
    }
    OpenCardPriorityPicker()
}


SaveAllConfigs() {
    global CardModeConfigs

    for modeName, config in CardModeConfigs {
        directory := "Settings"
        if !DirExist(directory)
            DirCreate(directory)

        file := FileOpen(config["filePath"], "w")
        if !file {
            AddToLog("Failed to save config for " modeName)
            continue
        }

        file.WriteLine("[CardPriority]")
        for index, cardName in config["options"] {
            file.WriteLine(Format("{}={}", cardName, index))
        }
        file.Close()
    }
}

LoadAllCardConfig() {
    global CardModeConfigs

    for modeName, config in CardModeConfigs {
        filePath := currentConfig["filePath"]

        if !FileExist(filePath) {
            ; No config file yet, keep default options
            continue
        }

        file := FileOpen(filePath, "r")
        if !file {
            MsgBox("Failed to open config file for " modeName)
            continue
        }

        local loadedOptions := []
        section := ""

        while !file.AtEOF {
            line := Trim(file.ReadLine())

            ; Skip empty lines or comments
            if (line = "" || SubStr(line, 1, 1) = ";")
                continue

            if RegExMatch(line, "^\[(.*)\]$", &match) {
                section := match.1
                continue
            }

            if (section = "CardPriority") {
                if RegExMatch(line, "(.+?)=(\d+)", &match) {
                    cardName := match.1
                    ; index := match.2  ; Not really needed here, we keep order by file lines
                    loadedOptions.Push(cardName)
                }
            }
        }

        file.Close()

        if (loadedOptions.Length > 0) {
            ; Replace the options list with loaded one
            currentConfig["options"] := loadedOptions
        }
    }
}

; === Helper Functions ===

OnDropDownChange(ctrl, index) {
    if (index >= 0 and index <= 19) {
        newPriority := ctrl.Text
        for i, dropdown in dropDowns {
            if (i != index && dropdown.Text = newPriority) {
                AddToLog(Format("{} already exists for priority {}, don't forget to change it!", newPriority, i))
                break
            }
        }
        currentConfig["options"][index] := newPriority
        AddToLog(Format("Priority {} set to {}", index, newPriority))
        RemoveEmptyStrings(priorityOrder)
        SaveNewCardConfigToFile(currentConfig["filePath"])
    } else {
        if (debugMessages) {
            AddToLog(Format("Invalid index {} for dropdown", index))
        }
    }
}

AttachDropDownEvent(dropDown, index, callback) {
    dropDown.OnEvent("Change", (*) => callback(dropDown, index))
}

RemoveEmptyStrings(array) {
    loop array.Length {
        i := array.Length - A_Index + 1
        if (array[i] = "") {
            array.RemoveAt(i)
        }
    }
}

Levenshtein(s1, s2) { ; Used to compare OCR results to card names
    len1 := StrLen(s1)
    len2 := StrLen(s2)

    ; Create a 2D array (1-based)
    matrix := []

    ; Initialize matrix
    Loop len1 + 1 {
        matrixRow := []
        Loop len2 + 1 {
            matrixRow.Push(0)
        }
        matrix.Push(matrixRow)
    }

    ; Fill first row and first column
    Loop len1 + 1
        matrix[A_Index][1] := A_Index - 1
    Loop len2 + 1
        matrix[1][A_Index] := A_Index - 1

    ; Calculate distances
    Loop len1 {
        i := A_Index
        char1 := SubStr(s1, i, 1)
        Loop len2 {
            j := A_Index
            char2 := SubStr(s2, j, 1)
            cost := (char1 = char2) ? 0 : 1

            above := matrix[i][j + 1]
            left := matrix[i + 1][j]
            diag := matrix[i][j]

            matrix[i + 1][j + 1] := Min(above + 1, left + 1, diag + cost)
        }
    }

    return matrix[len1 + 1][len2 + 1]
}

DetectText(x1, y1, x2, y2) {
    AddToLog("Checking for text...")

    x := x1
    y := y1
    w := x2 - x1
    h := y2 - y1

    try {
        result := OCR.FromRect(x, y, w, h, { grayscale: true, scale: 10.0 })
        
        if result {
            ; Clean the number string
            number := RegExReplace(number, "\\s+|!", "")
            AddToLog("Sending number: " number)
            return number
        }
    } 
    AddToLog("Could not detect any text.")
    return false
}

ArrayHasValue(arr, val) {
    for index, item in arr {
        if (item = val)
            return true
    }
    return false
}