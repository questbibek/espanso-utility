# content-video.ps1
# Generates video content ideas with authority, virality, and branding scores

param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    $apiKey = $env:OPENAI_API_KEY
    
    $topic = [System.Windows.Forms.Clipboard]::GetText()
    
    if (-not $topic -or $topic.Length -eq 0) {
        Write-Output "ERROR: No topic in clipboard. Copy your video topic first."
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
    
    $systemPrompt = "Generate 3 video content ideas based on the topic. For each idea, provide:

TITLE: [catchy title]

HOOK: [first 5 seconds to stop scrolling]

SCRIPT OUTLINE:
- [key point 1]
- [key point 2]
- [key point 3]
- [key point 4]

VISUALS:
- [visual 1]
- [visual 2]
- [visual 3]

CALL TO ACTION: [specific CTA]

SCORES:
Authority: [1-10]
Virality: [1-10]
Branding: [1-10]

---

Use this EXACT format with proper spacing between sections. Add a line of dashes (---) between each idea for clear separation."
    
    $escapedSystem = Escape-JsonString $systemPrompt
    $escapedTopic = Escape-JsonString $topic
    
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
      "content": "Topic: $escapedTopic"
    }
  ],
  "temperature": 0.8
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
