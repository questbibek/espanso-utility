$apiKey = $env:OPENAI_API_KEY
# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

try {
    # Get clipboard content
    $originalText = [System.Windows.Forms.Clipboard]::GetText()
    
    if ([string]::IsNullOrWhiteSpace($originalText)) {
        Write-Output "No text in clipboard"
        exit
    }

    # Prepare API request
    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a helpful mathematical calculator assistant. Evaluate the mathematical expression provided and return only the numerical result without any explanation or additional text."
            }
            @{
                role = "user"
                content = "Calculate: $originalText"
            }
        )
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    # Make API call
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body -ErrorAction Stop
    
    # Extract and output answer
    $answer = $response.choices[0].message.content.Trim()
    
    if ($answer) {
        Write-Output $answer
    } else {
        Write-Output "No answer received"
    }
    
} catch {
    # Output error for debugging
    Write-Output "Error: $($_.Exception.Message)"
}
