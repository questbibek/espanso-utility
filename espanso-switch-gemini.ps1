Add-Type -AssemblyName System.Windows.Forms
$envFile = "$PSScriptRoot\.env"
if (Test-Path $envFile) {
    $raw = [System.IO.File]::ReadAllText($envFile, [System.Text.Encoding]::UTF8)
    if ($raw -match '(?m)^AI_PRIMARY=') {
        $raw = $raw -replace '(?m)^AI_PRIMARY=.*', 'AI_PRIMARY=gemini'
    } else {
        $raw = $raw.TrimEnd() + "`r`nAI_PRIMARY=gemini`r`n"
    }
    [System.IO.File]::WriteAllText($envFile, $raw, [System.Text.Encoding]::UTF8)
}
[System.Environment]::SetEnvironmentVariable("AI_PRIMARY", "gemini", "User")
$env:AI_PRIMARY = "gemini"
Write-Output "Primary AI: Gemini"
