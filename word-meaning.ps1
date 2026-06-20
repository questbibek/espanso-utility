# word-meaning.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $word = [System.Windows.Forms.Clipboard]::GetText()
    $word = $word.Trim()

    if (-not $word -or $word.Length -eq 0) {
        Write-Output "ERROR: No word in clipboard"
        exit 1
    }

    $messages = @(
        @{
            role    = "system"
            content = @"
Provide a SHORT, CONCISE definition of the word. Format:

[word] ([part of speech]) - [one-line definition]

Example: ephemeral (adj.) - lasting for a very short time

Keep it to ONE line. Be clear and practical.
"@
        }
        @{ role = "user"; content = $word }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3
    Write-Output $result

} catch {
    Write-Output "Error: $_"
}
