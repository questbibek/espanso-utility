# draft-email.ps1
# Generates professional email from context in clipboard

param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    $apiKey = $env:OPENAI_API_KEY
    
    $context = [System.Windows.Forms.Clipboard]::GetText()
    
    if (-not $context -or $context.Length -eq 0) {
        Write-Output "ERROR: No context in clipboard"
        exit 1
    }
    
    function Escape-JsonString {
        param([string]$text)
        $text = $text -replace '\\', '\\'
        $text = $text -replace '"', '\"'
        $text = $text -replace "`n", '\n'
        $text = $text -replace "`r", ''
        $text = $text -replace "`t", '\t'
        return $text
    }
    
    $systemPrompt = "You are a professional email writer. Draft a clear, professional email based on the context provided.

Guidelines:
- Include subject line
- Professional but friendly tone
- Clear and concise
- Proper email structure (greeting, body, closing)
- No fluff or unnecessary words

Format:
Subject: [subject line]

[Email body]

Best regards,
[Name]"
    
    $escapedSystem = Escape-JsonString $systemPrompt
    $escapedContext = Escape-JsonString $context
    
    $bodyJson = @"
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "$escapedSystem"
    },
    {
      "role": "user",
      "content": "$escapedContext"
    }
  ],
  "temperature": 0.7
}
"@
    
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }
    
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson))
    $result = $response.choices[0].message.content.Trim()
    
    Write-Output $result
    
} catch {
    Write-Output "Error: $_"
}
