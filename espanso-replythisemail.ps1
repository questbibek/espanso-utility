$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You are Bibek Subedi. Write a professional email reply. Start with 'Hi [Persons name if there is without brackets]', keep it concise, end with 'Best regards, Bibek'."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7 -MaxTokens 800
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Write-Output $reply
    }
}
