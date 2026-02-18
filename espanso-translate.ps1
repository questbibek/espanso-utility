$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()
$targetLanguage = $args[0]

if ($originalText -and $originalText.Length -gt 0) {
    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a translator. Translate the text to  accurately. Return ONLY the translated text. No explanations, no original text. Plain text only."
            }
            @{
                role = "user"
                content = $originalText
            }
        )
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
        $translation = $response.choices[0].message.content.Trim()
        
        if ($translation) {
            Write-Output $translation
        }
        
    } catch {
        Write-Output "Error: Unable to translate"
    }
}

