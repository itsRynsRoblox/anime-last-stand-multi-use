#Requires AutoHotkey v2.0

UseCustomPoints() {
    global savedCoords  ; Access the global saved coordinates
    points := []

    presetIndex := PlacementProfiles.Value  ; Get the currently selected preset index

    ; Ensure presetIndex is valid
    if (presetIndex < 1 || !savedCoords.Has(presetIndex)) {
        AddToLog("⚠️ No placements set for Preset: " PlacementProfiles.Text)
        return points  ; Return empty list if invalid index
    }

    ; Use saved coordinates for the selected preset
    for coord in savedCoords[presetIndex] {
        points.Push({x: coord.x, y: coord.y})
    }

    AddToLog("Total Points: " points.Length)

    return points
}

GenerateRandomPoints() {
    points := []
    gridSize := 40  ; Minimum spacing between units
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Define placement area boundaries (adjust these as needed)
    minX := centerX - 180  ; Left boundary
    maxX := centerX + 180  ; Right boundary
    minY := centerY - 140  ; Top boundary
    maxY := centerY + 140  ; Bottom boundary
    
    ; Generate 40 random points
    Loop 40 {
        ; Generate random coordinates
        x := Random(minX, maxX)
        y := Random(minY, maxY)
        
        ; Check if point is too close to existing points
        tooClose := false
        for existingPoint in points {
            ; Calculate distance to existing point
            distance := Sqrt((x - existingPoint.x)**2 + (y - existingPoint.y)**2)
            if (distance < gridSize) {
                tooClose := true
                break
            }
        }
        
        ; If point is not too close to others, add it
        if (!tooClose)
            points.Push({x: x, y: y})
    }
    
    ; Always add center point last (so it's used last)
    points.Push({x: centerX, y: centerY})
    
    return points
}

GenerateGridPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)
    
    ; Generate grid points row by row
    Loop squaresPerSide {
        currentRow := A_Index
        y := startY + ((currentRow - 1) * gridSize)
        
        ; Generate each point in the current row
        Loop squaresPerSide {
            x := startX + ((A_Index - 1) * gridSize)
            points.Push({x: x, y: y})
        }
    }
    
    return points
}

GenerateUpandDownPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)
    
    ; Center point coordinates
    centerX := 408
    centerY := 320
    
    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)
    
    ; Generate grid points column by column (left to right)
    Loop squaresPerSide {
        currentColumn := A_Index
        x := startX + ((currentColumn - 1) * gridSize)
        
        ; Generate each point in the current column
        Loop squaresPerSide {
            y := startY + ((A_Index - 1) * gridSize)
            points.Push({x: x, y: y})
        }
    }
    
    return points
}

; circle coordinates
GenerateCirclePoints() {
    points := []
    
    ; Define each circle's radius
    radius1 := 45    ; First circle 
    radius2 := 90    ; Second circle 
    radius3 := 135   ; Third circle 
    radius4 := 180   ; Fourth circle 
    
    ; Angles for 8 evenly spaced points (in degrees)
    angles := [0, 45, 90, 135, 180, 225, 270, 315]
    
    ; First circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius1 * Cos(radians)
        y := centerY + radius1 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; second circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius2 * Cos(radians)
        y := centerY + radius2 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; third circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius3 * Cos(radians)
        y := centerY + radius3 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ;  fourth circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius4 * Cos(radians)
        y := centerY + radius4 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    return points
}

; Spiral coordinates (restricted to a rectangle)
GenerateSpiralPoints(rectX := 4, rectY := 123, rectWidth := 795, rectHeight := 433) {
    points := []
    
    ; Calculate center of the rectangle
    centerX := rectX + rectWidth // 2
    centerY := rectY + rectHeight // 2
    
    ; Angle increment per step (in degrees)
    angleStep := 30
    ; Distance increment per step (tighter spacing)
    radiusStep := 10
    ; Initial radius
    radius := 20
    
    ; Maximum radius allowed (smallest distance from center to edge)
    maxRadiusX := (rectWidth // 2) - 1
    maxRadiusY := (rectHeight // 2) - 1
    maxRadius := Min(maxRadiusX, maxRadiusY)

    ; Generate spiral points until reaching max boundary
    Loop {
        ; Stop if the radius exceeds the max boundary
        if (radius > maxRadius)
            break
        
        angle := A_Index * angleStep
        radians := angle * 3.14159 / 180
        x := centerX + radius * Cos(radians)
        y := centerY + radius * Sin(radians)
        
        ; Check if point is inside the rectangle
        if (x < rectX || x > rectX + rectWidth || y < rectY || y > rectY + rectHeight)
            break ; Stop if a point goes out of bounds
        
        points.Push({ x: Round(x), y: Round(y) })
        
        ; Increase radius for next point
        radius += radiusStep
    }
    
    return points
}

UseRecommendedPoints() {
    if (ModeDropdown.Text = "Raid") {
        if (RaidDropdown.Text = "Marines Fort") {
            return GenerateMarineFortPoints()
        }
        else if (RaidDropdown.Text = "Hell City") {
            return GenerateHellCityPoints()
        }
        else if (RaidDropdown.Text = "Snowy Capital") {
            return GenerateSnowyCapitalPoints()
        }
        else if (RaidDropdown.Text = "Leaf Village") {
            return GenerateLeafVillagePoints()
        }
        else if (RaidDropdown.Text = "Wanderniech") {
            return GenerateBleachPoints()
        }
        else if (RaidDropdown.Text = "Central City") {
            return GenerateCentralCityPoints2()
           ; return GenerateCentralCityPoints()
        }
    }
    if (ModeDropdown.Text = "Dungeon") {
        return GenerateDungeonPoints()
    }
    return GenerateRandomPoints()
}

Generate3x3GridPoints() {
    points := []
    gridSize := 20  ; Space between points
    gridSizeHalf := gridSize // 2
    
    ; Center point coordinates
    centerX := GetWindowCenter(rblxID).x - 30
    centerY := GetWindowCenter(rblxID).y - 30
    
    ; Define movement directions: right, down, left, up
    directions := [[1, 0], [0, 1], [-1, 0], [0, -1]]
    
    ; Spiral logic for a 3x3 grid
    x := centerX
    y := centerY
    step := 1  ; Number of steps in the current direction
    dirIndex := 0  ; Current direction index
    moves := 0  ; Move count to switch direction
    
    points.Push({x: x, y: y})  ; Start at center
    
    Loop 8 {  ; Fill remaining 8 spots (3x3 grid has 9 total)
        dx := directions[dirIndex + 1][1] * gridSize
        dy := directions[dirIndex + 1][2] * gridSize
        x += dx
        y += dy
        points.Push({x: x, y: y})
        
        moves++
        if (moves = step) {  ; Change direction
            moves := 0
            dirIndex := Mod(dirIndex + 1, 4)  ; Rotate through 4 directions
            if (dirIndex = 0 || dirIndex = 2) {
                step++  ; Increase step size after every two direction changes
            }
        }
    }
    
    return points
}

; raid coordinates
GenerateMarineFortPoints() {
    points := []

    points.Push({ x: Round(218), y: Round(264) })
    points.Push({ x: Round(272), y: Round(244) })
    points.Push({ x: Round(373), y: Round(244) })
    
    return points
}

GenerateHellCityPoints() {
    points := []

    points.Push({ x: Round(101), y: Round(242) })
    points.Push({ x: Round(235), y: Round(202) })
    points.Push({ x: Round(176), y: Round(197) })
    
    return points
}

GenerateSnowyCapitalPoints() {
    points := []

    points.Push({ x: 772, y: 252 })
    points.Push({ x: Round(762), y: Round(457) })
    points.Push({ x: Round(623), y: Round(366) })
    
    return points
}

GenerateLeafVillagePoints() {
    points := []

    points.Push({ x: Round(386), y: Round(242) })
    points.Push({ x: Round(603), y: Round(330) })
    points.Push({ x: Round(481), y: Round(386) })
    
    return points
}

GenerateCentralCityPoints() {
    points := []
    points.Push({ x: Round(413), y: Round(114) })
    points.Push({ x: Round(419), y: Round(196) })
    points.Push({ x: Round(404), y: Round(27) })
    
    return points
}

GenerateDungeonPoints() {
    points := []

    points.Push({ x: 695, y: 460 })
    points.Push({ x: 662, y: 300 })
    points.Push({ x: 753, y: 329 })
    points.Push({ x: 499, y: 268 }) ; Hill
    
    return points
}

GenerateCentralCityPoints2() {
    points := []
    points.Push({ x: Round(258), y: Round(312) }) ; Hill
    points.Push({ x: Round(167), y: Round(287) })
    points.Push({ x: Round(167), y: Round(242) })
    points.Push({ x: Round(147), y: Round(242) })
    
    return points
}

GenerateBleachPoints() {
    points := []

    points.Push({ x: Round(127), y: Round(580) }) ; Hill Placement
    points.Push({ x: Round(392), y: Round(507) }) ; Farm
    points.Push({ x: Round(341), y: Round(509) }) ; DPS Unit
    
    return points
}