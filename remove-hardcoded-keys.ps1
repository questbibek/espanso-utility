# =============================================
# remove-hardcoded-keys.ps1
# Run ONCE to clean all .ps1 files in espanso-utility
# Replaces hardcoded API keys with $env: references
#
# HOW TO RUN:
#   Open PowerShell and run:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\unrav\espanso-utility\remove-hardcoded-keys.ps1"
# =============================================

# Auto-detect the folder this script is in
$TargetDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $TargetDir) { $TargetDir = "$env:USERPROFILE\espanso-utility" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Removing Hardcoded Keys from Scripts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Folder: $TargetDir"
Write-Host ""

if (-not (Test-Path $TargetDir)) {
    Write-Host "ERROR: $TargetDir not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$modifiedCount = 0

Get-ChildItem "$TargetDir\*.ps1" | Where-Object { $_.Name -ne "remove-hardcoded-keys.ps1" -and $_.Name -ne "load-env.ps1" } | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    $changes = @()

    # ---- Pattern 1: OpenAI key as $apiKey = "sk-proj-..." ----
    if ($content -match 'apiKey\s*=\s*"sk-proj-') {
        $content = [regex]::Replace($content, '\$apiKey\s*=\s*"sk-proj-[^"]*"', '$apiKey = $env:OPENAI_API_KEY')
        $changes += "OPENAI_API_KEY (apiKey)"
    }

    # ---- Pattern 2: OpenAI key as $openaiApiKey = "sk-proj-..." ----
    if ($content -match 'openaiApiKey\s*=\s*"sk-proj-') {
        $content = [regex]::Replace($content, '\$openaiApiKey\s*=\s*"sk-proj-[^"]*"', '$openaiApiKey = $env:OPENAI_API_KEY')
        $changes += "OPENAI_API_KEY (openaiApiKey)"
    }

    # ---- Pattern 3: OCR.space key ($apiKey = "K8870...") ----
    if ($content -match 'apiKey\s*=\s*"K\d{10') {
        $content = [regex]::Replace($content, '\$apiKey\s*=\s*"K\d{10,}"', '$apiKey = $env:OCR_SPACE_API_KEY')
        $changes += "OCR_SPACE_API_KEY"
    }

    # ---- Pattern 4: Cloudinary cloud name ----
    if ($content -match 'cloudName\s*=\s*"[a-z0-9]+"') {
        $content = [regex]::Replace($content, '\$cloudName\s*=\s*"[a-z0-9]+"', '$cloudName = $env:CLOUDINARY_CLOUD_NAME')
        $changes += "CLOUDINARY_CLOUD_NAME"
    }

    # ---- Pattern 5: Cloudinary upload preset ----
    if ($content -match 'uploadPreset\s*=\s*"[a-z0-9]+"') {
        $content = [regex]::Replace($content, '\$uploadPreset\s*=\s*"[a-z0-9]+"', '$uploadPreset = $env:CLOUDINARY_UPLOAD_PRESET')
        $changes += "CLOUDINARY_UPLOAD_PRESET"
    }

    # ---- Pattern 6: Hardcoded user paths ----
    if ($content -match 'C:\\Users\\unrav\\espanso-utility') {
        $content = $content.Replace('C:\Users\unrav\espanso-utility', '$env:USERPROFILE\espanso-utility')
        $changes += "Hardcoded user path"
    }

    # ---- Save if modified ----
    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        $modifiedCount++
        Write-Host "  CLEANED: $($file.Name)" -ForegroundColor Green
        foreach ($change in $changes) {
            Write-Host "           -> $change" -ForegroundColor Gray
        }
    } else {
        Write-Host "  SKIPPED: $($file.Name)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Done! Modified $modifiedCount file(s)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Now run load-env.ps1 to set environment variables." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"