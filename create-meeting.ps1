# create-meeting.ps1
# Creates Google Meet links using Google Calendar API
# Usage: 
#   .\create-meeting.ps1
#   .\create-meeting.ps1 -Email "user@example.com" -DateTime "02-13-2026 3:40 PM" -Duration 60

param(
    [string]$Email = "",
    [string]$DateTime = "",
    [int]$Duration = 60,  # Duration in minutes
    [string]$Title = "Quick Meeting"
)

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # File paths
    $credentialsPath = "$PSScriptRoot\google-credentials.json"
    $tokenPath = "$PSScriptRoot\google-token.json"
    
    # Check if credentials exist
    if (-not (Test-Path $credentialsPath)) {
        Write-Output "ERROR: google-credentials.json not found. Please follow SETUP-GOOGLE-API.md"
        exit 1
    }
    
    # Read credentials
    $credentials = Get-Content $credentialsPath | ConvertFrom-Json
    $clientId = $credentials.installed.client_id
    $clientSecret = $credentials.installed.client_secret
    $redirectUri = "http://localhost"
    
    # Function to get access token
    function Get-AccessToken {
        if (Test-Path $tokenPath) {
            $token = Get-Content $tokenPath | ConvertFrom-Json
            
            # Check if token is expired
            $expiryTime = [DateTime]::Parse($token.expiry_time)
            if ($expiryTime -gt (Get-Date)) {
                return $token.access_token
            }
            
            # Refresh token if expired
            $refreshUrl = "https://oauth2.googleapis.com/token"
            $refreshBody = @{
                client_id = $clientId
                client_secret = $clientSecret
                refresh_token = $token.refresh_token
                grant_type = "refresh_token"
            }
            
            $response = Invoke-RestMethod -Uri $refreshUrl -Method Post -Body $refreshBody -ContentType "application/x-www-form-urlencoded"
            
            # Update token file
            $token.access_token = $response.access_token
            $token.expiry_time = (Get-Date).AddSeconds($response.expires_in).ToString("o")
            $token | ConvertTo-Json | Set-Content $tokenPath
            
            return $response.access_token
        }
        
        # First-time authentication
        $authUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=https://www.googleapis.com/auth/calendar"
        
        Write-Host "Opening browser for authentication..."
        Start-Process $authUrl
        
        $authCode = Read-Host "Paste the authorization code from the URL"
        
        # Exchange code for token
        $tokenUrl = "https://oauth2.googleapis.com/token"
        $tokenBody = @{
            code = $authCode
            client_id = $clientId
            client_secret = $clientSecret
            redirect_uri = $redirectUri
            grant_type = "authorization_code"
        }
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
        
        # Save token
        $tokenData = @{
            access_token = $response.access_token
            refresh_token = $response.refresh_token
            expiry_time = (Get-Date).AddSeconds($response.expires_in).ToString("o")
        }
        $tokenData | ConvertTo-Json | Set-Content $tokenPath
        
        return $response.access_token
    }
    
    # Get access token
    $accessToken = Get-AccessToken
    
    # Prepare event data
    if ($DateTime -eq "") {
        # Instant meeting (starts now, 1 hour duration)
        $startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).AddMinutes($Duration).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } else {
        # Scheduled meeting
        $startDateTime = [DateTime]::Parse($DateTime)
        $startTime = $startDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = $startDateTime.AddMinutes($Duration).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    
    # Build attendees array
    $attendees = @()
    if ($Email -ne "") {
        # Split by comma if multiple emails
        $emailList = $Email -split ','
        foreach ($emailAddress in $emailList) {
            $emailAddress = $emailAddress.Trim()
            if ($emailAddress -ne "") {
                $attendees += @{ email = $emailAddress }
            }
        }
    }
    
    # Create event
    $event = @{
        summary = $Title
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
    
    # Create Calendar event
    $calendarUrl = "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1&sendUpdates=all"
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri $calendarUrl -Method Post -Headers $headers -Body ($event | ConvertTo-Json -Depth 10)
    
    # Extract Google Meet link
    $meetLink = $response.conferenceData.entryPoints | Where-Object { $_.entryPointType -eq "video" } | Select-Object -ExpandProperty uri
    
    # Copy to clipboard
    $meetLink | Set-Clipboard
    
    # Output the link
    Write-Output $meetLink
    
} catch {
    Write-Output "Error: $_"
}
