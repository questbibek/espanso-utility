$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds 50

$originalText = [System.Windows.Forms.Clipboard]::GetText()

if ($originalText -and $originalText.Length -gt 0) {
    $messages = @(
        @{
            role    = "system"
            content = @"
You are an expert at writing git commit messages. Given a git diff, list of changes, or description of what was done, generate the best commit message following these rules:

You are an expert at writing git commit messages. Given a git diff, list of changes, or description of what was done, generate a ready-to-run git command following these rules:

1. Use Conventional Commits format: type(scope): short description
2. Types: feat, fix, refactor, chore, docs, style, test, perf
3. Subject line: max 72 chars, imperative mood, no period at end
4. Return ONLY this exact format on a single line, nothing else:
   git commit -m "your message here" ; git push

Examples:
git commit -m "feat(auth): add JWT refresh token rotation" ; git push
git commit -m "fix(payroll): handle clock-in during approved leave edge case" ; git push
git commit -m "refactor(api): extract email validation to separate service" ; git push
"@
        }
        @{ role = "user"; content = $originalText }
    )
    $reply = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.3 -MaxTokens 300
    if ($reply) {
        [System.Windows.Forms.Clipboard]::SetText($reply)
        Start-Sleep -Milliseconds 50
        Write-Output $reply
    }
}
