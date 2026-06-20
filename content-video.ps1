# content-video.ps1
param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms

    $topic = [System.Windows.Forms.Clipboard]::GetText()

    if (-not $topic -or $topic.Length -eq 0) {
        Write-Output "ERROR: No topic in clipboard. Copy your video topic first."
        exit 1
    }

    $messages = @(
        @{
            role    = "system"
            content = @"
Generate 3 video content ideas based on the topic. For each idea, provide:

TITLE: [catchy title]

HOOK: [first 5 seconds to stop scrolling]

SCRIPT OUTLINE:
- [key point 1]
- [key point 2]
- [key point 3]
- [key point 4]

VISUALS:
- [visual 1]
- [visual 2]
- [visual 3]

CALL TO ACTION: [specific CTA]

SCORES:
Authority: [1-10]
Virality: [1-10]
Branding: [1-10]

---

Use this EXACT format with proper spacing between sections. Add a line of dashes (---) between each idea for clear separation.
"@
        }
        @{ role = "user"; content = "Topic: $topic" }
    )
    $result = & "$PSScriptRoot\ai-call.ps1" -Messages $messages -Temperature 0.8
    Write-Output $result

} catch {
    Write-Output "Error: $($_.Exception.Message)"
}
