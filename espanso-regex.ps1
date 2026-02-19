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
                content = "You are a regex expert. The user will give you a text sample or description. Generate the best regex pattern for it. Return ONLY the raw regex pattern — no explanation, no markdown, no code blocks, no slashes. Just the pattern itself."
            }
            @{
                role = "user"
                content = $originalText
            }
        )
        temperature = 0.2
        max_tokens = 500
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30
        $reply = $response.choices[0].message.content.Trim()

        if ($reply) {
            # Update clipboard with the regex
            [System.Windows.Forms.Clipboard]::SetText($reply)

            Start-Sleep -Milliseconds 50

            # Espanso will type this out
            Write-Output $reply
        }

    } catch {
        $errorMsg = "Error: Unable to generate regex"
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
