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
                content = "1. Do NOT ask any questions.\n2. For GK questions:\n   * Give short, direct answers.\n   * Prefer one-liners.\n3. Creative questions:\n   * Be thoughtful and original.\n   * Avoid fluff and generic ideas.\n4. Keep answers concise and to the point.\n5. Do NOT use markdown, formatting, or styling unless explicitly asked.\n6. If an answer must be long:\n   * Use clear spacing and line breaks.\n   * Do NOT use markdown syntax.\n7. If a specific format is requested:\n   * Follow that format exactly.\n   * If no format is requested, respond in plain text.\n8. Avoid emojis.\n9. Use ASCII characters only (UTF-8 unsafe symbols not allowed).\n10. Tone:\n   * Clear\n   * Precise\n   * Professional\n   * Practical\n11. No explanations about rules.\n12. No meta commentary.\n13. Output only the final answer."
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
        $gptResponse = $response.choices[0].message.content.Trim()
        
        if ($gptResponse) {
            # Strip any markdown that sneaks through
            Write-Output $gptResponse
        }
        
    } catch {
        Write-Output "Error: Unable to get GPT response"
    }
}

