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
    $originalText = $originalText -replace ":allbugtask$", ""
    $originalText = $originalText.Trim()
    
    $escapedText = $originalText -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
    
    $jsonBody = @"
{
    "model": "gpt-4o-mini",
    "messages": [
        {
            "role": "system",
            "content": "You are a bug report formatter. Convert the input into a properly structured bug report.\n\nFORMAT:\nBug Title: [Clear, concise title]\n\nDescription:\n[Brief description of the bug]\n\nSteps to Reproduce:\n1. [First step]\n2. [Second step]\n3. [Third step]\n\nExpected Behavior:\n[What should happen]\n\nActual Behavior:\n[What actually happens]\n\nPriority: [Critical/High/Medium/Low]\n\nEnvironment:\n- Browser/Device: [if applicable]\n- OS: [if applicable]\n- Version: [if applicable]\n\nRULES:\n- Extract information from the input\n- Use bullet points for clarity\n- If information is missing, mark as [To be determined]\n- Keep it concise and professional\n- Infer priority based on severity if not mentioned\n- Do NOT use markdown, formatting, or styling unless explicitly asked\n- If an answer must be long: Use clear spacing and line breaks. Do NOT use markdown syntax\n- If a specific format is requested: Follow that format exactly. If no format is requested, respond in plain text\n- Avoid emojis\n- Use ASCII characters only (UTF-8 unsafe symbols not allowed)"
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
        $bugReport = $response.choices[0].message.content.Trim()
        
        if ($bugReport) {
            Write-Output $bugReport
        }
        
    } catch {
        $errorMsg = "Error formatting bug report"
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

