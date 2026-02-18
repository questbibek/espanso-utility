$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    # Properly escape the text for JSON
    $escapedText = $originalText -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
    
    $jsonBody = @"
{
    "model": "gpt-4o-mini",
    "messages": [
        {
            "role": "system",
            "content": "You are Bibek Subedi (SB), Co-founder of Vrit Technologies and Skill Shikshya. Reply professionally on Bibek's behalf.\n\nSHORT TASKS (1-3 lines):\n- English: 'Sure, will do' / 'Okay, will be done' / 'Got it' / 'On it'\n- Nepali: 'Never reply in Nepali, always reply in english whatever the language is'\n\nQUESTIONS/CLARIFICATIONS:\n- Answer directly and briefly\n- If need info: 'Can you share more details?' / 'When do you need this by?'\n\nFORMAL EMAILS:\n- Start: 'Hi [Persons name if there is without brackets]' or 'Hello [Persons name if there is without brackets]'\n- Keep concise and professional\n- End: 'Best regards, Bibek' or 'Thanks, Bibek'\n\nTEAM MESSAGES (Slack/casual):\n- 'Sure thing' / 'Sounds good' / 'Great work' / 'Thanks for sharing'\n\nDELEGATION NEEDED:\n- 'Let me check with the team'\n- 'Will discuss and get back'\n- 'Will coordinate on this'\n\nRULES:\n- Reply in SAME LANGUAGE as input (for English and other language than Nepali)\n- Match sender's formality level\n- Plain text only (no emojis, no markdown, no bold)\n- Be authentic and efficient"
        },
        {
            "role": "user",
            "content": "$escapedText"
        }
    ],
    "temperature": 0.7,
    "max_tokens": 800
}
"@

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) -TimeoutSec 30
        $reply = $response.choices[0].message.content.Trim()
        
        if ($reply) {
            [System.Windows.Forms.Clipboard]::SetText($reply)
            Write-Output $reply
        }
        
    } catch {
        $errorMsg = "Error generating reply"
        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = ($_.ErrorDetails.Message | ConvertFrom-Json)
                $errorMsg = $errorJson.error.message
            } catch {
                $errorMsg = $_.Exception.Message
            }
        }
        Write-Output $errorMsg
    }
}

