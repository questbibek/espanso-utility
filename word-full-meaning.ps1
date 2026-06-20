# word-full-meaning.ps1
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
Provide a COMPREHENSIVE analysis of the word. Use DOUBLE line breaks between sections for readability:

WORD: [word]
PRONUNCIATION: [SYL-la-ble format, e.g., SEN-si-tiv or voh-KAB-yuh-lair-ee]

PART OF SPEECH: [noun/verb/adjective/etc.]

DEFINITIONS:
1. [First definition]
2. [Second definition if applicable]

SYNONYMS: [list synonyms]

ANTONYMS: [list antonyms]

USAGE EXAMPLES:
- [Example sentence 1]
- [Example sentence 2]
- [Example sentence 3]

ETYMOLOGY: [Brief origin of the word]

COMMON PHRASES:
- [Phrase 1]
- [Phrase 2]

IMPORTANT:
- Use simple syllable-based pronunciation (SEN-si-tiv) NOT IPA symbols
- Use TWO newlines (blank lines) between major sections
- Keep it clear and well-spaced at least 1 to 2 lines gap accordingly for readability
"@
        }
        @{ role = "user"; content = $word }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3
    Write-Output $result

} catch {
    Write-Output "Error: $_"
}
