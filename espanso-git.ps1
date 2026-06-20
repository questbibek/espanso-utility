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
            content = "You are a Git expert. The user describes what they want to do with git. Return ONLY the exact git command ready to run - no explanation, no markdown, no code blocks, no comments. Just the raw command."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.1 -MaxTokens 300
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Start-Sleep -Milliseconds 50
        Write-Output $reply
    }
}
