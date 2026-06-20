# caption-social.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $context = [System.Windows.Forms.Clipboard]::GetText()

    if (-not $context -or $context.Length -eq 0) {
        Write-Output "ERROR: No context in clipboard. Copy some text first."
        exit 1
    }

    $messages = @(
        @{
            role    = "system"
            content = @"
Generate ONE universal social media caption that works across all platforms (LinkedIn, Twitter/X, Instagram, Facebook).

Requirements:
- NO emojis whatsoever
- Professional yet engaging tone
- Hook attention in first line
- 2-3 sentences maximum
- Include 3-5 relevant hashtags at the end
- Clear and concise
- Works for both personal and business content

Output ONLY the caption text, nothing else.
"@
        }
        @{ role = "user"; content = $context }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.7 -MaxTokens 200
    Write-Output $result

} catch {
    Write-Output "Error: $($_.Exception.Message)"
}
