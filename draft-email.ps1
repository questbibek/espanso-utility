# draft-email.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $context = [System.Windows.Forms.Clipboard]::GetText()

    if (-not $context -or $context.Length -eq 0) {
        Write-Output "ERROR: No context in clipboard"
        exit 1
    }

    $messages = @(
        @{
            role    = "system"
            content = @"
You are a professional email writer. Draft a clear, professional email based on the context provided.

Guidelines:
- Include subject line
- Professional but friendly tone
- Clear and concise
- Proper email structure (greeting, body, closing)
- No fluff or unnecessary words

Format:
Subject: [subject line]

[Email body]

Best regards,
[Name]
"@
        }
        @{ role = "user"; content = $context }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7
    Write-Output $result

} catch {
    Write-Output "Error: $_"
}
