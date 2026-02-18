# sheets-formula.ps1
# Generates Google Sheets formulas from natural language

param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    $apiKey = $env:OPENAI_API_KEY
    
    $request = [System.Windows.Forms.Clipboard]::GetText()
    
    if (-not $request -or $request.Length -eq 0) {
        Write-Output "ERROR: No request in clipboard. Copy your formula request first."
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
    
    $systemPrompt = "You are a Google Sheets formula expert. Convert natural language requests into Google Sheets formulas.

CRITICAL: Return ONLY the formula itself. No explanations, no examples, no text before or after. Just the raw formula ready to paste directly into a cell.

Examples:
User: 'sum a1 to d7'
You: =SUM(A1:D7)

User: 'average of column B'
You: =AVERAGE(B:B)

User: 'count non-empty cells in range A1 to A100'
You: =COUNTA(A1:A100)

Return ONLY the formula."
    
    $escapedSystem = Escape-JsonString $systemPrompt
    $escapedRequest = Escape-JsonString $request
    
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
      "content": "$escapedRequest"
    }
  ],
  "temperature": 0.1,
  "max_tokens": 100
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
