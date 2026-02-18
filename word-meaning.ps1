# word-meaning.ps1
# Provides quick, concise word definition from clipboard

param()

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    # API Key
    $apiKey = $env:OPENAI_API_KEY
    
    # Get word from clipboard
    $word = [System.Windows.Forms.Clipboard]::GetText()
    $word = $word.Trim()
    
    if (-not $word -or $word.Length -eq 0) {
        Write-Output "ERROR: No word in clipboard"
        exit 1
    }
    
    # Escape function for JSON
    function Escape-JsonString {
        param([string]$text)
        $text = $text -replace '\\', '\\'
        $text = $text -replace '"', '\"'
        $text = $text -replace "`n", '\n'
        $text = $text -replace "`r", ''
        $text = $text -replace "`t", '\t'
        return $text
    }
    
    # System prompt for quick definition
    $systemPrompt = "Provide a SHORT, CONCISE definition of the word. Format:

[word] ([part of speech]) - [one-line definition]

Example: ephemeral (adj.) - lasting for a very short time

Keep it to ONE line. Be clear and practical."
    
    $escapedSystem = Escape-JsonString $systemPrompt
    $escapedWord = Escape-JsonString $word
    
    # Build JSON body
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
      "content": "$escapedWord"
    }
  ],
  "temperature": 0.3
}
"@
    
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }
    
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson))
    $result = $response.choices[0].message.content.Trim()
    
    # Output result
    Write-Output $result
    
} catch {
    Write-Output "Error: $_"
}
