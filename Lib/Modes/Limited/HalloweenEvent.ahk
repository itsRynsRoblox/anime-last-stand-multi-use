#Requires AutoHotkey v2.0

StartHalloweenEvent(isPart2 := false) {
    FixClick(61, 448) ; Click "Halloween Event"
    Sleep 1000
    FixClick(348, 163) ; Click "Mode"
    Sleep (1000)
    if (isPart2) {
        FixClick(255, 195) ; Click "Part 2"
        Sleep(1000)
    }
    FixClick(400, 428) ; Click "Enter"
    Sleep (1000)
    FixClick(571, 408) ; Click "Start"
    while (isInLobby()) {
        Sleep(100)
    }
    AddToLog("[Info] Waiting to load into the game...")
    RestartStage()
}

WalkToHalloweenPath() {
    Walk("W", 9000)
    Walk("d", 500)
    Walk("w", 2000)
    Walk("d", 3500)
}