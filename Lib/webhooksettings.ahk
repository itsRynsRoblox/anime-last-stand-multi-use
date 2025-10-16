#Include %A_ScriptDir%\Lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include %A_ScriptDir%\Lib\AHKv2-Gdip-master\Gdip_All.ahk

global WebhookURL := WebhookURLBox.Text
global webhook := ""
global currentStreak := 0
global lastResult := "none"
global Wins := 0
global loss := 0
global stageStartTime := A_TickCount
global macroStartTime := A_TickCount
global currentMap := ""

if (!FileExist("Settings")) {
    DirCreate("Settings")
}

; Function to update streak
UpdateStreak(isWin) {
    global currentStreak, lastResult, Wins, loss
    
    ; Initialize lastResult if it doesn't exist
    if (!IsSet(lastResult)) {
        lastResult := "none"
    }
    
    if (isWin) {
        Wins++
        if (lastResult = "win")
            currentStreak += 1
        else
            currentStreak := 1
    } else {
        loss++
        if (lastResult = "lose")
            currentStreak -= 1
        else
            currentStreak := -1
    }
    
    lastResult := isWin ? "win" : "lose"
}

SendWebhookWithTime(isWin, stageLength) {
    global currentStreak, Wins, loss, WebhookURL, webhook, macroStartTime
    
    ; Check if WebhookURL is initialized and valid
    if (!IsSet(WebhookURL) || WebhookURL = "" || !(WebhookURL ~= "i)^https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}$")) {
        AddToLog("Webhook URL is missing or invalid - skipping webhook")
        return
    }

    ; Build webhook object if not already initialized
    if !IsObject(webhook) {
        webhook := WebHookBuilder(WebhookURL)
    }

    ; Update streak
    UpdateStreak(isWin)
    
    ; Calculate macro runtime (total time)
    macroLength := FormatStageTime(A_TickCount - macroStartTime)
    
    ; Build session data
    sessionData := "⌛ Macro Runtime: " macroLength "`n"
    . "⏱️ Stage Length: " stageLength "`n"
    . "🔄 Current Streak: " (currentStreak > 0 ? currentStreak " Win Streak" : Abs(currentStreak) " Loss Streak") "`n"
    . ":video_game: Current Mode: " (ModeDropdown.Text = "" ? "No Mode Selected" : ModeDropdown.Text) "`n"
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
    myEmbed := EmbedBuilder().setTitle("").setDescription("[" FormatTime(A_Now, "hh:mm tt") "] " lastlog).setColor(0x0077ff)
        

    ; Send the webhook
    webhook.send({
        content: (""),
        embeds: [myEmbed],
        files: []
    })

    ; Clean up resources
}

WebhookLog() {
    if (webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        TextWebhook()
    } 
}

WebhookScreenshot(title, description, color := 0x0dffff, status := "") {
    global webhook, WebhookURL, wins, loss, currentStreak, stageStartTime

    if (!IsSet(stageStartTime)) {
        stageStartTime := A_TickCount
    }
    
    if !(webhookURL ~= 'i)https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}') {
        return
    }
    
    ; Select appropriate message based on conditions
    footerText := GameTitle . version

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

    UserIDSent := ""

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

    pCroppedBitmap := CropImage(pBitmap, 0, 0, 1366, 700)
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

        ; Check if WebhookURL is initialized and valid
        if (!IsSet(WebhookURL) || WebhookURL = "" || !(WebhookURL ~= "i)^https?:\/\/discord\.com\/api\/webhooks\/(\d{18,19})\/[\w-]{68}$")) {
            AddToLog("Webhook URL is missing or invalid - skipping webhook")
            return
        }

        ; Build webhook object if not already initialized
        if !IsObject(webhook) {
            webhook := WebHookBuilder(WebhookURL)
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