$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

# Save current clipboard (the copied message to reply to)
$copiedMessage = [System.Windows.Forms.Clipboard]::GetText()

# Clear clipboard to avoid confusion
[System.Windows.Forms.Clipboard]::Clear()
Start-Sleep -Milliseconds 100

# Select all and copy to get full text with context
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("^c")
Start-Sleep -Milliseconds 300

$fullText = [System.Windows.Forms.Clipboard]::GetText()

if ($copiedMessage -and $fullText) {
    # Find the trigger position
    $triggerPattern = ":replywithcontext|:rwc"
    
    if ($fullText -match $triggerPattern) {
        # Split by trigger (handle both :replywithcontext and :rwc)
        $parts = $fullText -split $triggerPattern, 2
        
        # Text BEFORE trigger = context for GPT
        $contextBeforeTrigger = $parts[0].Trim()
        
        # Text AFTER trigger (if any)
        $textAfterTrigger = ""
        if ($parts.Length -gt 1) {
            $textAfterTrigger = $parts[1].Trim()
        }
        
        # Build the API request
        $body = @{
            model = "gpt-4o-mini"
            messages = @(
                @{
                    role = "system"
                    content = "You are Bibek Subedi (SB), Co-founder of Vrit Technologies. Write SHORT, PRECISE replies (1-3 sentences max). Be direct, professional, and relevant. No fluff. Plain text only."
                }
                @{
                    role = "user"
                    content = "Context: $contextBeforeTrigger`n`nMessage to reply to: $copiedMessage`n`nWrite a brief reply as Bibek considering the context above."
                }
            )
            temperature = 0.7
            max_tokens = 200
        } | ConvertTo-Json -Depth 10
        
        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json; charset=utf-8"
        }
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30
            $reply = $response.choices[0].message.content.Trim()
            
            if ($reply) {
                # If there's text after trigger, preserve it
                if ($textAfterTrigger) {
                    $finalOutput = $reply + " " + $textAfterTrigger
                } else {
                    $finalOutput = $reply
                }
                
                # Output for Espanso to replace
                Write-Output $finalOutput
            } else {
                Write-Output "Error: Empty response from API"
            }
        } catch {
            $errorMsg = "Error: Unable to generate reply"
            if ($_.ErrorDetails.Message) {
                try {
                    $errorJson = ($_.ErrorDetails.Message | ConvertFrom-Json)
                    $errorMsg = "Error: " + $errorJson.error.message
                } catch {
                    $errorMsg = "Error: " + $_.Exception.Message
                }
            }
            Write-Output $errorMsg
        }
    } else {
        Write-Output "Error: Trigger not found in text"
    }
} else {
    Write-Output "Error: No text copied or no clipboard content"
}
