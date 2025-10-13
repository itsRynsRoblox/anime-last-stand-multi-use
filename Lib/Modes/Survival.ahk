#Requires AutoHotkey v2.0

StartSurvivalMode() {
    while !(ok := isMenuOpen("Survival")) {
        Teleport("Raid")
        Sleep (1000)
        spawnAngle := DetectAngle("Raid")
        WalkToSurvivalRoom(spawnAngle)
        Sleep (1000)
    }
    AddToLog("Starting Survival")
    SelectSurvival()
}

WalkToSurvivalRoom(angle) {
    switch angle {
    case 2:
        SendInput("{d down}")
        Sleep(800)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed
        SendInput("{s down}")
        Sleep(800)
        SendInput("{s up}")
        KeyWait "s"  ; Wait for the key to be fully processed
    case 1:
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
        SendInput("{d down}")
        Sleep(2000)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed    
    }
}

SelectSurvival() {
    baseX := 200
    Y := 175
    spacing := 70

    x := baseX + spacing * (SurvivalDropdown.Value - 1)
    FixClick(x, y)
    Sleep(500)
    FixClick(300, 415) ; Click "Enter"
    Sleep(500)
    FixClick(570, 410) ; Click "Start"
    RestartStage()
}