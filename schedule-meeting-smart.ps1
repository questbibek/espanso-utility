# schedule-meeting-smart.ps1
# Takes natural language from clipboard, uses GPT to extract meeting details, creates Google Meet

param()

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    
    # API Keys
    $openaiApiKey = $env:OPENAI_API_KEY
    
    # File paths for Google Calendar
    $credentialsPath = "$env:USERPROFILE\espanso-utility\google-credentials.json"
    $tokenPath = "$env:USERPROFILE\espanso-utility\google-token.json"
    
    # Get text from clipboard
    $userInput = [System.Windows.Forms.Clipboard]::GetText()
    
    if (-not $userInput -or $userInput.Length -eq 0) {
        Write-Output "ERROR: No text in clipboard"
        exit 1
    }
    
    # Escape function for JSON
    function Escape-JsonString {
        param([string]$text)
        $text = $text -replace '\\', '\\'
        $text = $text -replace '"', '\"'
        $text = $text -replace "`n", '\n'
        $text = $text -replace "`r", ''
        $text = $text -replace "`t", '\t'
        return $text
    }
    
    # Current date for relative parsing
    $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm"
    $tomorrowDate = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
    $currentTimezone = (Get-TimeZone).Id
    
    # Build system prompt
    $systemPrompt = "Extract meeting details and return ONLY valid JSON:
{
  ""title"": ""Meeting title"",
  ""emails"": [""email1@example.com""],
  ""datetime"": ""YYYY-MM-DD HH:MM"",
  ""duration"": 60
}

RULES:
- datetime REQUIRED in format YYYY-MM-DD HH:MM (24-hour)
- Current datetime: $currentDate
- Current timezone: $currentTimezone
- Parse relative times from NOW, not tomorrow
- 'in 15 minutes' = add 15 minutes to current time
- 'in 1 hour' = add 1 hour to current time
- 'tomorrow' = $tomorrowDate
- emails: array of email addresses (empty [] if none)
- duration: minutes (default 60)
- title: descriptive subject
- Return ONLY JSON, no markdown, no explanation"
    
    # Escape strings for JSON
    $escapedSystem = Escape-JsonString $systemPrompt
    $escapedUser = Escape-JsonString $userInput
    
    # Build JSON manually
    $bodyJson = @"
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "$escapedSystem"
    },
    {
      "role": "user",
      "content": "$escapedUser"
    }
  ],
  "temperature": 0.3
}
"@
    
    $headers = @{
        "Authorization" = "Bearer $openaiApiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }
    
    $gptResponse = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson))
    $jsonResponse = $gptResponse.choices[0].message.content.Trim()
    
    # Remove markdown backticks if present
    $jsonResponse = $jsonResponse -replace '```json', '' -replace '```', ''
    $jsonResponse = $jsonResponse.Trim()
    
    # Parse JSON response
    $meetingDetails = $jsonResponse | ConvertFrom-Json
    
    # Get Google Calendar access token
    function Get-AccessToken {
        if (Test-Path $tokenPath) {
            $token = Get-Content $tokenPath | ConvertFrom-Json
            
            $expiryTime = [DateTime]::Parse($token.expiry_time)
            if ($expiryTime -gt (Get-Date)) {
                return $token.access_token
            }
            
            # Refresh token
            $credentials = Get-Content $credentialsPath | ConvertFrom-Json
            $refreshUrl = "https://oauth2.googleapis.com/token"
            $refreshBody = @{
                client_id = $credentials.installed.client_id
                client_secret = $credentials.installed.client_secret
                refresh_token = $token.refresh_token
                grant_type = "refresh_token"
            }
            
            $response = Invoke-RestMethod -Uri $refreshUrl -Method Post -Body $refreshBody -ContentType "application/x-www-form-urlencoded"
            
            $token.access_token = $response.access_token
            $token.expiry_time = (Get-Date).AddSeconds($response.expires_in).ToString("o")
            $token | ConvertTo-Json | Set-Content $tokenPath
            
            return $response.access_token
        }
        
        Write-Output "ERROR: Not authenticated. Run create-meeting.ps1 first."
        exit 1
    }
    
    $accessToken = Get-AccessToken
    
    # Parse start time - reject if no datetime specified
    if ($null -eq $meetingDetails.datetime -or $meetingDetails.datetime -eq "") {
        Write-Output "ERROR: No date/time specified. Use :meeting for instant meetings."
        exit 1
    }
    
    if ($meetingDetails.datetime -eq "now") {
        Write-Output "ERROR: For instant meetings, use :meeting trigger instead."
        exit 1
    }
    
    $startDateTime = [DateTime]::Parse($meetingDetails.datetime)
    $startTime = $startDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $endTime = $startDateTime.AddMinutes($meetingDetails.duration).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    # Build attendees
    $attendees = @()
    foreach ($email in $meetingDetails.emails) {
        if ($email -and $email.Trim() -ne "") {
            $attendees += @{ email = $email.Trim() }
        }
    }
    
    # Create Google Calendar event
    $event = @{
        summary = $meetingDetails.title
        start = @{
            dateTime = $startTime
            timeZone = "UTC"
        }
        end = @{
            dateTime = $endTime
            timeZone = "UTC"
        }
        conferenceData = @{
            createRequest = @{
                requestId = [Guid]::NewGuid().ToString()
                conferenceSolutionKey = @{
                    type = "hangoutsMeet"
                }
            }
        }
        attendees = $attendees
    }
    
    $calendarUrl = "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1&sendUpdates=all"
    $calendarHeaders = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri $calendarUrl -Method Post -Headers $calendarHeaders -Body ($event | ConvertTo-Json -Depth 10)
    
    # Extract Google Meet link
    $meetLink = $response.conferenceData.entryPoints | Where-Object { $_.entryPointType -eq "video" } | Select-Object -ExpandProperty uri
    
    # Copy to clipboard
    $meetLink | Set-Clipboard
    
    # Output the link
    Write-Output $meetLink
    
} catch {
    Write-Output "Error: $_"
}