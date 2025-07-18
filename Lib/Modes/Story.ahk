#Requires AutoHotkey v2.0

StartStoryMode() {
    
    ; Get current map and act
    currentStoryMap := StoryDropdown.Text
    currentStoryAct := StoryActDropdown.Text
        
    ; Execute the movement pattern
    AddToLog("Moving to position for " currentStoryMap)
    StoryMovement()
    
    ; Start stage
    while !(ok := isMenuOpen("Story")) {
        StoryMovement()
    }

    AddToLog("Starting " currentStoryMap " - " currentStoryAct)
    StartStory(currentStoryMap, currentStoryAct)

    SelectDifficulty("Nightmare")

    ; Handle play mode selection
    PlayHere()
    RestartStage()
}

StartStory(map, act) {
    return StartContent(map, act, GetStoryMap, GetStoryAct, { x: 190, y: 185 }, { x: 300, y: 240 })
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
        case "Hollow Night Palace": return {x: 190, y: 225, scrolls: 0}
        case "Firefighters Base": return {x: 190, y: 260, scrolls: 0}
        case "Demon Skull Village": return {x: 190, y: 295, scrolls: 0}
        case "Shibuya": return {x: 190, y: 335, scrolls: 0}
        case "Abandoned Cathedral": return {x: 190, y: 375, scrolls: 0}

        case "Moriah": return {x: 190, y: 265, scrolls: 1}
        case "Soul Society": return {x: 190, y: 300, scrolls: 1}
        case "Thrilled Bark": return {x: 190, y: 340, scrolls: 1}
        case "Dragon Heaven": return {x: 190, y: 375, scrolls: 1}

        case "Ryuudou Temple": return {x: 190, y: 275, scrolls: 2}
        case "Snowy Village": return {x: 190, y: 310, scrolls: 2}
        case "Rain Village": return {x: 190, y: 345, scrolls: 2}
        case "Giant's District": return {x: 190, y: 380, scrolls: 2}

        case "Oni Island": return {x: 190, y: 280, scrolls: 3}
        case "Unknown Planet": return {x: 190, y: 315, scrolls: 3}
        case "Oasis": return {x: 190, y: 350, scrolls: 3}
        case "Harge Forest": return {x: 190, y: 380, scrolls: 3}

        case "Babylon": return {x: 190, y: 285, scrolls: 4}
        case "Destroyed Shinjuku": return {x: 190, y: 320, scrolls: 4}
        case "Train Station": return {x: 190, y: 360, scrolls: 4}

        case "Swordsmith Village": return {x: 190, y: 335, scrolls: 5}
        case "Sacrifical Realm": return {x: 190, y: 370, scrolls: 5}
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

SelectDifficulty(name := "") {
    switch name {
        case "Normal":
            FixClick(270, 185)
        case "Nightmare":
            FixClick(270, 220)    
    }
    Sleep(1000)
}

WalkToStoryRoom(angle) {
    switch angle {
        case 1:
            SendInput("{a down}")
            Sleep(400)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
            SendInput("{s down}")
            Sleep(800)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed
            SendInput("{a down}")
            Sleep(400)
            SendInput("{a up}")
            KeyWait "a"  ; Wait for the key to be fully processed
            Sleep (1000)
        case 2:
            SendInput("{d down}")
            Sleep(1000)
            SendInput("{d up}")
            KeyWait "d"  ; Wait for the key to be fully processed
            Sleep (250)
            SendInput("{s down}")
            Sleep(2000)
            SendInput("{s up}")
            KeyWait "s"  ; Wait for the key to be fully processed   
            Sleep (1000) 
    }
}