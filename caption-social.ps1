# caption-social.ps1
# Generates a universal social media caption from context

param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    $apiKey = $env:OPENAI_API_KEY
    
    $context = [System.Windows.Forms.Clipboard]::GetText()
    
    if (-not $context -or $context.Length -eq 0) {
        Write-Output "ERROR: No context in clipboard. Copy some text first."
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
    
    $systemPrompt = "Generate ONE universal social media caption that works across all platforms (LinkedIn, Twitter/X, Instagram, Facebook).

Requirements:
- NO emojis whatsoever
- Professional yet engaging tone
- Hook attention in first line
- 2-3 sentences maximum
- Include 3-5 relevant hashtags at the end
- Clear and concise
- Works for both personal and business content

Output ONLY the caption text, nothing else."
    
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
  "temperature": 0.7,
  "max_tokens": 200
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
    Write-Output "Error: $($_.Exception.Message)"
}
