#Requires AutoHotkey v2.0

StartRaidMode() {

    ; Get current map and act
    currentRaidMap := RaidDropdown.Text
    currentRaidAct := RaidActDropdown.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentRaidMap)
    RaidMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 351, 435, 454, 455, 0, 0, RaidSelectButton)) {
        RaidMovement()
    }

    AddToLog("Starting " currentRaidMap " - " currentRaidAct)
    StartRaid(currentRaidMap, currentRaidAct)
    ; Handle play mode selection
    PlayHere("Raid")
    RestartStage()
}

StartRaid(map, act) {
    return StartContent(map, act, GetRaidMap, GetRaidAct, { x: 195, y: 185 }, { x: 195, y: 185 })
}

RaidMovement() {
    Teleport("Raid")
    Sleep (1000)
    spawnAngle := DetectAngle("Raid")
    WalkToRaidRoom(spawnAngle)
    Sleep (1000)
}

WalkToRaidRoom(angle) {
    switch angle {
        case 2:
            SendInput("{a down}")
            Sleep(800)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
            SendInput("{w down}")
            Sleep(2000)
            SendInput("{w up}")
            KeyWait "w"  ; Wait for the key to be fully processed
        case 1:
            SendInput("{s down}")
            Sleep(800)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
            SendInput("{a down}")
            Sleep(2000)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
    }
}

GetRaidMap(map) {
    switch map {
        case "Marines Fort": return { x: 185, y: 185, scrolls: 0 }
        case "Hell City": return { x: 185, y: 225, scrolls: 0 }
        case "Snowy Capital": return { x: 185, y: 260, scrolls: 0 }
        case "Leaf Village": return { x: 185, y: 295, scrolls: 0 }
        case "Wanderniech": return { x: 185, y: 335, scrolls: 0 }
        case "Central City": return { x: 185, y: 370, scrolls: 0 }
        case "Giants District": return { x: 185, y: 265, scrolls: 1 }
        case "Flying Island": return { x: 185, y: 305, scrolls: 1 }
        case "U-18": return { x: 185, y: 340, scrolls: 1 }
        case "Flower Garden": return { x: 185, y: 375, scrolls: 1 }
        case "Ancient Dungeon": return { x: 185, y: 275, scrolls: 2 }
        case "Shinjuku Crater": return { x: 185, y: 315, scrolls: 2 }
        case "Valhalla Arena": return { x: 185, y: 350, scrolls: 2 }
        case "Frozen Planet": return { x: 185, y: 380, scrolls: 2 }
        case "Blossom Church": return { x: 185, y: 295, scrolls: 3 }
        case "Science Sanctuary": return { x: 185, y: 335, scrolls: 3 }
        case "Menos Forest": return { x: 185, y: 370, scrolls: 3 }
    }
}

GetRaidAct(act) {
    baseY := 185
    spacing := 30
    x := 270

    ; Extract the act number from the string, e.g., "Act 3" → 3
    if RegExMatch(act, "Act\s*(\d+)", &match) {
        actNumber := match[1]
        y := baseY + spacing * (actNumber - 1)
        return { x: x, y: y, scrolls: 0 }
    }

    ; Default return if the input doesn't match expected format
    return { x: x, y: baseY, scrolls: 0 }
}