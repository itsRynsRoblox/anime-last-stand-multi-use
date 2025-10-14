#Requires AutoHotkey v2.0

StartHalloweenEvent() {
    FixClick(61, 448) ; Click "Halloween Event"
    Sleep 1000
    FixClick(348, 163) ; Click "Mode"
    Sleep (1000)
    FixClick(400, 428) ; Click "Enter"
    Sleep (1000)
    FixClick(571, 408) ; Click "Start"
    Sleep (1000)
    RestartStage()
}