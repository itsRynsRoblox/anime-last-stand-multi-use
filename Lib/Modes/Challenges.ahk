#Requires AutoHotkey v2.0

WalkToChallengeRoom(angle) {
    switch angle {
    case 2:
        SendInput("{d down}")
        Sleep(800)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed
        SendInput("{s down}")
        Sleep(800)
        SendInput("{s up}")
        KeyWait "s"  ; Wait for the key to be fully processed
    case 1:
        SendInput("{w down}")
        Sleep(800)
        SendInput("{w up}")
        KeyWait "w"  ; Wait for the key to be fully processed
        SendInput("{d down}")
        Sleep(2000)
        SendInput("{d up}")
        KeyWait "d"  ; Wait for the key to be fully processed    
    }
}