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
$targetLanguage = $args[0]

if ($originalText -and $originalText.Length -gt 0 -and $targetLanguage) {
    $originalText = $originalText -replace ":all.*$", ""
    $originalText = $originalText.Trim()

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
