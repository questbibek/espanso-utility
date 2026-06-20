$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = @"
You are a user story formatter for project management. Convert the input into a properly structured user story.

FORMAT:
User Story: As a [user type], I want to [action] so that [benefit]

Description:
[Brief description of the feature/functionality]

Acceptance Criteria:
1. [Specific, testable criterion]
2. [Specific, testable criterion]
3. [Specific, testable criterion]

Priority: [Critical/High/Medium/Low]

Estimated Effort: [Story Points or Time estimate]

Notes:
[Any additional context, dependencies, or technical considerations]

RULES:
- Extract information from the input
- Write clear, specific acceptance criteria
- If information is missing, mark as [To be determined]
- Keep it concise and actionable
- Focus on user value and business outcomes
- Infer priority based on business impact if not mentioned
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
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Write-Output $reply
    }
}
