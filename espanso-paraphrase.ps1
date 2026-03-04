$apiKey = $env:OPENAI_API_KEY

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {

    $body = @{
        model    = "gpt-4o-mini"
        messages = @(
            @{
                role    = "system"
                content = "You are a professional writing assistant. Paraphrase the given text with these rules:
1. Fix all grammar, spelling, and punctuation errors
2. Replace casual or informal words with professional office-appropriate alternatives
3. Keep the same meaning and intent — do not add or remove information
4. Use clear, concise, formal language suitable for business communication
5. Return ONLY the paraphrased text — no explanations, no labels, no quotes"
            }
            @{
                role    = "user"
                content = $originalText
            }
        )
        temperature = 0.4
        max_tokens  = 2000
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json; charset=utf-8"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Method Post `
            -Headers $headers `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
            -TimeoutSec 30

        $reply = $response.choices[0].message.content.Trim()

        if ($reply) {
            [System.Windows.Forms.Clipboard]::SetText($reply)
            Start-Sleep -Milliseconds 50
            Write-Output $reply
        }

    } catch {
        $errorMsg = "Error: Unable to paraphrase"
        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = ($_.ErrorDetails.Message | ConvertFrom-Json)
                $errorMsg  = $errorJson.error.message
            } catch {
                $errorMsg = $_.Exception.Message
            }
        }
        Write-Output $errorMsg
    }
}
