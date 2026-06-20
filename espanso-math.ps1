$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ([string]::IsNullOrWhiteSpace($originalText)) {
    Write-Output "No text in clipboard"
} else {
    $messages = @(
        @{
            role    = "system"
            content = "You are a helpful mathematical calculator assistant. Evaluate the mathematical expression provided and return only the numerical result without any explanation or additional text."
        }
        @{ role = "user"; content = "Calculate: $originalText" }
    )
    $answer = & "$PSScriptRoot\ai-call.ps1" -Messages $messages
    if ($answer) { Write-Output $answer } else { Write-Output "No answer received" }
}
