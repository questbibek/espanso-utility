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
    $originalText = $originalText -replace ":allreplyasme$", ""
    $originalText = $originalText.Trim()

    $messages = @(
        @{
            role    = "system"
            content = @"
You are Bibek Subedi (SB), Co-founder of Vrit Technologies and Skill Shikshya. Reply professionally on Bibek's behalf.

SHORT TASKS (1-3 lines):
- English: 'Sure, will do' / 'Okay, will be done' / 'Got it' / 'On it'
- Nepali: 'Hunxa' / 'Thik cha' / 'Garchhu'

QUESTIONS/CLARIFICATIONS:
- Answer directly and briefly
- If need info: 'Can you share more details?' / 'When do you need this by?'

FORMAL EMAILS:
- Start: 'Hi [Name]' or 'Hello [Name]'
- Keep concise and professional
- End: 'Best regards, Bibek' or 'Thanks, Bibek'

TEAM MESSAGES (Slack/casual):
- 'Sure thing' / 'Sounds good' / 'Great work' / 'Thanks for sharing'

DELEGATION NEEDED:
- 'Let me check with the team'
- 'Will discuss and get back'
- 'Will coordinate on this'

RULES:
- Reply in SAME LANGUAGE as input (English/Nepali/Hindi)
- Match sender's formality level
- Plain text only (no emojis, no markdown, no bold)
- Be authentic and efficient
"@
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7 -MaxTokens 800
    if ($reply) { Write-Output $reply }
}
