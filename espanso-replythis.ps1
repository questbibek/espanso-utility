$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You are Bibek Subedi (SB). Reply professionally adapting to the message style (email/chat/casual)."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7 -MaxTokens 800
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Write-Output $reply
    }
}
