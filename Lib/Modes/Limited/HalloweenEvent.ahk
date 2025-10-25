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

StartRestartStage() {
    AddToLog("[Info] Restart threshold reached")
    FixClick(233, 10)
    Sleep(1000)
    FixClick(339, 253)
    Sleep(1000)
    FixClick(233, 10)
    sleepTime := SeamlessToggle.Value ? 1000 : 5000
    Sleep(sleepTime)
    RestartStage()
}

EnableSeamless() {
    FixClick(233, 10) ; click settings
    Sleep(1000)
    FixClick(405, 279)
    Sleep(750)
    Scroll(1, "WheelDown", 50)
    Sleep(1000)

    if (!isSeamlessEnabled()) {
        AddToLog("[Info] Enabling Seamless")
        FixClick(493, 393)
    } else {
        AddToLog("[Info] Seamless already enabled")
    }
    Sleep(1000)
    FixClick(233, 10) ; close settings
}

isSeamlessEnabled() {
    return GetPixel(0x7CC021, 506, 392, 1, 1, 10)
}

CheckShouldRestart() {
    global stageStartTime
    if (EventDropdown.Text = "Halloween P2" && HalloweenRestart.Value) {
        if (TimerManager.HasExpired("RestartStage")) {

            stageEndTime := A_TickCount
            stageLength := FormatStageTime(stageEndTime - stageStartTime)

            if (WebhookEnabled.Value) {
                try {
                    SendWebhookWithTime(true, stageLength)
                } catch {
                    AddToLog("Error: Unable to send webhook.")
                }
            } else {
                UpdateStreak(true)
            }
            AddToLog("[Info] Restarting stage")
            FixClick(233, 10)
            Sleep(1000)
            FixClick(339, 253)
            Sleep(1000)
            FixClick(233, 10)
            sleepTime := SeamlessToggle.Value ? 1000 : 5000
            Sleep(sleepTime)
            return RestartStage()
        }
    }
}