$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$copiedMessage = [System.Windows.Forms.Clipboard]::GetText()

[System.Windows.Forms.Clipboard]::Clear()
Start-Sleep -Milliseconds 100

[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("^c")
Start-Sleep -Milliseconds 300

$fullText = [System.Windows.Forms.Clipboard]::GetText()

if ($copiedMessage -and $fullText) {
    $triggerPattern = ":replywithcontext|:rwc"

    if ($fullText -match $triggerPattern) {
        $parts = $fullText -split $triggerPattern, 2
        $contextBeforeTrigger = $parts[0].Trim()
        $textAfterTrigger = ""
        if ($parts.Length -gt 1) { $textAfterTrigger = $parts[1].Trim() }

        $messages = @(
            @{
                role    = "system"
                content = "You are Bibek Subedi (SB), Co-founder of Vrit Technologies. Write SHORT, PRECISE replies (1-3 sentences max). Be direct, professional, and relevant. No fluff. Plain text only."
            }
            @{
                role    = "user"
                content = "Context: $contextBeforeTrigger`n`nMessage to reply to: $copiedMessage`n`nWrite a brief reply as Bibek considering the context above."
            }
        )
        $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7 -MaxTokens 200

        if ($reply) {
            $finalOutput = if ($textAfterTrigger) { $reply + " " + $textAfterTrigger } else { $reply }
            Write-Output $finalOutput
        } else {
            Write-Output "Error: Empty response from AI"
        }
    } else {
        Write-Output "Error: Trigger not found in text"
    }
} else {
    Write-Output "Error: No text copied or no clipboard content"
}
