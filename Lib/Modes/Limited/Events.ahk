#Requires AutoHotkey v2.0

StartEvent() {
    switch (EventDropdown.Text) {
        case "Halloween":
            StartHalloweenEvent()
        case "Halloween P2":
            StartHalloweenEvent(true)
    }
}