#Requires AutoHotkey v2.0

DungeonMode() {
    AddToLog("Starting Dungeon Mode")
    RestartStage()
}

HandleDungeonEnd() {
    AddToLog("Handling Dungeon end")
    ClickReplay()
    return RestartStage()
}

RestartDungeon() {

    ; Wait for loading
    CheckLoaded()

    ; Do initial setup and map-specific movement during vote timer
    BasicSetup()

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    PlacingUnits(PlacementPatternDropdown.Text == "Custom" || PlacementPatternDropdown.Text = "Map Specific")
    
    ; Monitor stage progress
    MonitorStage()
}