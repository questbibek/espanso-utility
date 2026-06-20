# schedule-meeting-smart.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $credentialsPath = "$env:USERPROFILE\espanso-utility\google-credentials.json"
    $tokenPath = "$env:USERPROFILE\espanso-utility\google-token.json"

    $userInput = [System.Windows.Forms.Clipboard]::GetText()

    if (-not $userInput -or $userInput.Length -eq 0) {
        Write-Output "ERROR: No text in clipboard"
        exit 1
    }

    $currentDate     = Get-Date -Format "yyyy-MM-dd HH:mm"
    $tomorrowDate    = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
    $currentTimezone = (Get-TimeZone).Id

    $messages = @(
        @{
            role    = "system"
            content = "Extract meeting details and return ONLY valid JSON:`n{`n  `"title`": `"Meeting title`",`n  `"emails`": [`"email1@example.com`"],`n  `"datetime`": `"YYYY-MM-DD HH:MM`",`n  `"duration`": 60`n}`n`nRULES:`n- datetime REQUIRED in format YYYY-MM-DD HH:MM (24-hour)`n- Current datetime: $currentDate`n- Current timezone: $currentTimezone`n- Parse relative times from NOW, not tomorrow`n- 'in 15 minutes' = add 15 minutes to current time`n- 'in 1 hour' = add 1 hour to current time`n- 'tomorrow' = $tomorrowDate`n- emails: array of email addresses (empty [] if none)`n- duration: minutes (default 60)`n- title: descriptive subject`n- Return ONLY JSON, no markdown, no explanation"
        }
        @{ role = "user"; content = $userInput }
    )
    $jsonResponse = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3

    $jsonResponse = $jsonResponse -replace '```json', '' -replace '```', ''
    $jsonResponse = $jsonResponse.Trim()

    $meetingDetails = $jsonResponse | ConvertFrom-Json

    function Get-AccessToken {
        if (Test-Path $tokenPath) {
            $token = Get-Content $tokenPath | ConvertFrom-Json
            $expiryTime = [DateTime]::Parse($token.expiry_time)
            if ($expiryTime -gt (Get-Date)) { return $token.access_token }

            $credentials  = Get-Content $credentialsPath | ConvertFrom-Json
            $refreshBody  = @{
                client_id     = $credentials.installed.client_id
                client_secret = $credentials.installed.client_secret
                refresh_token = $token.refresh_token
                grant_type    = "refresh_token"
            }
            $response = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" -Method Post -Body $refreshBody -ContentType "application/x-www-form-urlencoded"
            $token.access_token = $response.access_token
            $token.expiry_time  = (Get-Date).AddSeconds($response.expires_in).ToString("o")
            $token | ConvertTo-Json | Set-Content $tokenPath
            return $response.access_token
        }
        Write-Output "ERROR: Not authenticated. Run create-meeting.ps1 first."
        exit 1
    }

    $accessToken = Get-AccessToken

    if ($null -eq $meetingDetails.datetime -or $meetingDetails.datetime -eq "") {
        Write-Output "ERROR: No date/time specified. Use :meeting for instant meetings."
        exit 1
    }
    if ($meetingDetails.datetime -eq "now") {
        Write-Output "ERROR: For instant meetings, use :meeting trigger instead."
        exit 1
    }

    $startDateTime = [DateTime]::Parse($meetingDetails.datetime)
    $startTime     = $startDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $endTime       = $startDateTime.AddMinutes($meetingDetails.duration).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $attendees = @()
    foreach ($email in $meetingDetails.emails) {
        if ($email -and $email.Trim() -ne "") { $attendees += @{ email = $email.Trim() } }
    }

    $event = @{
        summary       = $meetingDetails.title
        start         = @{ dateTime = $startTime; timeZone = "UTC" }
        end           = @{ dateTime = $endTime;   timeZone = "UTC" }
        conferenceData = @{
            createRequest = @{
                requestId            = [Guid]::NewGuid().ToString()
                conferenceSolutionKey = @{ type = "hangoutsMeet" }
            }
        }
        attendees = $attendees
    }

    $calendarHeaders = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }
    $response = Invoke-RestMethod -Uri "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1&sendUpdates=all" -Method Post -Headers $calendarHeaders -Body ($event | ConvertTo-Json -Depth 10)

    $meetLink = $response.conferenceData.entryPoints | Where-Object { $_.entryPointType -eq "video" } | Select-Object -ExpandProperty uri
    $meetLink | Set-Clipboard
    Write-Output $meetLink

} catch {
    Write-Output "Error: $_"
}
