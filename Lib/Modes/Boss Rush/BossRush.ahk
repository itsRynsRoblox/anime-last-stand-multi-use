#Requires AutoHotkey v2.0

WaitForGilgamesh() {
    Loop {

        if (CheckForXp()) {
            AddToLog("Game over detected")
            break
        }

        if (ok := FindText(&X, &Y, 362, 117, 445, 134, 0, 0.10, Gilgamesh)) {
            AddToLog("Using Cup of Rebirth...")
            loop 15 {
                FixClick(282, 328) ; click nuke
                Sleep(150)
            }
            break
        }
        Sleep 500
    }
}