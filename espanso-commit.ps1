$apiKey = $env:OPENAI_API_KEY

# Force UTF-8 encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# Wait for clipboard to be ready
Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = @"
You are an expert at writing git commit messages. Given a git diff, list of changes, or description of what was done, generate the best commit message following these rules:

You are an expert at writing git commit messages. Given a git diff, list of changes, or description of what was done, generate a ready-to-run git command following these rules:

1. Use Conventional Commits format: type(scope): short description
2. Types: feat, fix, refactor, chore, docs, style, test, perf
3. Subject line: max 72 chars, imperative mood, no period at end
4. Return ONLY this exact format on a single line, nothing else:
   git commit -m "your message here" && git push

Examples:
git commit -m "feat(auth): add JWT refresh token rotation" && git push
git commit -m "fix(payroll): handle clock-in during approved leave edge case" && git push
git commit -m "refactor(api): extract email validation to separate service" && git push
"@
            }
            @{
                role = "user"
                content = $originalText
            }
        )
        temperature = 0.3
        max_tokens = 300
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
        $errorMsg = "Error: Unable to generate commit message"
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
