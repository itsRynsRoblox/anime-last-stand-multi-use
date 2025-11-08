#Requires AutoHotkey v2.0

CheckForUpdates() {
    global repoOwner, repoName, version

    if (!UpdateChecker.Value) {
        return
    }

    ; --- Get latest release info from GitHub ---
    url := "https://api.github.com/repos/" repoOwner "/" repoName "/releases/latest"
    http := ComObject("MSXML2.XMLHTTP")
    http.Open("GET", url, false)
    http.Send()

    if (http.Status != 200) {
        AddToLog("❌ Failed to check for updates. HTTP " http.Status)
        AddToLog("Current Version: " version)
        return
    }

    response := http.responseText
    file := JSON.parse(response)
    latestVersion := file["tag_name"]
    assets := file["assets"]

    ; --- Read release title and description (changelog) ---
    releaseTitle := file.Has("name") ? file["name"] : latestVersion
    if file.Has("body") && file["body"] != ""
        releaseNotes := file["body"]
    else
        releaseNotes := "(No changelog or description provided for this release.)"

    ; Clean up for readability
    releaseNotes := StrReplace(releaseNotes, "`r", "")
    releaseNotes := StrReplace(releaseNotes, "`n`n", "`n")

    ; --- Compare versions ---
    comparison := VerCompare(version, latestVersion)

    if (comparison < 0) {
        MainUI.Opt("-AlwaysOnTop")

        ; Truncate long changelog for readability
        if StrLen(releaseNotes) > 1200
            releaseNotes := SubStr(releaseNotes, 1, 1200) "`n... (truncated)"

        ; --- Prompt user for update ---
        msg :=
            (
                "Current: " version " → Latest: v" latestVersion
                "`n`n" releaseNotes
                "`n`nDo you want to download and install it now?"
                "`n`nNote: Your Settings folder will be backed up and preserved."
            )

        MsgBoxResult := MsgBox(msg, "New Update Available", "YesNo")

        if (MsgBoxResult = "Yes") {
            AddToLog("⬇️ Accepted update, starting download...")

            if (assets.Length = 0) {
                MainUI.Opt("+AlwaysOnTop")
                AddToLog("⚠️ No release files found for version " latestVersion)
                return
            }

            ; --- Download the first asset ---
            downloadUrl := assets[1]["browser_download_url"]
            fileName := A_Temp "\" assets[1]["name"]
            Download(downloadUrl, fileName)

            ; --- Create a unique script-local temp extraction folder ---
            extractDir := A_ScriptDir "\update_extract_" A_TickCount
            DirCreate(extractDir)

            ; --- Extract update ZIP to this folder ---
            psCmd := Format('powershell -NoProfile -Command "Expand-Archive -Force ' '{}' ' ' '{}' '"', fileName,
                extractDir)
            RunWait(psCmd, , "Hide")

            ; --- Backup user Settings ---
            settingsDir := A_ScriptDir "\Settings"
            if DirExist(settingsDir) {
                backupDir := A_ScriptDir "\Settings_Backup_" version
                DirCreate(backupDir)
                DirCopy(settingsDir, backupDir, true)
                AddToLog("💾 Backed up settings...")
            }

            ; --- Delete old files but preserve key folders ---
            loop files, A_ScriptDir "\*.*", "R" {
                file := A_LoopFileFullPath

                if InStr(file, "\Settings\")
                    continue
                if InStr(file, "\Settings_Backup_")
                    continue
                if (file = A_ScriptFullPath)
                    continue
                if InStr(file, extractDir)
                    continue

                FileDelete(file)
            }

            ; --- Remove empty folders safely ---
            loop files, A_ScriptDir "\*", "DR" {
                dir := A_LoopFileFullPath

                if InStr(dir, "\Settings") || InStr(dir, "\Settings_Backup_") || InStr(dir, extractDir)
                    continue

                try DirDelete(dir, false)  ; delete only if empty, skip errors
                catch
                    continue
            }

            ; --- Copy new update contents ---
            DirCopy(extractDir, A_ScriptDir, true)
            AddToLog("✅ Update files copied successfully")

            ; --- Clean up temporary extraction folder ---
            try {
                DirDelete(extractDir, true)  ; true = recursive delete
            }


            Sleep(2000)
            Run(A_ScriptFullPath)
            ExitApp
        } else {
            MainUI.Opt("+AlwaysOnTop")
        }

    } else if (comparison > 0) {
        AddToLog("🚨 Your version is newer than the latest published (" latestVersion ")")
    } else {
        AddToLog("✅ You are already using the latest version (" version ")")
    }
}