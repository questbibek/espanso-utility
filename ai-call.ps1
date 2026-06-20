# Shared AI provider helper. All espanso AI scripts call this.
# Usage: & "$PSScriptRoot\ai-call.ps1" -Messages $messages [-Temperature 0.3] [-MaxTokens 500]
param(
    [Parameter(Mandatory=$true)]
    [object[]]$Messages,
    [double]$Temperature = -1,
    [int]$MaxTokens = 0,
    [switch]$ShowProvider
)

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$providers = @{
    gemini = @{
        Url   = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        Key   = $env:GEMINI_API_KEY
        Model = if ($env:GEMINI_MODEL) { $env:GEMINI_MODEL } else { "gemini-2.0-flash" }
    }
    groq = @{
        Url   = "https://api.groq.com/openai/v1/chat/completions"
        Key   = $env:GROQ_API_KEY
        Model = if ($env:GROQ_MODEL) { $env:GROQ_MODEL } else { "llama-3.3-70b-versatile" }
    }
}

$primaryName  = if ($env:AI_PRIMARY -and $providers.ContainsKey($env:AI_PRIMARY.ToLower())) { $env:AI_PRIMARY.ToLower() } else { "gemini" }
$fallbackName = if ($primaryName -eq "gemini") { "groq" } else { "gemini" }

function Invoke-Provider {
    param([string]$Name, [object[]]$Msgs, [double]$Temp, [int]$MaxTok)
    $p = $providers[$Name]
    if (-not $p.Key) { throw "No API key configured for $Name" }

    $bodyHash = @{
        model    = $p.Model
        messages = $Msgs
    }
    if ($Temp -ge 0)   { $bodyHash.temperature = $Temp }
    if ($MaxTok -gt 0) { $bodyHash.max_tokens  = $MaxTok }

    $json = $bodyHash | ConvertTo-Json -Depth 10
    $headers = @{
        "Authorization" = "Bearer $($p.Key)"
        "Content-Type"  = "application/json; charset=utf-8"
    }

    $resp    = Invoke-RestMethod -Uri $p.Url -Method Post -Headers $headers `
                   -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 30
    $content = $resp.choices[0].message.content
    if (-not $content -or $content.Length -eq 0) { throw "Empty response from $Name" }
    return $content.Trim()
}

$primaryError = $null
$result = $null
$usedProvider = $null

try {
    $result = Invoke-Provider -Name $primaryName -Msgs $Messages -Temp $Temperature -MaxTok $MaxTokens
    $usedProvider = $primaryName
} catch {
    $primaryError = $_.Exception.Message
}

if ($usedProvider) {
    if ($ShowProvider) { Write-Output "$result`n[via $usedProvider]" } else { Write-Output $result }
    return
}

try {
    $result = Invoke-Provider -Name $fallbackName -Msgs $Messages -Temp $Temperature -MaxTok $MaxTokens
    $usedProvider = $fallbackName
    if ($ShowProvider) { Write-Output "$result`n[via $usedProvider]" } else { Write-Output $result }
} catch {
    $fallbackError = $_.Exception.Message
    Write-Output "Error: both AI providers failed. Primary ($primaryName): $primaryError | Fallback ($fallbackName): $fallbackError"
}
