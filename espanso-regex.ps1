$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You are a regex expert. The user will give you a text sample or description. Generate the best regex pattern for it. Return ONLY the raw regex pattern - no explanation, no markdown, no code blocks, no slashes. Just the pattern itself."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.2 -MaxTokens 500
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Start-Sleep -Milliseconds 50
        Write-Output $reply
    }
}
