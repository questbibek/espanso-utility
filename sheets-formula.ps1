# sheets-formula.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $request = [System.Windows.Forms.Clipboard]::GetText()

    if (-not $request -or $request.Length -eq 0) {
        Write-Output "ERROR: No request in clipboard. Copy your formula request first."
        exit 1
    }

    $messages = @(
        @{
            role    = "system"
            content = @"
You are a Google Sheets formula expert. Convert natural language requests into Google Sheets formulas.

CRITICAL: Return ONLY the formula itself. No explanations, no examples, no text before or after. Just the raw formula ready to paste directly into a cell.

Examples:
User: 'sum a1 to d7'
You: =SUM(A1:D7)

User: 'average of column B'
You: =AVERAGE(B:B)

User: 'count non-empty cells in range A1 to A100'
You: =COUNTA(A1:A100)

Return ONLY the formula.
"@
        }
        @{ role = "user"; content = $request }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.1 -MaxTokens 100
    Write-Output $result

} catch {
    Write-Output "Error: $($_.Exception.Message)"
}
