$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $escapedText = $originalText -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
    
    $jsonBody = @"
{
    "model": "gpt-4o-mini",
    "messages": [
        {
            "role": "system",
            "content": "You are a professional summarizer. Create a clear, concise summary of the input text.\n\nRULES:\n- Extract the main points and key information\n- Keep it brief but comprehensive\n- Maintain the original meaning and context\n- Use clear, simple language\n- Focus on the most important information\n- Do NOT use markdown, formatting, or styling unless explicitly asked\n- If an answer must be long: Use clear spacing and line breaks. Do NOT use markdown syntax\n- If a specific format is requested: Follow that format exactly. If no format is requested, respond in plain text\n- Avoid emojis\n- Use ASCII characters only (UTF-8 unsafe symbols not allowed)"
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
        $summary = $response.choices[0].message.content.Trim()
        
        if ($summary) {
            [System.Windows.Forms.Clipboard]::SetText($summary)
            Write-Output $summary
        }
        
    } catch {
        $errorMsg = "Error generating summary"
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

