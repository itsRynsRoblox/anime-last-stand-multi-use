#Requires AutoHotkey v2.0

StartStoryMode() {
    
    ; Get current map and act
    currentStoryMap := StoryDropdown.Text
    currentStoryAct := StoryActDropdown.Text
        
    ; Execute the movement pattern
    AddToLog("Moving to position for " currentStoryMap)
    StoryMovement()
    
    ; Start stage
    while !(ok:=FindText(&X, &Y, 352, 431, 451, 458, 0, 0, StorySelectButton)) {
        StoryMovement()
    }

    AddToLog("Starting " currentStoryMap " - " currentStoryAct)
    StartStory(currentStoryMap, currentStoryAct)

    ; Handle play mode selection
    PlayHere()
    RestartStage()
}

StartStory(map, act) {
    return StartContent(map, act, GetStoryMap, GetStoryAct, { x: 150, y: 190 }, { x: 300, y: 240 })
}

StoryMovement() {
    FixClick(35, 350) ; Click Teleport
    Sleep (1000)
    FixClick(392, 333) ; Click Story & Infinite
    Sleep (1000)
    FixClick(35, 350) ; Click Teleport to close
    Sleep (1000)

    spawnAngle := DetectAngle()
    WalkToStoryRoom(spawnAngle)
}

GetStoryMap(map) {
    switch map {
        case "Hog Town": return {x: 190, y: 185, scrolls: 0}
    }
}

GetStoryAct(act) {
    baseY := 185
    spacing := 28
    baseX := 320

    ; Handle "Infinite" case separately
    if (act = "Infinite") {
        x := baseX + spacing * 6  ; Assuming "Infinite" comes after Act 6
        return { x: x, y: baseY, scrolls: 0 }
    }

    ; Extract the act number from the string, e.g., "Act 3" → 3
    if RegExMatch(act, "Act\s*(\d+)", &match) {
        actNumber := match[1]
        x := baseX + spacing * (actNumber - 1)
        return { x: x, y: baseY, scrolls: 0 }
    }

    ; Default return if the input doesn't match expected format
    return { x: x, y: baseY, scrolls: 0 }
}