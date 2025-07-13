#Requires AutoHotkey v2.0

DungeonMode() {
    AddToLog("Starting Dungeon Mode")
    RestartStage()
}

HandleDungeonEnd() {
    AddToLog("Handling Dungeon end")
    ClickReplay()
    return RestartStage()
}

WalkToDungeonRoom(angle) {
    switch angle {
    case 1:
        SendInput("{d down}")
        Sleep(800)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
    case 2:
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
        SendInput("{a down}")
        Sleep(2000)
        SendInput("{a up}")
        KeyWait "a"  ; Wait for the key to be fully processed    
    }
}

Dungeon() {
    
    ; Get current map and act
    dungeonMap := DungeonDropdown.Text
        
    ; Execute the movement pattern
    AddToLog("Moving to position for " dungeonMap)
    DungeonMovement()
    
    ; Start stage
    while !(ok:=FindText(&X, &Y, 262, 443, 351, 465, 0, 0, DungeonSelectButton)) {
        DungeonMovement()
    }

    AddToLog("Starting " dungeonMap)
    StartDungeon(dungeonMap)

    ; Handle play mode selection
    PlayHere("Dungeon")
    RestartStage()
}

StartDungeon(map) {
    AddToLog("Selecting dungeon: " map)

    ; Get Story map 
    Dungeon := GetDungeons(map)
    if (!Dungeon) {
        AddToLog("Error: Dungeon '" map "' not found. Please tell Ryn")
        return false
    }
    
    ; Scroll if needed
    if (Dungeon.scrolls > 0) {
        AddToLog("Scrolling down " Dungeon.scrolls " for " map)
        MouseMove(150, 190)
        SendInput("{WheelDown}")
        Sleep(250)
    }

    Sleep(1000)
    FixClick(Dungeon.x, Dungeon.y)
    Sleep(1000)
    return true
}

GetDungeons(map) {
    switch map {
        case "Devil's Dungeon": return {x: 210, y: 175, scrolls: 0}
        case "Infernal Dungeon": return {x: 310, y: 175, scrolls: 0}
        case "Monarch's Dungeon": return {x: 415, y: 175, scrolls: 0}
    }
}

DungeonMovement() {
    Teleport("Raid")

    ; Get the angle for the dungeon room
    angle := DetectAngle("Raid")
    
    ; Walk to the dungeon room based on the angle
    WalkToDungeonRoom(angle)
    Sleep(1000)  ; Wait for the movement to complete
}