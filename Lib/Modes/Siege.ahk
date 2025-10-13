#Requires AutoHotkey v2.0

SiegeMovement() {
    Teleport("Raid")
    Sleep (1000)
    spawnAngle := DetectAngle("Raid")
    WalkToSiegeRoom(spawnAngle)
    Sleep (1000)
}

WalkToSiegeRoom(angle) {
    switch angle {
        case 2:
            SendInput("{a down}")
            Sleep(800)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
            SendInput("{s down}")
            Sleep(2000)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
        case 1:
            SendInput("{s down}")
            Sleep(1000)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
            SendInput("{d down}")
            Sleep(2000)
            SendInput("{d up}")
            KeyWait "d"  ; Wait for the key to be fully processed
    }
}

SelectSiege() {
    X := 190
    baseY := 190
    spacing := 40

    y := baseY + spacing * (SiegeDropdown.Value - 1)
    FixClick(x, y)
    Sleep(500)
    FixClick(350, 250) ; Click normal mode
    Sleep(500)
    FixClick(405, 415) ; Click "Select Map"
    Sleep(500)
    FixClick(570, 410) ; Click "Start"
    RestartStage()
}