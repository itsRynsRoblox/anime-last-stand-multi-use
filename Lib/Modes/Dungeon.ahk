#Requires AutoHotkey v2.0

StartDungeonMode() {
    while !(ok := FindText(&X, &Y, 262, 443, 351, 465, 0, 0, DungeonSelectButton)) {
        Teleport("Raid")
        Sleep (1000)
        spawnAngle := DetectAngle("Raid")
        WalkToDungeonRoom(spawnAngle)
        Sleep (1000)
    }
    AddToLog("Starting " DungeonDropdown.Text)
    SelectDungeon()
}

WalkToDungeonRoom(angle) {
    switch angle {
    case 1:
        SendInput("{d down}")
        Sleep(800)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed
        SendInput("{w down}")
        Sleep(2000)
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

SelectDungeon() {
    baseX := 200
    Y := 175
    spacing := 70

    x := baseX + spacing * (DungeonDropdown.Value - 1)
    FixClick(x, y)
    Sleep(500)
    FixClick(300, 415) ; Click "Enter"
    Sleep(500)
    FixClick(570, 410) ; Click "Start"
    RestartStage()
}