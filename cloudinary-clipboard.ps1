# cloudinary-clipboard.ps1
# Place in $PSScriptRoot\

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Cloudinary credentials
    $cloudName = $env:CLOUDINARY_CLOUD_NAME
    $uploadPreset = $env:CLOUDINARY_UPLOAD_PRESET
    
    Add-Type -AssemblyName System.Windows.Forms
    
    # Check if clipboard contains an image
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $image = [System.Windows.Forms.Clipboard]::GetImage()
        
        # Save to temp file
        $tempPath = [System.IO.Path]::GetTempPath()
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $imagePath = Join-Path $tempPath "clipboard_$timestamp.png"
        
        $image.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Upload to Cloudinary with unsigned preset
        $uploadUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload"
        
        $response = curl.exe -s `
            -F "file=@$imagePath" `
            -F "upload_preset=$uploadPreset" `
            $uploadUrl
        
        # Parse JSON response
        $result = $response | ConvertFrom-Json
        $imageUrl = $result.secure_url
        
        # Copy URL to clipboard
        $imageUrl | Set-Clipboard
        
        # Clean up temp file
        Remove-Item $imagePath -Force -ErrorAction SilentlyContinue
        
        # Output the URL
        Write-Output $imageUrl
        
    } else {
        Write-Output "No image in clipboard"
    }
    
} catch {
    Write-Output "Error: $_"
    if (Test-Path $imagePath) {
        Remove-Item $imagePath -Force -ErrorAction SilentlyContinue
    }
}
