#Requires AutoHotkey v2.0

StartBossRush() {
    while !(ok := isMenuOpen("Boss Rush")) {
        Teleport("Raid")
        Sleep (1000)
        spawnAngle := DetectAngle("Raid")
        WalkToBossRush(spawnAngle)
        Sleep (1000)
    }
    AddToLog("Starting Boss Rush")
    SelectBossRush()
}

WalkToBossRush(angle) {
    switch angle {
        case 2:
            SendInput("{d down}")
            Sleep(1200)
            SendInput("{d up}")
            KeyWait "d"  ; Wait for the key to be fully processed
            SendInput("{s down}")
            Sleep(800)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
        case 1:
            SendInput("{s down}")
            Sleep(1350)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
            SendInput("{a down}")
            Sleep(900)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
    }
}

SelectBossRush() {
    baseX := 202
    Y := 185
    spacing := 90

    x := baseX + spacing * (BossRushDropdown.Value - 1)
    FixClick(x, y)
    Sleep(250)
    FixClick(350, 415) ; Click "Enter"
    RestartStage()
}