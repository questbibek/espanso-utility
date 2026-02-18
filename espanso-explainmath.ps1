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
                content = "You are a math tutor. Solve step-by-step with clear explanations. Use plain ASCII only (x^2 for squared, sqrt(x) for square root). No LaTeX or special symbols. Use clear spacing and line breaks. Be educational but concise."
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
        $explanation = $response.choices[0].message.content.Trim()
        
        if ($explanation) {
            Write-Output $explanation
        }
        
    } catch {
        Write-Output "Error: Unable to solve"
    }
}

