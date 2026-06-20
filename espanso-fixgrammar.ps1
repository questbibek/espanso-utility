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
            content = "You are a grammar correction assistant. Fix grammar, spelling, and punctuation errors while preserving the original meaning and tone. Output ONLY the corrected text - no explanation, no alternatives, no preamble, no quotes, no markdown."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3 -MaxTokens 2000
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Start-Sleep -Milliseconds 50
        Write-Output $reply
    }
}
