# =============================================
# load-env.ps1
# Loads API keys from .env into User Environment Variables
# Run ONCE after setup (or after changing keys)
# Scripts then use $env:GEMINI_API_KEY, $env:GROQ_API_KEY etc. at runtime
# =============================================

param(
    [string]$EnvFile = "$env:USERPROFILE\espanso-utility\.env"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading .env into Environment Variables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---- Check .env file ----
if (-not (Test-Path $EnvFile)) {
    Write-Host "  .env not found at: $EnvFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Create it with:" -ForegroundColor Yellow
    Write-Host "    copy $env:USERPROFILE\espanso-utility\.env.example $env:USERPROFILE\espanso-utility\.env" -ForegroundColor White
    Write-Host "    notepad $env:USERPROFILE\espanso-utility\.env" -ForegroundColor White
    exit 1
}

# ---- Parse and set environment variables ----
$loaded = 0

Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()

    # Skip comments and empty lines
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Length -eq 2) {
            $key   = $parts[0].Trim()
            $value = $parts[1].Trim()

            # Skip placeholder values
            if ($value -match "^your_" -or $value -eq "") {
                Write-Host "  SKIPPED: $key (not configured)" -ForegroundColor DarkYellow
                return
            }

            # Set as User environment variable (persists across reboots)
            [System.Environment]::SetEnvironmentVariable($key, $value, "User")

            # Also set for current session
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")

            # Display (masked)
            $masked = $value.Substring(0, [Math]::Min(8, $value.Length)) + "..."
            Write-Host "  SET: $key = $masked" -ForegroundColor Green
            $loaded++
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Loaded $loaded environment variable(s)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Variables are set permanently (User level)." -ForegroundColor White
Write-Host "  They persist across reboots and terminal sessions." -ForegroundColor White
Write-Host ""

# ---- Restart Espanso automatically so it picks up the new vars ----
$espanso = Get-Command espanso -ErrorAction SilentlyContinue
if ($espanso) {
    $running = Get-Process -Name "espanso" -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Restarting Espanso..." -ForegroundColor Yellow
        & espanso restart 2>$null
        Start-Sleep -Seconds 1
        $still = Get-Process -Name "espanso" -ErrorAction SilentlyContinue
        if ($still) {
            Write-Host "  Espanso restarted OK." -ForegroundColor Green
        } else {
            Write-Host "  Espanso restart sent (may take a moment)." -ForegroundColor Green
        }
    } else {
        Write-Host "  Espanso is not running - start it and the new vars will be loaded automatically." -ForegroundColor Yellow
    }
} else {
    Write-Host "  espanso not in PATH - start or restart it manually to pick up the new vars." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Test it:" -ForegroundColor Yellow
Write-Host "    echo `$env:GEMINI_API_KEY" -ForegroundColor White
Write-Host ""
