#Include %A_ScriptDir%\Lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include %A_ScriptDir%\Lib\AHKv2-Gdip-master\Gdip_All.ahk

global DiscordUserIDFile := "Settings\DiscordUSERID.txt"
global SendActivityLogsFile := "Settings\SendActivityLogs.txt"
global WebhookURL := WebhookURLBox.Value  
global webhook := ""
global currentStreak := 0
global lastResult := "none"
global Wins := 0
global loss := 0
global mode := ""
global StartTime := A_TickCount 
global stageStartTime := A_TickCount
global macroStartTime := A_TickCount
global currentMap := ""

if (!FileExist("Settings")) {
    DirCreate("Settings")
}

win_messages := [
            "clean victory secured 🏆",
            "macro going crazy rn fr 🔥",
            "stacking those Ws 📈",
            "another dub in the books 🎯",
            "back to back wins incoming 💫",
            "(˵ •̀ ᴗ – ˵ ) ✧",
            "♡‧₊˚✧ ૮ ˶ᵔ ᵕ ᵔ˶ ა ✧˚₊‧♡",
            "/)_/)`n(,,>.<)`n/ >❤️",
            "૮꒰ ˶• ༝ •˶꒱ა ♡",
            "✧｡٩(ˊᗜˋ )و✧*｡",
            "( •̯́ ₃ •̯̀)",
            "₍ᐢ•ﻌ•ᐢ₎*･ﾟ｡"

        ],
        lose_messages := [
            "next one is a win fr 💯",
            "just warming up 🔥",
            "next run is the one 🎮",
            "almost had it that time 🎯",
            "getting better each run 📈",
            "(╯°□°)╯︵ ┻━┻",
            "(ಠ益ಠ)",
            "(╥﹏╥)",
            "(⇀‸↼‶)",
            "(◣ _ ◢)",
            "<(ꐦㅍ _ㅍ)>"
        ],
        ; Milestone messages (every 10th attempt)
        milestone_win_messages := [
        "milestone #{count} win secured! 🏆",
        "#{count} wins and counting! 📈",
        "#{count} wins in the books! 🔥",
        "reached #{count} wins! ⭐",
        "#{count} wins and still going strong! 💫"
        ],
        milestone_lose_messages := [
        "milestone #{count} loss... just bad luck, next time! 🍀",
        "#{count} losses, but we'll get 'em next time! 🤞",
        "reached #{count} losses... just one of those days! 🤷‍♂️",
        "hit #{count} losses, but we’ll turn it around soon! 🙌",
        "milestone #{count} loss, but no worries—next game is ours! 😎"
        ]
        ; Streak messages
        winstreak_messages := [
            "#{streak} win streak lets gooo 🏆",
            "on fire with #{streak} wins 🔥",
            "unstoppable #{streak} win streak 💫",
            "#{streak} wins in a row sheesh 📈",
            "#{streak} win streak going crazy 🌟"
            "(˵ •̀ ᴗ – ˵ ) ✧",
            "♡‧₊˚✧ ૮ ˶ᵔ ᵕ ᵔ˶ ა ✧˚₊‧♡",
            "/)_/)`n(,,>.<)`n/ >❤️",
            "૮꒰ ˶• ༝ •˶꒱ა ♡",
            "✧｡٩(ˊᗜˋ )و✧*｡",
            "( •̯́ ₃ •̯̀)"
        ],
        losestreak_messages := [
            "#{streak} runs of experience gained 📚",
            "#{streak} tries closer to victory 🎯",
            "learning from #{streak} attempts 💪",
            "#{streak} runs of practice secured 📈",
            "comeback loading after #{streak} 🔄"
            "(╯°□°)╯︵ ┻━┻",
            "(ಠ益ಠ)",
            "(╥﹏╥)",
            "(⇀‸↼‶)",
            "(◣ _ ◢)",
            "<(ꐦㅍ _ㅍ)>"
        ],
        ; Time-based messages
        long_win_messages := [
        "took #{time} but macro finally popped off 💪",
        "#{time} grind actually paid off wtf 😳",
        "pc earned its rest after #{time} 😴",
        "#{time} of pure skill 🔥",
        ],
        long_lose_messages := [
        "#{time} of valuable experience 📚",
        "#{time} of strategy learning 🧠",
        "#{time} closer to victory 🎯",
        "#{time} of practice makes perfect ⭐",
        "#{time} getting stronger 💪"
        ]

; Function to update streak
UpdateStreak(isWin) {
    global currentStreak, lastResult
    
    ; Initialize lastResult if it doesn't exist
    if (!IsSet(lastResult)) {
        lastResult := "none"
    }
    
    if (isWin) {
        if (lastResult = "win")
            currentStreak += 1
        else
            currentStreak := 1
    } else {
        if (lastResult = "lose")
            currentStreak -= 1
        else
            currentStreak := -1
    }
    
    lastResult := isWin ? "win" : "lose"
}

SendWebhookWithTime(isWin, stageLength) {
    global currentStreak, Wins, loss, WebhookURL, webhook, macroStartTime
    
    ; Update streak
    UpdateStreak(isWin)

    if !(WebhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        AddToLog("Invalid webhook URL - skipping webhook")
        return
    }
    
    ; Initialize webhook
    webhook := WebHookBuilder(WebhookURL)
    
    ; Calculate macro runtime (total time)
    macroLength := FormatStageTime(A_TickCount - macroStartTime)
    
    ; Build session data
    sessionData := "⌛ Macro Runtime: " macroLength "`n"
    . "⏱️ Stage Length: " stageLength "`n"
    . "🔄 Current Streak: " (currentStreak > 0 ? currentStreak " Win Streak" : Abs(currentStreak) " Loss Streak") "`n"
    . ":video_game: Current Mode: " mode "`n"
    . ":white_check_mark: Successful Runs: " Wins "`n"
    . "❌ Failed Runs: " loss "`n"
    . ":bar_chart: Total Runs: " (loss+Wins) "`n"
    . ":scales: Win Rate: " Format("{:.1f}%", (Wins/(Wins+loss))*100) "`n"
    isWin ? 0x0AB02D : 0xB00A0A,
    isWin ? "win" : "lose"
    
    
    ; Send webhook
    WebhookScreenshot(
        isWin ? "Stage Complete!" : "Stage Failed",
        sessionData,
        isWin ? 0x0AB02D : 0xB00A0A,
        isWin ? "win" : "lose"
    )
}

CropImage(pBitmap, x, y, width, height) {
    ; Initialize GDI+ Graphics from the source bitmap
    pGraphics := Gdip_GraphicsFromImage(pBitmap)
    if !pGraphics {
        MsgBox("Failed to initialize graphics object")
        return
    }

    ; Create a new bitmap for the cropped image
    pCroppedBitmap := Gdip_CreateBitmap(width, height)
    if !pCroppedBitmap {
        MsgBox("Failed to create cropped bitmap")
        Gdip_DeleteGraphics(pGraphics)
        return
    }

    ; Initialize GDI+ Graphics for the new cropped bitmap
    pTargetGraphics := Gdip_GraphicsFromImage(pCroppedBitmap)
    if !pTargetGraphics {
        MsgBox("Failed to initialize graphics for cropped bitmap")
        Gdip_DisposeImage(pCroppedBitmap)
        Gdip_DeleteGraphics(pGraphics)
        return
    }

    ; Copy the selected area from the source bitmap to the new cropped bitmap
    Gdip_DrawImage(pTargetGraphics, pBitmap, 0, 0, width, height, x, y, width, height)

    ; Cleanup
    Gdip_DeleteGraphics(pGraphics)
    Gdip_DeleteGraphics(pTargetGraphics)

    ; Return the cropped bitmap
    return pCroppedBitmap
}

TextWebhook() {
    global lastlog

    ; Calculate the runtime
    ElapsedTimeMs := A_TickCount - StartTime
    ElapsedTimeSec := Floor(ElapsedTimeMs / 1000)
    ElapsedHours := Floor(ElapsedTimeSec / 3600)
    ElapsedMinutes := Floor(Mod(ElapsedTimeSec, 3600) / 60)
    ElapsedSeconds := Mod(ElapsedTimeSec, 60)
    Runtime := Format("{} hours, {} minutes", ElapsedHours, ElapsedMinutes)

    ; Prepare the attachment and embed
    myEmbed := EmbedBuilder()
        .setTitle("")
        .setDescription("[" FormatTime(A_Now, "hh:mm tt") "] " lastlog)
        .setColor(0x0077ff)
        

    ; Send the webhook
    webhook.send({
        content: (""),
        embeds: [myEmbed],
        files: []
    })

    ; Clean up resources
}

InitiateWinWebhook() {
    if (webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        global webhook := WebHookBuilder(WebhookURL)
        stageLength := FormatStageTime(A_TickCount - stageStartTime)
        SendWebhookWithTime(true, stageLength)
    }
}

InitiateLoseWebhook() {
    if (webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        global webhook := WebHookBuilder(WebhookURL)
        stageLength := FormatStageTime(A_TickCount - stageStartTime)
        SendWebhookWithTime(false, stageLength)
    }
}

WebhookLog() {
    if (webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        global webhook := WebHookBuilder(WebhookURL)
        TextWebhook()
    } 
}
;Discord webhooks, above

WebhookScreenshot(title, description, color := 0x0dffff, status := "") {
    global webhook, WebhookURL, DiscordUserID, wins, loss, currentStreak, stageStartTime
    ; Yap message

    footerMessages := Map(
        "win", win_messages,
        "lose", lose_messages,
        "milestone_win", milestone_win_messages,
        "milestone_lose", milestone_lose_messages,
        "winstreak", winstreak_messages,
        "losestreak", losestreak_messages,
        "long_win", long_win_messages,
        "long_lose", long_lose_messages
    )

    global webhook := WebHookBuilder(WebhookURL)
    global DiscordUserID := FileRead(DiscordUserIDFile, "UTF-8")
    global wins, loss, currentStreak, stageStartTime

    if (!IsSet(stageStartTime)) {
        stageStartTime := A_TickCount
    }
    
    if !(webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        return
    }
    
    ; Select appropriate message based on conditions
    footerText := ""
    messages := footerMessages[status = "win" ? "win" : "lose"]  ; default messages

    ; Check if it's a long run (30+ minutes)
    stageLength := CalculateElapsedTime(stageStartTime)
    stageMinutes := Floor((A_TickCount - stageStartTime) / (1000 * 60))

    ; Helper function to replace placeholders
    ReplaceVars(text, vars) {
        for key, value in vars {
            text := StrReplace(text, "#{" key "}", value)
        }
        return text
    }

    ; If no special message was set, use a random regular message
    if (footerText = "") {
        footerText := "Ryn's Anime Last Stand Macro " version
    }

    ; Rest of your existing WebhookScreenshot code...
    UserIDSent := (DiscordUserID = "") ? "" : "<@" DiscordUserID ">"

    ; Initialize GDI+
    pToken := Gdip_Startup()
    if !pToken {
        MsgBox("Failed to initialize GDI+")
        return
    }

    ; Capture and process screen
    pBitmap := Gdip_BitmapFromScreen()
    if !pBitmap {
        MsgBox("Failed to capture the screen")
        Gdip_Shutdown(pToken)
        return
    }

    pCroppedBitmap := CropImage(pBitmap, 0, 0, 1366, 633)
    if !pCroppedBitmap {
        MsgBox("Failed to crop the bitmap")
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)
        return
    }   
    
    ; Prepare and send webhook
    attachment := AttachmentBuilder(pCroppedBitmap)
    myEmbed := EmbedBuilder()
    myEmbed.setTitle(title)
    myEmbed.setDescription(description)
    myEmbed.setColor(color)
    myEmbed.setImage(attachment)
    myEmbed.setFooter({ text: footerText })

    webhook.send({
        content: UserIDSent,
        embeds: [myEmbed],
        files: [attachment]
    })

    ; Cleanup
    Gdip_DisposeImage(pBitmap)
    Gdip_DisposeImage(pCroppedBitmap)
    Gdip_Shutdown(pToken)
}

SendWebhookRequest(webhook, params, maxRetries := 3) {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", webhook, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(JSON.Stringify(params))
        AddToLog("Webhook sent successfully")
        return true
    } catch {
        AddToLog("Unable to send webhook - continuing without sending")
        return false
    }
}

sendDCWebhook() {
    MacroRuntime := CalculateElapsedTime(MacroStartTime)
    StageRuntime := CalculateElapsedTime(StageStartTime)

    ; Prepare the embed
    myEmbed := EmbedBuilder()
    myEmbed.setTitle(":exclamation: Client Disconnected :exclamation:")
    myEmbed.setDescription(":stopwatch: Disconnected At: " MacroRuntime "`n:stopwatch: Stage Runtime: " StageRuntime "")
    myEmbed.setColor(0xB00A0A)

    try {
        if (WebhookURL.Value != "") {
            global Webhook := WebHookBuilder(WebhookURL.Value)
        }
    } catch {
        AddToLog("Webhook URL is not set or invalid.")
        return
    }

    ; Send the webhook
    try {
        Webhook.send({
            embeds: [myEmbed],
        })

        AddToLog("Sent webhook successfully")
    } catch {
        AddToLog("Failed to send webhook")
    }

}

sendTestWebhook() {
    global Wins := 1
    SendWebhookWithTime(true, 1)
}