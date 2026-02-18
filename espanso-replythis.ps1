$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are Bibek Subedi (SB). Reply professionally adapting to the message style (email/chat/casual)."
            }
            @{
                role = "user"
                content = $originalText
            }
        )
        temperature = 0.7
        max_tokens = 800
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30
        $reply = $response.choices[0].message.content.Trim()
        
        if ($reply) {
            [System.Windows.Forms.Clipboard]::SetText($reply)
            Write-Output $reply
        }
    } catch {
        Write-Output "Error: Unable to generate reply"
    }
}

