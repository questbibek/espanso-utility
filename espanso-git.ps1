$apiKey = $env:OPENAI_API_KEY

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a Git expert. The user describes what they want to do with git. Return ONLY the exact git command ready to run — no explanation, no markdown, no code blocks, no comments. Just the raw command."
            }
            @{
                role = "user"
                content = $originalText
            }
        )
        temperature = 0.1
        max_tokens = 300
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
            Start-Sleep -Milliseconds 50
            Write-Output $reply
        }
    } catch {
        $errorMsg = "Error: Unable to generate git command"
        if ($_.ErrorDetails.Message) {
            try { $errorMsg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch { $errorMsg = $_.Exception.Message }
        }
        Write-Output $errorMsg
    }
}
