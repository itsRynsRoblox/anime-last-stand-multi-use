#Requires AutoHotkey v2.0

WalkToCavernRoom(angle) {
    switch angle {
    case 2:
        SendInput("{d down}")
        Sleep(800)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
    case 1:
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
        SendInput("{a down}")
        Sleep(2000)
        SendInput("{a up}")
        KeyWait "a"  ; Wait for the key to be fully processed    
    }
}