$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()
$targetLanguage = $args[0]

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You are a translator. Translate the text to $targetLanguage accurately. Output ONLY the translated text. No explanation, no alternatives, no original text, no preamble, no quotes, no markdown."
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages
    if ($reply) { Write-Output $reply }
} else {
    Write-Output "No text to translate"
}
