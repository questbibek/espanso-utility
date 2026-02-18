$apiKey = $env:OPENAI_API_KEY

# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# Wait for clipboard to be ready
Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    
    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a grammar correction assistant. Fix grammar, spelling, and punctuation errors while preserving the original meaning and tone. Return ONLY the corrected text without explanations."
            }
            @{
                role = "user"
                content = $originalText
            }
        )
        temperature = 0.3
        max_tokens = 2000
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30
        $reply = $response.choices[0].message.content.Trim()
        
        if ($reply) {
            # Update clipboard with corrected text
            [System.Windows.Forms.Clipboard]::SetText($reply)
            
            # Wait for clipboard to be filled
            Start-Sleep -Milliseconds 50
            
            # Output the corrected text (Espanso will type it to replace :fg/:fixgrammar)
            Write-Output $reply
        }
        
    } catch {
        $errorMsg = "Error: Unable to fix grammar"
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
