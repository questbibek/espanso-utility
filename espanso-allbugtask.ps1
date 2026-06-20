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
    $originalText = $originalText -replace ":allbugtask$", ""
    $originalText = $originalText.Trim()

    $messages = @(
        @{
            role    = "system"
            content = @"
You are a bug report formatter. Convert the input into a properly structured bug report.

FORMAT:
Bug Title: [Clear, concise title]

Description:
[Brief description of the bug]

Steps to Reproduce:
1. [First step]
2. [Second step]
3. [Third step]

Expected Behavior:
[What should happen]

Actual Behavior:
[What actually happens]

Priority: [Critical/High/Medium/Low]

Environment:
- Browser/Device: [if applicable]
- OS: [if applicable]
- Version: [if applicable]

RULES:
- Extract information from the input
- Use bullet points for clarity
- If information is missing, mark as [To be determined]
- Keep it concise and professional
- Infer priority based on severity if not mentioned
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
