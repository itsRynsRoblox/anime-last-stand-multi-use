#Requires AutoHotkey v2.0

StartPortalMode() {
    StartPortal()
    RestartStage()
}

HandlePortalEnd(isVictory := true) {
    if (PortalRoleDropdown.Text = "Host") {
        if (isVictory) {
            AddToLog(PortalDropdown.Text " Portal completed successfully, starting next portal...")
            StartNextPortal()
        } else {
            if (FindText(&X, &Y, 238, 400, 566, 445, 0, 0, Retry)) {
                ClickReplay()
                AddToLog(PortalDropdown.Text " Portal failed, retrying...")
            } else {
                AddToLog(PortalDropdown.Text " Portal failed, starting next portal...")
                Sleep(1000)
                StartNextPortal()
                if (!SeamlessToggle.Value) {
                    Sleep (2500) ; Wait for the portal to start
                }
            }
        }
    } else {
        WaitForRestart()
    }
    return RestartStage()
}

StartNextPortal() {
    FixClick(387, 398) ; View Portal
    Sleep(500)
    FixClick(255, 173) ; Search bar
    Sleep(500)
    SendInput(PortalDropdown.Text) ; Type the selected portal
    Sleep(500)
    FixClick(242, 232) ; Click on the portal
    Sleep(500)
    FixClick(632, 469) ; Enter the portal
    Sleep(500)
    FixClick(354, 323) ; Start the portal
    Sleep(500)
}

WaitForRestart() {
    AddToLog("Waiting for host to start next portal")
    Loop {
        Sleep(500)
        if (!isMenuOpen("End Screen")) {
            break
        }
    }
}

IsValidPortal() {
    Sleep(1000)  ; Allow UI to fully update

    ; === Map Detection ===
    detectedMap := DetectMapForPortal()
    if (!detectedMap) {
        return false
    }

    if (ShouldSkipMap(detectedMap)) {
        return false
    }

    AddToLog("✅ Valid Portal: Map = '" detectedMap "'")
    return true
}

DetectMapForPortal() {
    mapPatterns := Map(
        "Summer Laguna", SummerLaguna
    )

    for mapName, pattern in mapPatterns {
        if (ok := FindText(&X, &Y, 549, 230, 628, 249, 0, 0, pattern)) {
            return mapName
        }
    }
    return ""
}

ShouldSkipMap(portalName := "") {
    static portalMap := Map(
        "Summer Laguna", "Summer Laguna"
    )

    selectedMap := PortalDropdown.Text

    if !portalMap.Has(selectedMap)
        return false

    return portalName != portalMap[selectedMap]
}

StartPortal() {
    if (PortalRoleDropdown.Text = "Host") {
        if (PortalLobby.Value) {
            FixClick(88, 288) ; Open Inventory
            Sleep (500)
            FixClick(135, 201) ; Click on the Portal Selection
            Sleep (500)
            FixClick(245, 174) ; Search bar
            Sleep (500)
            SendInput(PortalDropdown.Text) ; Type the selected portal
            Sleep (500)

            ; Try each portal in order
            for index, portal in [1, 2, 3, 4, 5] {
                SelectPortal(portal)
                Sleep(500)

                AddToLog("✅ Portal " . portal . " selected successfully.")
                FixClick(620, 470) ; Spawn Portal
                Sleep (500)
                FixClick(69, 398) ; Start Portal
                Sleep (2500)
                return true ; Success, exit early

                /*AddToLog("Checking portal " . portal . "...")

                if (IsValidPortal()) {
                    AddToLog("✅ Portal " . portal . " selected successfully.")
                    FixClick(620, 470) ; Spawn Portal
                    Sleep (500)
                    FixClick(69, 398) ; Start Portal
                    Sleep (2500)
                    return true ; Success, exit early
                } else {
                    AddToLog("❌ Portal " . portal . " is not valid. Trying next...")
                } */
            }

            AddToLog("🚫 No valid portals found.")
            return false
        }
    }
}

SelectPortal(portal := 0) {
    coords := GetPortalCoords(portal)
    FixClick(coords.x, coords.y)
}

GetPortalCoords(portal) {
    coordMap := Map(
        1, {x: 240, y: 235},
        2, {x: 305, y: 235},
        3, {x: 365, y: 235},
        4, {x: 430, y: 235},
        5, {x: 490, y: 235},
    )
    return coordMap.Has(portal) ? coordMap[portal] : coordMap[0]
}