$apiKey = $env:OPENAI_API_KEY

# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds 50

$label = [System.Windows.Forms.Clipboard]::GetText()

if ($label -and $label.Length -gt 0) {

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = @"
You are a form filler assistant for testing purposes. Generate realistic random/fake values for every field — never use any real personal data.

RULES:
- Return ONLY the raw value — no explanation, no quotes, no punctuation around it
- ALL values must be randomly generated and realistic
- First Name → random common English/Western first name
- Last Name → random common last name
- Full Name → random full name
- Email → random fake email like john.doe@gmail.com or test@example.com
- Phone → random US-format phone +1-555-xxx-xxxx
- Username → random username based on a fake name
- Company → random fake company name
- Job Title → random realistic job title
- Website → random fake domain
- Address / Street → random fake US street address
- City → random US city
- State → random US state
- Country → United States
- ZIP → random valid-format US ZIP
- Date of Birth → random DOB for someone aged 20-35
- Card Number → valid-format fake Visa: 4xxx xxxx xxxx xxxx
- CVV → random 3-digit number
- Card Expiry → a future MM/YY
- Card Name → same as the random full name
- OTP / Code → random 4-6 digit number
- Password → random strong 12-char password with mixed chars
- Date → today's actual date
- Time → current actual time
- Unknown fields → generate a sensible random value
"@
            }
            @{
                role = "user"
                content = $label
            }
        )
        temperature = 0.1
        max_tokens = 100
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json; charset=utf-8"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30
        $reply = $response.choices[0].message.content.Trim()

        if ($reply) {
            [System.Windows.Forms.Clipboard]::SetText($reply)
            Start-Sleep -Milliseconds 50
            Write-Output $reply
        }

    } catch {
        $errorMsg = "Error: Unable to fill"
        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = ($_.ErrorDetails.Message | ConvertFrom-Json)
                $errorMsg = $errorJson.error.message
            } catch {
                $errorMsg = $_.Exception.Message
            }
        }
        Write-Output $errorMsg
    }
}