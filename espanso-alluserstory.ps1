$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web

Start-Sleep -Milliseconds 100
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("^c")
Start-Sleep -Milliseconds 300

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $originalText = $originalText -replace ":alluserstory$", ""
    $originalText = $originalText.Trim()
    
    $escapedText = $originalText -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
    
    $jsonBody = @"
{
    "model": "gpt-4o-mini",
    "messages": [
        {
            "role": "system",
            "content": "You are a user story formatter for project management. Convert the input into a properly structured user story.\n\nFORMAT:\nUser Story: As a [user type], I want to [action] so that [benefit]\n\nDescription:\n[Brief description of the feature/functionality]\n\nAcceptance Criteria:\n1. [Specific, testable criterion]\n2. [Specific, testable criterion]\n3. [Specific, testable criterion]\n\nPriority: [Critical/High/Medium/Low]\n\nEstimated Effort: [Story Points or Time estimate]\n\nNotes:\n[Any additional context, dependencies, or technical considerations]\n\nRULES:\n- Extract information from the input\n- Write clear, specific acceptance criteria\n- If information is missing, mark as [To be determined]\n- Keep it concise and actionable\n- Focus on user value and business outcomes\n- Infer priority based on business impact if not mentioned\n- Do NOT use markdown, formatting, or styling unless explicitly asked\n- If an answer must be long: Use clear spacing and line breaks. Do NOT use markdown syntax\n- If a specific format is requested: Follow that format exactly. If no format is requested, respond in plain text\n- Avoid emojis\n- Use ASCII characters only (UTF-8 unsafe symbols not allowed)"
        },
        {
            "role": "user",
            "content": "$escapedText"
        }
    ],
    "temperature": 0.3,
    "max_tokens": 1000
}
"@

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) -TimeoutSec 30
        $userStory = $response.choices[0].message.content.Trim()
        
        if ($userStory) {
            Write-Output $userStory
        }
        
    } catch {
        $errorMsg = "Error formatting user story"
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

