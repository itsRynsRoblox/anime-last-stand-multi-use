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

    ; --- Import/Export Buttons at Bottom ---
    imgY := groupBoxHeight + 40  ; adjust vertical spacing

    importBtn := CardGUI.Add("Picture", Format("x85 y{} w27 h27", imgY), Import)
    exportBtn := CardGUI.Add("Picture", Format("x135 y{} w27 h27", imgY), Export)

    ; Optional: attach click handlers

    importBtn.OnEvent("Click", (*) => ImportCardConfig(config["modeName"]))
    exportBtn.OnEvent("Click", (*) => ExportCardConfig(config["modeName"]))

    return CardGUI
}


OpenCardPriorityPicker() {
    CardGUI.Show()
}


SelectCardsByMode() {
    if (EventDropdown.Text = "Halloween") {
        return SelectCards("Halloween")
    }
    else if (ModeDropdown.Text = "Boss Rush") {
        return SelectCards("BossRush")
    }
    return false
}

SelectCards(eventName) {
    global cachedCardPriorities

    eventName := StrReplace(eventName, " ", "")

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

    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
    }

    SendInput("X") ; Close unit menu

    cardPriorities := cachedCardPriorities[eventName]

    baseX := 169
    baseY := 305
    scale := 1.0


    cardSlots := [
        { clickOffsetX: 0,   clickOffsetY: -15,   ocrOffsetX1: -69, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
        { clickOffsetX: 159, clickOffsetY: -15, ocrOffsetX1: 87,  ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
        { clickOffsetX: 317, clickOffsetY: -15, ocrOffsetX1: 241, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
        { clickOffsetX: 473, clickOffsetY: -15, ocrOffsetX1: 402, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 }
    ]

    for index, slot in cardSlots {
        slot.clickX := baseX + slot.clickOffsetX * scale
        slot.clickY := baseY + slot.clickOffsetY * scale
        slot.ocrX1 := baseX + slot.ocrOffsetX1 * scale
        slot.ocrY1 := baseY + slot.ocrOffsetY1 * scale
        slot.ocrX2 := slot.ocrX1 + slot.ocrWidth * scale
        slot.ocrY2 := slot.ocrY1 + slot.ocrHeight * scale
    }

    foundCards := Map()
    for index, slot in cardSlots {
        MouseMove(slot.clickX, slot.clickY)
        Wiggle()

        ; --- Start adaptive OCR wait ---
        maxAttempts := 3    ; total max time to wait for a card (ms)
        interval := 50    ; check every 50 ms
        attempts := 0
        orcResult := ""
        ocrCleaned := ""

        while (attempts < maxAttempts) {
            orcResult := ReadText(slot.ocrX1, slot.ocrY1, slot.ocrX2, slot.ocrY2, 10.0, false)
            ocrCleaned := RegExReplace(orcResult, "\\s+|!", "")
            ocrCleaned := RegExReplace(ocrCleaned, "[^a-zA-Z]", "")
            ocrCleaned := RegExReplace(ocrCleaned, "i)(IV|III|II|I)$", "")

            if (ocrCleaned != "") {
                break
            }

            Sleep(interval)
            attempts += 1
            AddToLog("Waiting for card... attempt " attempts)
        }
        
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
            if (AutoAbilityBox.Value) {
                SetTimer(CheckAutoAbility, GetAutoAbilityTimer())
            }
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

        result := OCR.FromFile(fullPath, { grayscale: true, monochrome: 255})


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

    allMsg := ""  ; Accumulate messages here

    for modeName, currentConfig in CardModeConfigs {
        filePath := currentConfig["filePath"]

        if !FileExist(filePath) {
            continue
        }

        file := FileOpen(filePath, "r")
        if !file {
            allMsg .= "Failed to open config file for " modeName "`n"
            continue
        }

        local loadedOptions := []  ; Will store objects {name:, priority:}
        section := ""

        while !file.AtEOF {
            line := Trim(file.ReadLine())

            if (line = "" || SubStr(line, 1, 1) = ";")
                continue

            if RegExMatch(line, "^\[(.*)\]$", &match) {
                section := match.1
                continue
            }

            if (section = "CardPriority") {
                if RegExMatch(line, "(.+?)=(\d+)", &match) {
                    cardName := match.1
                    priority := match.2 + 0
                    loadedOptions.Push({ name: cardName, priority: priority })
                    allMsg .= modeName " - Card: " cardName " | Priority: " priority "`n"
                }
            }
        }

        file.Close()

        if (loadedOptions.Length > 0) {
            ; Manual sort by priority
            for i, outer in loadedOptions {
                for j, inner in loadedOptions {
                    if (i < j && outer.priority > inner.priority) {
                        temp := loadedOptions[i]
                        loadedOptions[i] := loadedOptions[j]
                        loadedOptions[j] := temp
                    }
                }
            }

            ; Extract just the names in sorted order
            namesSorted := []
            for card in loadedOptions
                namesSorted.Push(card.name)

            currentConfig["options"] := namesSorted
        }
    }

    ; Show all cards and priorities at once
    if (allMsg != "" && debugMessages)
        MsgBox(allMsg, "Loaded Card Priorities")
}

; === Helper Functions ===

OnDropDownChange(ctrl, index) {
    if (index >= 0 && index <= dropDowns.Length) {
        newPriority := ctrl.Text
        used := Map()
        originalOptions := currentConfig["options"].Clone()

        ; First, collect all selected options (after change)
        for i, dropdown in dropDowns {
            if (i == index) {
                used[newPriority] := i  ; new value just selected
            } else {
                used[dropdown.Text] := i
            }
        }

        ; Find missing option(s)
        missing := []
        for _, opt in originalOptions {
            if !used.Has(opt) {
                missing.Push(opt)
            }
        }

        ; Check for duplicates and fix them
        for i, dropdown in dropDowns {
            if (i != index && dropdown.Text = newPriority) {
                if (missing.Length > 0) {
                    replacement := missing.Pop()
                    dropdown.Text := replacement
                    if (debugMessages) {
                        AddToLog(Format("Card '{}' replaced with '{}'", newPriority, replacement))
                    }
                } else {
                    AddToLog("Warning: No available replacement for duplicate value.")
                }
            }
        }

        ; Update options based on new dropdown states
        for i, dropdown in dropDowns {
            currentConfig["options"][i] := dropdown.Text
        }

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

ExportCardConfig(modeName) {
    global CardModeConfigs, dropDowns

    config := CardModeConfigs[modeName]

    modeName := StrReplace(config["title"], " ", "")


    if !config {
        AddToLog("❌ No card config found for mode: " modeName)
        return
    }

    exportDir := A_ScriptDir "\Settings\Export"
    if !DirExist(exportDir)
        DirCreate(exportDir)

    filePath := exportDir "\" modeName ".txt"

    try {
        if FileExist(filePath)
            FileDelete(filePath)

        ; Write the card priority in [CardPriority] section
        cardData := "[CardPriority]`n"

        for index, dd in dropDowns {
            selected := dd.Text
            if selected != ""
                cardData .= selected "=" index "`n"
        }

        FileAppend(cardData, filePath)
        AddToLog("✅ Card config successfully exported!")
    } catch {
        AddToLog("❌ Failed to export card config")
    }
}

ImportCardConfig(modeName) {
    global CardModeConfigs, dropDowns

    config := CardModeConfigs[modeName]
    if !config {
        AddToLog("❌ No config found for mode: " modeName)
        return
    }

    ; Disable AlwaysOnTop temporarily for file dialog
    MainUI.Opt("-AlwaysOnTop")
    Sleep(100)

    selectedFile := FileSelect(3, , "Select a card config file to import", "Text Documents (*.txt)")

    MainUI.Opt("+AlwaysOnTop")

    if !selectedFile {
        AddToLog("⚠️ Import cancelled by user.")
        return
    }

    ; Read selected file
    content := FileRead(selectedFile)
    lines := StrSplit(content, "`n")

    loadedOptions := []
    section := ""

    for line in lines {
        line := Trim(line)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue

        if RegExMatch(line, "^\[(.*)\]$", &match) {
            section := match.1
            continue
        }

        if (section = "CardPriority") {
            if RegExMatch(line, "(.+?)=(\d+)", &match) {
                cardName := match.1
                loadedOptions.Push(cardName)
            }
        }
    }

    if (loadedOptions.Length = 0) {
        AddToLog("⚠️ No valid card data found in file.")
        return
    }

    ; Overwrite the existing file for this mode
    targetFile := A_ScriptDir "\" config["filePath"]

    try {
        if FileExist(targetFile) {
            FileDelete(targetFile)
        }
    } catch as e {
        AddToLog("❌ Failed to delete file: " targetFile "`nError: " e.Message)
    }

    try {
        FileAppend("[CardPriority]`n", targetFile)
        for index, name in loadedOptions {
            FileAppend(name "=" index "`n", targetFile)
        }

        config["options"] := loadedOptions
        AddToLog("✅ Imported and replaced card config for mode: " modeName)
        SaveNewCardConfigToFile(modeName)

        ; Update all the dropdowns
        for index, dd in dropDowns {
            dd.Text := loadedOptions[index]
        }
    } catch as e {
        AddToLog("❌ Failed to write new card config: " e.Message)
    }
}

ExportAllCardConfigs() {
    global CardModeConfigs

    for modeName, config in CardModeConfigs {
        ExportCardConfig(modeName)
    }
}

HasCards(ModeName) {
    ; Array of modes that have card selection
    static modesWithCards := ["Boss Rush", "Halloween", "Halloween P2"]

    ; Check if current mode is in the array
    for mode in modesWithCards {
        if (mode = ModeName)
            return true
    }
    return false
}

GetCardSlotsByWave(wave) {
    wave := Integer(wave)
    baseX := 169
    baseY := 305
    scale := 1.0

    if (wave <= 10) {
        ; Early waves — 4 cards
        cardSlots := [
            { clickOffsetX: 0,   clickOffsetY: -15,   ocrOffsetX1: -69, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
            { clickOffsetX: 159, clickOffsetY: -15, ocrOffsetX1: 87,  ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
            { clickOffsetX: 317, clickOffsetY: -15, ocrOffsetX1: 241, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
            { clickOffsetX: 473, clickOffsetY: -15, ocrOffsetX1: 402, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 }
        ]
    }
    else if (wave <= 40) {
        ; Mid waves — 3 cards (shifted slightly toward center)
        baseX := 200
        cardSlots := [
            { clickOffsetX: 0,   clickOffsetY: -15,   ocrOffsetX1: -69, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
            { clickOffsetX: 159, clickOffsetY: -15, ocrOffsetX1: 100,  ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 },
            { clickOffsetX: 317, clickOffsetY: -15, ocrOffsetX1: 300, ocrOffsetY1: -91, ocrWidth: 140, ocrHeight: 50 }
        ]
    }
    else if (wave <= 50) {
        ; Late waves — only 2 cards (further centered)
        baseX := 240
        cardSlots := [
            { clickOffsetX: 0,   clickOffsetY: 0,   ocrOffsetX1: -70, ocrOffsetY1: -91, ocrWidth: 138, ocrHeight: 50 },
            { clickOffsetX: 265, clickOffsetY: -10, ocrOffsetX1: 200, ocrOffsetY1: -91, ocrWidth: 138, ocrHeight: 50 }
        ]
    }

    ; Calculate actual positions
    for index, slot in cardSlots {
        slot.clickX := baseX + slot.clickOffsetX * scale
        slot.clickY := baseY + slot.clickOffsetY * scale
        slot.ocrX1 := baseX + slot.ocrOffsetX1 * scale
        slot.ocrY1 := baseY + slot.ocrOffsetY1 * scale
        slot.ocrX2 := slot.ocrX1 + slot.ocrWidth * scale
        slot.ocrY2 := slot.ocrY1 + slot.ocrHeight * scale
    }
    return cardSlots
}

ShowRegions(cardSlots, showClicks := true) {
    static overlays := []  ; persists between calls

    ; destroy previous overlays
    if IsObject(overlays) {
        for g in overlays
            try g.Destroy()
    }
    overlays := []

    for index, slot in cardSlots {
        w := slot.ocrX2 - slot.ocrX1
        h := slot.ocrY2 - slot.ocrY1

        ; OCR box (red)
        ocrGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; create new Gui
        ocrGui.BackColor := "Red"
        ocrGui.Show("x" slot.ocrX1 " y" slot.ocrY1 " w" w " h" h)
        overlays.Push(ocrGui)

        if showClicks {
            cx := slot.clickX - 6  ; center marker (12x12)
            cy := slot.clickY - 6

            ; Click marker (blue)
            clickGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; <-- correct: Gui(), not ocrGui(...)
            clickGui.BackColor := "Blue"
            clickGui.Show("x" cx " y" cy " w12 h12")
            overlays.Push(clickGui)
        }
    }

    ; store overlays so HideRegions can access them
    ShowRegions._overlays := overlays
}