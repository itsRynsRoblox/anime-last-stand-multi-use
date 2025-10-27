#Requires AutoHotkey v2.0

class TimerManager {
    static timers := Map()

    ; Starts a failsafe timer for a given name and duration (ms)
    static Start(name, durationMs) {
        this.timers[name] := A_TickCount + durationMs

        if (debugMessages) {
            ; Convert ms → minutes:seconds
            totalSeconds := Floor(durationMs / 1000)
            minutes := Floor(totalSeconds / 60)
            seconds := Mod(totalSeconds, 60)

            ; Pad seconds to always show 2 digits (e.g. 2:05)
            formattedTime := minutes ":" Format("{:02}", seconds)
            AddToLog("[Timer] '" name "' will trigger in " formattedTime " " (debugMessages ? "(" durationMs " ms)" : ""))
        }
    }

    ; Checks if the failsafe timer has expired
    static HasExpired(name) {
        return this.timers.Has(name) && A_TickCount >= this.timers[name]
    }

    ; Gets remaining time in milliseconds
    static GetRemaining(name) {
        if !this.timers.Has(name)
            return 0
        remaining := this.timers[name] - A_TickCount
        return remaining > 0 ? remaining : 0
    }

    ; Clears a timer
    static Clear(name) {
        if this.timers.Has(name) {
            this.timers.Delete(name)
            if (debugMessages) {
                AddToLog(Format("[Timer] '{}' has been cleared", name))
            }
        }
    }

    ; Resets the timer (if needed)
    static Reset(name, durationMs) {
        this.Start(name, durationMs)
    }

    static CheckAndRestart(name, durationMs) {
        if this.HasExpired(name) {
            this.Start(name, durationMs)
            return true
        }
        return false
    }

    static ClearAll() {
        this.timers.Clear()
        if (debugMessages) {
            AddToLog("[Timer] All timers have been cleared")
        }
    }
}