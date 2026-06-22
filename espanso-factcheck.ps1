# :factcheck - Verify a claim against a live web search.
# Usage: copy/select the claim, delete it, then type  :factcheck
#   (or just copy the claim to the clipboard and type :factcheck)
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$claim = [System.Windows.Forms.Clipboard]::GetText()
if ($claim) { $claim = ($claim -replace ":factcheck$", "").Trim() }

if ($claim -and $claim.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You are a fact-checker. Verify the user's claim using current web search results.\n1. Do NOT ask any questions.\n2. Start with a one-word verdict on its own line: TRUE, FALSE, MISLEADING, or UNVERIFIED.\n3. Then one or two plain-text lines explaining why, citing what the current facts are.\n4. End with a 'Source:' line giving the most authoritative source (name and/or URL).\n5. No markdown syntax. Avoid emojis. Use ASCII characters only.\n6. No meta commentary or disclaimers about being an AI."
        }
        @{ role = "user"; content = "Fact-check this claim: $claim" }
    )
    $reply = & "$PSScriptRoot\ai-responses.ps1" -Messages $messages -MaxTokens 700
    if ($reply) { Write-Output $reply }
}
