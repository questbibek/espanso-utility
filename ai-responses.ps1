# Web-grounded helper built on OpenAI's Responses API + the `web_search` tool.
# Unlike ai-search.ps1 (chat-completions `web_search_options`, which only works
# on *-search-preview models), this path works with general models like gpt-5.1,
# so it powers :factcheck.
#
# Usage: & "$PSScriptRoot\ai-responses.ps1" -Messages $messages [-Model gpt-5.1] [-MaxTokens 700]
#
# Needs OPENAI_API_KEY. The system message (if any) becomes `instructions`;
# the remaining messages are joined into `input`.
param(
    [Parameter(Mandatory=$true)]
    [object[]]$Messages,
    [string]$Model,
    [int]$MaxTokens = 0
)

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$key = $env:OPENAI_API_KEY
$url = "https://api.openai.com/v1/responses"
if (-not $Model) { $Model = if ($env:OPENAI_FACTCHECK_MODEL) { $env:OPENAI_FACTCHECK_MODEL } else { "gpt-5.1" } }

if (-not $key) {
    Write-Output "Error: OPENAI_API_KEY is not set. Add it to .env and run setup-espanso.ps1 (or load-env.ps1)."
    return
}

$instructions = ($Messages | Where-Object { $_.role -eq "system" } | ForEach-Object { $_.content }) -join "`n`n"
$input        = ($Messages | Where-Object { $_.role -ne "system" } | ForEach-Object { $_.content }) -join "`n`n"

$bodyHash = @{
    model = $Model
    input = $input
    tools = @(@{ type = "web_search" })
}
if ($instructions) { $bodyHash.instructions = $instructions }
if ($MaxTokens -gt 0) { $bodyHash.max_output_tokens = $MaxTokens }

$json    = $bodyHash | ConvertTo-Json -Depth 10
$headers = @{
    "Authorization" = "Bearer $key"
    "Content-Type"  = "application/json; charset=utf-8"
}

try {
    $resp = Invoke-RestMethod -Uri $url -Method Post -Headers $headers `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 60

    $content = (
        $resp.output |
        Where-Object { $_.type -eq "message" } |
        ForEach-Object { $_.content } |
        Where-Object { $_.type -eq "output_text" } |
        ForEach-Object { $_.text }
    ) -join "`n"

    if (-not $content -or $content.Length -eq 0) { throw "Empty response from OpenAI" }
    Write-Output $content.Trim()
} catch {
    Write-Output "Error: web search failed ($Model): $($_.Exception.Message)"
}
