# =============================================================
#  ESPANSO SETUP (Windows) - interactive, re-runnable
#  Runs from ANY folder. Safe to run repeatedly: keeps existing
#  keys, only asks about what's missing or what you choose to change.
#  Secrets are masked on screen.
#
#  Providers: GPT (primary) + Gemini/Groq (fallback), or swap via AI_PRIMARY.
#
#  RUN in PowerShell (from anywhere - Downloads, the repo, etc.):
#    Unblock-File .\setup-espanso.ps1
#    powershell -ExecutionPolicy Bypass -File .\setup-espanso.ps1
#  (works the same in pwsh 7: pwsh -ExecutionPolicy Bypass -File .\setup-espanso.ps1)
#
#  ONE-SHOT (unattended) install - no questions, accepts all defaults,
#  skips any API key that isn't already in .env (re-run later to add them):
#    powershell -ExecutionPolicy Bypass -File .\setup-espanso.ps1 -Yes
# =============================================================

param(
    [Alias('Unattended','NonInteractive','y')]
    [switch]$Yes   # one-shot: accept all defaults, never prompt, skip missing keys
)

$ErrorActionPreference = "Continue"
$AUTO = [bool]$Yes

$UtilDir   = Join-Path $env:USERPROFILE "espanso-utility"
$ConfigDir = Join-Path $env:APPDATA "espanso"
$EnvFile   = Join-Path $UtilDir ".env"
$UtilRepo  = "https://github.com/questbibek/espanso-utility.git"
$ConfRepo  = "https://github.com/questbibek/espanso.git"
$EspansoVer = "2.3.0"   # used for the official-installer fallback

function Title($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Info($m){ Write-Host "  > $m" -ForegroundColor Gray }
function Good($m){ Write-Host "  OK $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  ! $m" -ForegroundColor Yellow }

function Confirm-Step([string]$Question,[bool]$Default=$true){
    if($script:AUTO){
        Write-Host "$Question -> $(if($Default){'yes'}else{'no'}) (auto)" -ForegroundColor DarkGray
        return $Default
    }
    $suffix = if($Default){"[Y/n]"}else{"[y/N]"}
    $a = Read-Host "$Question $suffix"
    if([string]::IsNullOrWhiteSpace($a)){ return $Default }
    return $a.Trim().ToLower().StartsWith('y')
}

# Free-text prompt that returns "" (use default / skip) in one-shot mode.
function Read-Opt([string]$Prompt){
    if($script:AUTO){ return "" }
    return Read-Host $Prompt
}

# Mask a secret for display: show first 4 + last 4, dots in between
function Mask([string]$v){
    if([string]::IsNullOrEmpty($v)){ return "" }
    if($v.Length -le 10){ return ("*" * $v.Length) }
    return $v.Substring(0,4) + ("*" * 6) + $v.Substring($v.Length-4)
}

function Read-EnvFile($path){
    $d = [ordered]@{}
    if(Test-Path $path){
        foreach($line in Get-Content $path){
            if($line -match '^\s*#'){ continue }
            if($line -notmatch '='){ continue }
            $parts = $line -split '=',2
            $d[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    return $d
}

# Prompt for a key; masks current value; Enter keeps/skips
function Read-Key {
    param([string]$Name,[string]$Desc,[string]$Current,[switch]$Secret,[switch]$Required)
    $shown = if($Current){ if($Secret){ "[set: " + (Mask $Current) + "]" } else { "[set: $Current]" } } else { "[not set]" }
    Write-Host ""
    Write-Host "    $Name $shown" -ForegroundColor White
    Write-Host "      $Desc" -ForegroundColor DarkGray
    if($Required -and -not $Current){ Write-Host "      (required for AI triggers)" -ForegroundColor Yellow }
    if($script:AUTO){
        Write-Host "      $(if($Current){'kept'}else{'skipped'}) (auto)" -ForegroundColor DarkGray
        return $Current
    }
    $hint = if($Current){ "      Enter new value, or press Enter to KEEP: " } else { "      Enter value, or press Enter to SKIP: " }
    $val = Read-Host $hint
    if([string]::IsNullOrWhiteSpace($val)){ return $Current }
    return $val.Trim()
}

# Robustly locate the espanso CLI, return its path or $null
function Find-Espanso {
    $c = Get-Command espanso -ErrorAction SilentlyContinue
    if($c){ return $c.Source }
    foreach($p in @(
        "$env:LOCALAPPDATA\Programs\Espanso\espanso.exe",
        "$env:ProgramFiles\Espanso\espanso.exe",
        "${env:ProgramFiles(x86)}\Espanso\espanso.exe"
    )){ if(Test-Path $p){ return $p } }
    $hit = Get-ChildItem -Path "$env:LOCALAPPDATA","$env:ProgramFiles" -Filter "espanso.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if($hit){ return $hit.FullName }
    return $null
}

# -------------------------------------------------------------
Title "Espanso Setup"
Write-Host "Sets up Espanso + your trigger scripts. Skip any API key and re-run"
Write-Host "later to add it. Existing keys are kept; secrets are masked on screen."
Write-Host "AI providers: GPT (primary) + Gemini/Groq (fallback). Any one alone is enough." -ForegroundColor DarkGray
if($AUTO){ Write-Host "ONE-SHOT MODE: accepting all defaults, no prompts. Missing keys are skipped - re-run anytime to add them." -ForegroundColor Yellow }

# 1. Prerequisites -------------------------------------------
Title "1. Prerequisites"
if(-not (Get-Command git -ErrorAction SilentlyContinue)){
    Info "Installing Git..."
    winget install --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
} else { Good "Git present" }

$ESPANSO = Find-Espanso
if(-not $ESPANSO){
    Info "Espanso not found. Installing the official build..."
    # winget's package can report success without leaving a usable exe, so use
    # the official GitHub installer directly (puts espanso on PATH reliably).
    $instUrl = "https://github.com/espanso/espanso/releases/download/v$EspansoVer/Espanso-Win-Installer-x86_64.exe"
    $instOut = Join-Path $env:TEMP "Espanso-Installer.exe"
    try {
        Invoke-WebRequest -Uri $instUrl -OutFile $instOut -UseBasicParsing
        Info "Launching the Espanso installer - click through Next > Install > Finish..."
        Start-Process $instOut -Wait
    } catch {
        Warn "Could not download/run the official installer: $($_.Exception.Message)"
        Warn "Falling back to winget..."
        winget install --id Espanso.Espanso --source winget --accept-source-agreements --accept-package-agreements
    }
    $ESPANSO = Find-Espanso
}
if($ESPANSO){ Good "Espanso: $ESPANSO" }
else { Warn "Espanso still not detected. Open a NEW terminal and re-run this script after the installer finishes." }

# Stop espanso before touching its config
if($ESPANSO){ Info "Stopping Espanso..."; & $ESPANSO stop 2>$null | Out-Null }

# 2. Clone / update repos ------------------------------------
Title "2. Scripts and config"
function Sync-Repo($url,$dest,$label){
    if(Test-Path (Join-Path $dest ".git")){
        Info "Updating $label..."
        git -C "$dest" pull --ff-only 2>&1 | Out-Null
    } elseif(Test-Path $dest){
        $bak = "$dest.bak.$(Get-Date -Format yyyyMMddHHmmss)"
        Warn "$label exists but isn't a git repo - backing up to $bak"
        Move-Item $dest $bak
        Info "Cloning $label..."
        git clone "$url" "$dest" 2>&1 | Out-Null
    } else {
        Info "Cloning $label..."
        git clone "$url" "$dest" 2>&1 | Out-Null
    }
}
Sync-Repo $UtilRepo $UtilDir "espanso-utility (scripts)"
Sync-Repo $ConfRepo $ConfigDir "espanso (config + triggers)"
Good "Repos ready"

# 3. .env walkthrough ----------------------------------------
Title "3. API keys (skip any - re-run later to add them)"
if(-not (Test-Path $EnvFile)){
    $example = Join-Path $UtilDir ".env.example"
    if(Test-Path $example){ Copy-Item $example $EnvFile } else { New-Item -ItemType File -Path $EnvFile -Force | Out-Null }
}
$d = Read-EnvFile $EnvFile

# --- Gemini ---
Write-Host "`n  -- Gemini (primary AI provider) --" -ForegroundColor Cyan
$d['GEMINI_API_KEY'] = Read-Key -Name "GEMINI_API_KEY" -Secret -Required `
    -Desc "Get it at https://aistudio.google.com/apikey" -Current $d['GEMINI_API_KEY']

$curGeminiModel = $d['GEMINI_MODEL']
$dispGeminiModel = if($curGeminiModel){ $curGeminiModel } else { "gemini-2.0-flash (default)" }
Write-Host "`n    GEMINI_MODEL [current: $dispGeminiModel]" -ForegroundColor White
Write-Host "      Browse models at https://ai.google.dev/gemini-api/docs/models" -ForegroundColor DarkGray
$gm = Read-Opt "      Enter a model slug, or press Enter to keep default (gemini-2.0-flash): "
if(-not [string]::IsNullOrWhiteSpace($gm)){ $d['GEMINI_MODEL'] = $gm.Trim() }
elseif(-not $curGeminiModel){ $d['GEMINI_MODEL'] = "gemini-2.0-flash" }

# --- Groq ---
Write-Host "`n  -- Groq (fallback AI provider) --" -ForegroundColor Cyan
$d['GROQ_API_KEY'] = Read-Key -Name "GROQ_API_KEY" -Secret -Required `
    -Desc "Get it at https://console.groq.com/keys" -Current $d['GROQ_API_KEY']

$curGroqModel = $d['GROQ_MODEL']
$dispGroqModel = if($curGroqModel){ $curGroqModel } else { "llama-3.3-70b-versatile (default)" }
Write-Host "`n    GROQ_MODEL [current: $dispGroqModel]" -ForegroundColor White
Write-Host "      Browse models at https://console.groq.com/docs/models" -ForegroundColor DarkGray
$grm = Read-Opt "      Enter a model slug, or press Enter to keep default (llama-3.3-70b-versatile): "
if(-not [string]::IsNullOrWhiteSpace($grm)){ $d['GROQ_MODEL'] = $grm.Trim() }
elseif(-not $curGroqModel){ $d['GROQ_MODEL'] = "llama-3.3-70b-versatile" }

# --- OpenAI (default provider + web-grounded :ask / :factcheck) ---
Write-Host "`n  -- OpenAI (default AI provider; also powers :ask and :factcheck) --" -ForegroundColor Cyan
$d['OPENAI_API_KEY'] = Read-Key -Name "OPENAI_API_KEY" -Secret `
    -Desc "Default provider for AI triggers, plus :ask / :factcheck. Get it at https://platform.openai.com/api-keys" `
    -Current $d['OPENAI_API_KEY']

$curGptModel = $d['OPENAI_MODEL']
$dispGptModel = if($curGptModel){ $curGptModel } else { "gpt-4.1-mini (default)" }
Write-Host "`n    OPENAI_MODEL [current: $dispGptModel]" -ForegroundColor White
Write-Host "      Chat model used for the AI intermediator. See https://platform.openai.com/docs/models" -ForegroundColor DarkGray
$gptm = Read-Opt "      Enter a model slug, or press Enter to keep default (gpt-4.1-mini): "
if(-not [string]::IsNullOrWhiteSpace($gptm)){ $d['OPENAI_MODEL'] = $gptm.Trim() }
elseif(-not $curGptModel){ $d['OPENAI_MODEL'] = "gpt-4.1-mini" }

$curSearchModel = $d['OPENAI_SEARCH_MODEL']
$dispSearchModel = if($curSearchModel){ $curSearchModel } else { "gpt-4o-mini-search-preview (default)" }
Write-Host "`n    OPENAI_SEARCH_MODEL [current: $dispSearchModel]" -ForegroundColor White
Write-Host "      Search-enabled model for :ask (must be an OpenAI *-search-preview model)." -ForegroundColor DarkGray
$om = Read-Opt "      Enter a model slug, or press Enter to keep default (gpt-4o-mini-search-preview): "
if(-not [string]::IsNullOrWhiteSpace($om)){ $d['OPENAI_SEARCH_MODEL'] = $om.Trim() }
elseif(-not $curSearchModel){ $d['OPENAI_SEARCH_MODEL'] = "gpt-4o-mini-search-preview" }

$curFactModel = $d['OPENAI_FACTCHECK_MODEL']
$dispFactModel = if($curFactModel){ $curFactModel } else { "gpt-5.1 (default)" }
Write-Host "`n    OPENAI_FACTCHECK_MODEL [current: $dispFactModel]" -ForegroundColor White
Write-Host "      Model used for :factcheck (web-grounded via the Responses API)." -ForegroundColor DarkGray
$fm = Read-Opt "      Enter a model slug, or press Enter to keep default (gpt-5.1): "
if(-not [string]::IsNullOrWhiteSpace($fm)){ $d['OPENAI_FACTCHECK_MODEL'] = $fm.Trim() }
elseif(-not $curFactModel){ $d['OPENAI_FACTCHECK_MODEL'] = "gpt-5.1" }

# --- Primary provider selection ---
Write-Host "`n  -- Primary AI provider --" -ForegroundColor Cyan
$curPrimary = $d['AI_PRIMARY']
$dispPrimary = if($curPrimary){ $curPrimary } else { "gpt (default)" }
Write-Host "    AI_PRIMARY [current: $dispPrimary]" -ForegroundColor White
Write-Host "      Which provider to call first; the others are automatic fallbacks." -ForegroundColor DarkGray
$pv = Read-Opt "      Enter 'gpt', 'gemini' or 'groq', or press Enter to keep default (gpt): "
if($pv.Trim().ToLower() -eq 'groq'){ $d['AI_PRIMARY'] = "groq" }
elseif($pv.Trim().ToLower() -eq 'gemini'){ $d['AI_PRIMARY'] = "gemini" }
elseif($pv.Trim().ToLower() -eq 'gpt'){ $d['AI_PRIMARY'] = "gpt" }
elseif(-not $curPrimary){ $d['AI_PRIMARY'] = "gpt" }

# Optional: OCR
if(Confirm-Step "`n  Configure OCR (for :ocr)?" $false){
    $d['OCR_SPACE_API_KEY'] = Read-Key -Name "OCR_SPACE_API_KEY" -Secret -Desc "Free key at ocr.space/ocrapi/freekey" -Current $d['OCR_SPACE_API_KEY']
}
# Optional: Cloudinary
if(Confirm-Step "`n  Configure Cloudinary (screenshots / file uploads)?" $false){
    $d['CLOUDINARY_CLOUD_NAME']    = Read-Key -Name "CLOUDINARY_CLOUD_NAME"    -Desc "cloudinary.com/console" -Current $d['CLOUDINARY_CLOUD_NAME']
    $d['CLOUDINARY_UPLOAD_PRESET'] = Read-Key -Name "CLOUDINARY_UPLOAD_PRESET" -Desc "Settings > Upload Presets" -Current $d['CLOUDINARY_UPLOAD_PRESET']
    $d['CLOUDINARY_API_KEY']       = Read-Key -Name "CLOUDINARY_API_KEY" -Secret -Desc "Settings > API Keys" -Current $d['CLOUDINARY_API_KEY']
    $d['CLOUDINARY_API_SECRET']    = Read-Key -Name "CLOUDINARY_API_SECRET" -Secret -Desc "Settings > API Keys" -Current $d['CLOUDINARY_API_SECRET']
}
# Optional: Cloudflare R2
if(Confirm-Step "`n  Configure Cloudflare R2 (file storage)?" $false){
    $d['R2_ACCESS_KEY_ID']     = Read-Key -Name "R2_ACCESS_KEY_ID" -Secret -Desc "Cloudflare > R2 > Manage API Tokens" -Current $d['R2_ACCESS_KEY_ID']
    $d['R2_SECRET_ACCESS_KEY'] = Read-Key -Name "R2_SECRET_ACCESS_KEY" -Secret -Desc "Cloudflare > R2 > Manage API Tokens" -Current $d['R2_SECRET_ACCESS_KEY']
    $d['R2_ACCOUNT_ID']        = Read-Key -Name "R2_ACCOUNT_ID" -Desc "Cloudflare > R2 > Manage API Tokens" -Current $d['R2_ACCOUNT_ID']
    $d['R2_BUCKET_NAME']       = Read-Key -Name "R2_BUCKET_NAME" -Desc "Your R2 bucket name" -Current $d['R2_BUCKET_NAME']
    $d['R2_PUBLIC_BASE_URL']   = Read-Key -Name "R2_PUBLIC_BASE_URL" -Desc "R2 > Bucket > Public Development URL" -Current $d['R2_PUBLIC_BASE_URL']
}

# Write .env back (keep only non-empty values)
$lines = @()
foreach($k in $d.Keys){ if($null -ne $d[$k] -and $d[$k] -ne ""){ $lines += "$k=$($d[$k])" } }
Set-Content -Path $EnvFile -Value $lines -Encoding UTF8
Good ".env saved ($($lines.Count) keys)"

# 4. Load keys into Windows (direct - no load-env.ps1, no hang) ----
Title "4. Loading keys into Windows"
foreach($k in $d.Keys){
    if($null -ne $d[$k] -and $d[$k] -ne ""){
        [System.Environment]::SetEnvironmentVariable($k, $d[$k], "User")     # persisted
        [System.Environment]::SetEnvironmentVariable($k, $d[$k], "Process")  # this session
    }
}
Good "Keys loaded (user-scope + this session)"

# 5. Unblock scripts -----------------------------------------
Title "5. Unblocking scripts"
Get-ChildItem "$UtilDir\*.ps1","$UtilDir\*.bat" -ErrorAction SilentlyContinue | Unblock-File
Good "Scripts unblocked"

# 6. Silent auto-start (Task Scheduler, no UAC popup) --------
Title "6. Auto-start on login (silent)"
if($AUTO){
    # One-shot mode: the elevated scheduled task needs a UAC prompt, which would
    # block an unattended run. Register the espanso service instead (no elevation).
    Info "One-shot mode: registering espanso service for auto-start (no UAC)."
    if($ESPANSO){ & $ESPANSO service register 2>$null | Out-Null }
    Good "Auto-start via espanso service"
} elseif(Confirm-Step "  Set Espanso to start silently every login?" $true){
    $taskScript = @'
$espansoPath = "$env:LOCALAPPDATA\Programs\Espanso\espansod.exe"
if(-not (Test-Path $espansoPath)){ $espansoPath = "$env:ProgramFiles\Espanso\espansod.exe" }
$action    = New-ScheduledTaskAction -Execute $espansoPath -Argument "daemon"
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
Register-ScheduledTask -TaskName "Espanso" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
'@
    $tp = Join-Path $env:TEMP "espanso-task.ps1"
    Set-Content -Path $tp -Value $taskScript -Encoding UTF8
    Info "A UAC prompt will appear once to create the elevated startup task..."
    try {
        Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$tp -Wait
        if($ESPANSO){ & $ESPANSO service unregister 2>$null | Out-Null }
        Good "Auto-start task created"
    } catch { Warn "Auto-start skipped (UAC declined). Re-run anytime." }
} else {
    Info "Skipped."
    if($ESPANSO){ & $ESPANSO service register 2>$null | Out-Null }
}

# 7. Start Espanso -------------------------------------------
Title "7. Starting Espanso"
if($ESPANSO){
    & $ESPANSO restart 2>$null | Out-Null
    Start-Sleep -Seconds 1
    & $ESPANSO start 2>$null | Out-Null
    Good "Espanso started"
} else { Warn "Espanso not detected - open a new terminal and run: espanso restart" }

# 8. Summary -------------------------------------------------
Title "Done!"
$set = ($d.Keys | Where-Object { $d[$_] }) -join ", "
Write-Host "  Configured: $set"
Write-Host ""
$primary   = if($d['AI_PRIMARY']){ $d['AI_PRIMARY'] } else { "gpt" }
$fallbacks = (@('gpt','gemini','groq') | Where-Object { $_ -ne $primary }) -join ", "
Write-Host "  AI routing: $primary (primary)  ->  $fallbacks (fallback)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Test it: open a NEW window and type  :gpt  or  :fixgrammar" -ForegroundColor Green
Write-Host "  Live web search (needs OpenAI key): copy text, then  :ask  or  :factcheck" -ForegroundColor Green
Write-Host "  Switch provider on the fly:  :switch-gpt, :switch-gemini  or  :switch-groq" -ForegroundColor Green
Write-Host "  Add a skipped key later? Just run this script again - it keeps"
Write-Host "  everything you already set and only asks about the rest."
Write-Host ""
Write-Host "  If emojis/Nepali look garbled, apply the UTF-8 fix from the README"
Write-Host "  (as Admin) and reboot."
