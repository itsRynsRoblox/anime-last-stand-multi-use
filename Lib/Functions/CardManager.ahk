#Requires AutoHotkey v2.0

SelectCardsByMode() {
    if (ModeDropdown.Text = "Halloween Event") {
        return SelectCards("Halloween")
    }
    return false
}

SelectCards(eventName) {
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, 0) ; Pause auto ability checks
    }

    AddToLog("[" eventName "] Selecting card...")

    ; Load card priorities from file
    cardPriorityFile := A_ScriptDir "\Settings\" eventName "CardPriority.txt"

    cardPriorities := Map()

    if (!FileExist(cardPriorityFile)) {
        AddToLog("Error: " eventName "CardPriority.txt not found.")
        return false
    }

    try {
        loop read, cardPriorityFile {
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
        AddToLog("Error reading " eventName "CardPriority.txt: " e.Message)
        return false
    }

    if (cardPriorities.Count = 0) {
        AddToLog("No card priorities set in " eventName "CardPriority.txt. Cannot proceed.")
        return false
    }

    ; Default card slots
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

        if (ocrCleaned != "") {
            for cardName, priority in cardPriorities {
                matchScore := 1.0 - (Levenshtein(ocrCleaned, cardName) / Max(StrLen(ocrCleaned), StrLen(cardName)))
                if (matchScore >= 0.8) {
                    foundCards[cardName] := { slot: slot, priority: priority }
                    AddToLog("Found card '" cardName "' with priority " priority)
                    if (debugMessages) {
                        AddToLog("Exact or close match: OCR='" ocrCleaned "' matched with '" cardName)
                    }
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
            FixClick(400, 395) ; Confirm selection
            return true
        }
    }

    AddToLog("No cards found...")
    
    if (AutoAbilityBox.Value) {
        SetTimer(CheckAutoAbility, GetAutoAbilityTimer()) ; Resume auto ability checks
    }
    return false
}

OcrBetterNew(x1, y1, x2, y2, scale, debug := false) {
    try {
        WinGetPos(&winX, &winY, , , "ahk_exe RobloxPlayerBeta.exe")
        x1 += winX, y1 += winY, x2 += winX, y2 += winY

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

        filename := "OCR_" A_TickCount ".png"
        fullPath := A_ScriptDir "\Images\" filename

        Gdip_SaveBitmapToFile(pScaled, fullPath, 100)
        Sleep 100

        result := ""
        if FileExist(fullPath) {
            result := OCR.ocr_from_file(fullPath, , true)
            Sleep 100
            FileDelete(fullPath)
        } else {
            AddToLog("Failed to save OCR image")
        }

        if debug {
            logText := "No result returned or result is empty"
            if IsObject(result) && result.Length > 0 {
                combined := ""
                for block in result {
                    cleaned := RegExReplace(block.text, "\s+", "")
                    combined .= cleaned
                }
                logText := (combined != "") ? "Found text: " combined : "No text found in result"
            }
            AddToLog(logText)
        }

        if IsObject(result) && result.Length > 0 {
            finalText := ""
            for block in result {
                finalText .= RegExReplace(block.text, "\s+", "")
            }
            return finalText
        }

        return ""
    } catch as err {
        AddToLog("OCR Error: " err.Message)
        return ""
    } finally {
        ; Cleanup
        if IsSet(g)
            Gdip_DeleteGraphics(g)
        if IsSet(pBitmap)
            Gdip_DisposeImage(pBitmap)
        if IsSet(pScaled)
            Gdip_DisposeImage(pScaled)
        if IsSet(pToken)
            Gdip_Shutdown(pToken)
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

; === Helper Functions ===
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