# cloudinary-upload.ps1
# Ctrl+C one or multiple files anywhere in Explorer → :cloudinaryupload → returns all links

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $cloudName    = $env:CLOUDINARY_CLOUD_NAME
    $uploadPreset = $env:CLOUDINARY_UPLOAD_PRESET

    Add-Type -AssemblyName System.Windows.Forms

    $filePaths = @()
    if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
        $filePaths = [System.Windows.Forms.Clipboard]::GetFileDropList()
    } elseif ([System.Windows.Forms.Clipboard]::ContainsText()) {
        $filePaths = @(([System.Windows.Forms.Clipboard]::GetText()).Trim())
    }
    if (-not $filePaths) { Write-Output "No file in clipboard"; exit 1 }

    $links = @()

    foreach ($filePath in $filePaths) {
        $filePath = $filePath.Trim()
        if (-not (Test-Path $filePath)) { $links += "Not found: $filePath"; continue }

        $fileName = [System.IO.Path]::GetFileName($filePath)
        $ext      = [System.IO.Path]::GetExtension($fileName).ToLower()

        # Determine resource type
        $resourceType = switch ($ext) {
            { $_ -in ".mp4", ".mov", ".avi", ".mkv", ".webm" } { "video" }
            { $_ -in ".pdf", ".zip", ".txt", ".json", ".csv", ".docx", ".xlsx" } { "raw" }
            default { "image" }
        }

        $uploadUrl = "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload"

        $response = curl.exe -s `
            -F "file=@$filePath" `
            -F "upload_preset=$uploadPreset" `
            $uploadUrl

        $result = $response | ConvertFrom-Json
        $links += $result.secure_url
    }

    $output = $links -join "`n"
    $output | Set-Clipboard
    Write-Output $output

} catch {
    Write-Output "Error: $_"
}
