# cloudinary-delete.ps1
# Ctrl+C one or multiple files → :cloudinarydelete → deletes from Cloudinary by public_id

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $cloudName = $env:CLOUDINARY_CLOUD_NAME
    $apiKey    = $env:CLOUDINARY_API_KEY
    $apiSecret = $env:CLOUDINARY_API_SECRET

    Add-Type -AssemblyName System.Windows.Forms

    $filePaths = @()
    if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
        $filePaths = [System.Windows.Forms.Clipboard]::GetFileDropList()
    } elseif ([System.Windows.Forms.Clipboard]::ContainsText()) {
        $filePaths = @(([System.Windows.Forms.Clipboard]::GetText()).Trim())
    }
    if (-not $filePaths) { Write-Output "No file in clipboard"; exit 1 }

    function Get-Sha1Hex([string]$str) {
        $sha1  = [System.Security.Cryptography.SHA1]::Create()
        $bytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($str))
        return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
    }

    function Get-ResourceType([string]$ext) {
        switch ($ext) {
            { $_ -in ".mp4", ".mov", ".avi", ".mkv", ".webm" } { return "video" }
            { $_ -in ".pdf", ".zip", ".txt", ".json", ".csv", ".docx", ".xlsx" } { return "raw" }
            default { return "image" }
        }
    }

    $results = @()

    foreach ($filePath in $filePaths) {
        $fileName     = [System.IO.Path]::GetFileName($filePath.Trim())
        $ext          = [System.IO.Path]::GetExtension($fileName).ToLower()
        $resourceType = Get-ResourceType $ext

        # raw keeps full filename as public_id, image/video strips extension
        $publicId = if ($resourceType -eq "raw") {
            $fileName
        } else {
            [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        }

        $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $sigString = "public_id=$publicId&timestamp=$timestamp$apiSecret"
        $signature = Get-Sha1Hex $sigString

        $response = curl.exe -s -X POST `
            "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy" `
            -F "public_id=$publicId" `
            -F "timestamp=$timestamp" `
            -F "api_key=$apiKey" `
            -F "signature=$signature"

        $result = ($response | ConvertFrom-Json).result

        if ($result -eq "ok") {
            $results += "Deleted: $publicId"
        } else {
            $results += "Failed: $publicId ($result)"
        }
    }

    Write-Output ($results -join "`n")

} catch {
    Write-Output "Error: $_"
}