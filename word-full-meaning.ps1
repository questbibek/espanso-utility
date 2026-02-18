# word-full-meaning.ps1
# Provides comprehensive word analysis from clipboard

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
    
    # System prompt for comprehensive analysis
    $systemPrompt = "Provide a COMPREHENSIVE analysis of the word. Use DOUBLE line breaks between sections for readability:

WORD: [word]
PRONUNCIATION: [SYL-la-ble format, e.g., SEN-si-tiv or voh-KAB-yuh-lair-ee]

PART OF SPEECH: [noun/verb/adjective/etc.]

DEFINITIONS:
1. [First definition]
2. [Second definition if applicable]

SYNONYMS: [list synonyms]

ANTONYMS: [list antonyms]

USAGE EXAMPLES:
- [Example sentence 1]
- [Example sentence 2]
- [Example sentence 3]

ETYMOLOGY: [Brief origin of the word]

COMMON PHRASES:
- [Phrase 1]
- [Phrase 2]

IMPORTANT: 
- Use simple syllable-based pronunciation (SEN-si-tiv) NOT IPA symbols
- Use TWO newlines (blank lines) between major sections
- Keep it clear and well-spaced at least 1 to 2 lines gap accordingly for readability"
    
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
