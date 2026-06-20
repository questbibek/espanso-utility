Add-Type -AssemblyName System.Windows.Forms
$envFile = "$PSScriptRoot\.env"
if (Test-Path $envFile) {
    $raw = [System.IO.File]::ReadAllText($envFile, [System.Text.Encoding]::UTF8)
    if ($raw -match '(?m)^AI_PRIMARY=') {
        $raw = $raw -replace '(?m)^AI_PRIMARY=.*', 'AI_PRIMARY=groq'
    } else {
        $raw = $raw.TrimEnd() + "`r`nAI_PRIMARY=groq`r`n"
    }
    [System.IO.File]::WriteAllText($envFile, $raw, [System.Text.Encoding]::UTF8)
}
[System.Environment]::SetEnvironmentVariable("AI_PRIMARY", "groq", "User")
$env:AI_PRIMARY = "groq"
Write-Output "Primary AI: Groq"
