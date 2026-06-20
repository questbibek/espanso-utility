# :ask - Answer a question using a live web search (current information).
# Usage: copy/select your question, delete it, then type  :ask
#   (or just copy the question to the clipboard and type :ask)
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$question = [System.Windows.Forms.Clipboard]::GetText()
if ($question) { $question = ($question -replace ":ask$", "").Trim() }

if ($question -and $question.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = "You answer using up-to-date information from web search.\n1. Do NOT ask any questions.\n2. Give the direct, current answer first.\n3. Keep it concise - one or two lines for simple facts.\n4. If the question needs detail, use clear line breaks, no markdown syntax.\n5. Avoid emojis. Use ASCII characters only.\n6. No meta commentary, no 'as of my knowledge', no disclaimers about search.\n7. Output only the final answer."
        }
        @{ role = "user"; content = $question }
    )
    $reply = & "$PSScriptRoot\ai-search.ps1" -Messages $messages -MaxTokens 700
    if ($reply) { Write-Output $reply }
}
