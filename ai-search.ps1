# Web-grounded AI helper. Uses OpenAI's search-preview models, which run a
# live web search before answering - so questions about current events
# (latest news, "who is PM of Nepal", today's prices, etc.) get fresh answers
# instead of a stale training-cutoff guess.
#
# Usage: & "$PSScriptRoot\ai-search.ps1" -Messages $messages [-MaxTokens 600]
#
# Needs OPENAI_API_KEY in the environment. Optional OPENAI_SEARCH_MODEL
# (default gpt-4o-mini-search-preview). Note: search-preview models do NOT
# accept a temperature param, so it is intentionally not sent.
param(
    [Parameter(Mandatory=$true)]
    [object[]]$Messages,
    [int]$MaxTokens = 0
)

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$key   = $env:OPENAI_API_KEY
$model = if ($env:OPENAI_SEARCH_MODEL) { $env:OPENAI_SEARCH_MODEL } else { "gpt-4o-mini-search-preview" }
$url   = "https://api.openai.com/v1/chat/completions"

if (-not $key) {
    Write-Output "Error: OPENAI_API_KEY is not set. Add it to .env and run setup-espanso.ps1 (or load-env.ps1)."
    return
}

$bodyHash = @{
    model              = $model
    messages           = $Messages
    web_search_options = @{}
}
if ($MaxTokens -gt 0) { $bodyHash.max_tokens = $MaxTokens }

$json    = $bodyHash | ConvertTo-Json -Depth 10
$headers = @{
    "Authorization" = "Bearer $key"
    "Content-Type"  = "application/json; charset=utf-8"
}

try {
    $resp    = Invoke-RestMethod -Uri $url -Method Post -Headers $headers `
                   -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 45
    $content = $resp.choices[0].message.content
    if (-not $content -or $content.Length -eq 0) { throw "Empty response from OpenAI" }
    Write-Output $content.Trim()
} catch {
    Write-Output "Error: web search failed ($model): $($_.Exception.Message)"
}
