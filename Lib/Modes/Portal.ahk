#Requires AutoHotkey v2.0

PortalMode() {
    FixClick(88, 288)
    Sleep (500)
    FixClick(135, 201) ; Click on the Portal Selection
    Sleep (500)
    FixClick(245, 174) ; Search bar
    Sleep (500)
    SendInput(PortalDropdown.Text) ; Type the selected portal
    Sleep (500)
    FixClick(242, 232) ; Click on the portal
    Sleep (500)
    FixClick(620, 470) ; Spawn Portal
    Sleep (500)
    FixClick(69, 398) ; Start Portal
    Sleep (2500)
    RestartStage()
}

HandlePortalEnd(isVictory := true) {
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