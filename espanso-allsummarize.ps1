$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds 100
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("^c")
Start-Sleep -Milliseconds 300

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $originalText = $originalText -replace ":allsummarize$", ""
    $originalText = $originalText.Trim()

    $messages = @(
        @{
            role    = "system"
            content = @"
You are a professional summarizer. Create a clear, concise summary of the input text.

RULES:
- Extract the main points and key information
- Keep it brief but comprehensive
- Maintain the original meaning and context
- Use clear, simple language
- Focus on the most important information
- Do NOT use markdown, formatting, or styling unless explicitly asked
- If an answer must be long: Use clear spacing and line breaks. Do NOT use markdown syntax
- If a specific format is requested: Follow that format exactly. If no format is requested, respond in plain text
- Avoid emojis
- Use ASCII characters only (UTF-8 unsafe symbols not allowed)
"@
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3 -MaxTokens 1000
    if ($reply) { Write-Output $reply }
}
