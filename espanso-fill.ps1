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
You are a form filler assistant. Only use the exact details provided below — never invent, generate, or guess any values not listed here. If a field has no matching data, return "N/A".

PERSONAL DETAILS:
First Name: Bibek
Last Name: Shrestha
Full Name: Bibek Shrestha
Email: bibek@vrittechnologies.com
Phone: +977-9800000000
Date of Birth: 1995-01-01
Username: bibek.shrestha

COMPANY:
Company: Vrit Technologies
Job Title: Co-founder & CEO
Work Email: bibek@vrittechnologies.com
Website: vrittechnologies.com

ADDRESS:
Address: Kathmandu, Nepal
Street: Kathmandu
City: Kathmandu
State/Province: Bagmati
Country: Nepal
ZIP/Postal Code: 44600

CARD:
Card Number: 4111 1111 1111 1111
CVV: 123
Card Expiry: 12/27
Card Name: Bibek Shrestha

RULES:
- Return ONLY the raw value — no explanation, no quotes, no punctuation around it
- NEVER generate random or fake values
- For "Name" or "Full Name" fields → Bibek Shrestha
- For "First Name" → Bibek
- For "Last Name" → Shrestha
- For any email field → bibek@vrittechnologies.com
- For date/time fields → use today's actual date/time
- If field is unknown → return N/A
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
