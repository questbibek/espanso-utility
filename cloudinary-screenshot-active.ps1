# cloudinary-screenshot-active.ps1
# Place in $PSScriptRoot\
# Captures the monitor where the mouse cursor is currently located

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Cloudinary credentials
    $cloudName = $env:CLOUDINARY_CLOUD_NAME
    $uploadPreset = $env:CLOUDINARY_UPLOAD_PRESET
    
    # Create temporary file path
    $tempPath = [System.IO.Path]::GetTempPath()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $screenshotPath = Join-Path $tempPath "screenshot_$timestamp.png"
    
    # Load required assemblies for screenshot
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Get cursor position
    $cursorPos = [System.Windows.Forms.Cursor]::Position
    
    # Find which screen contains the cursor
    $activeScreen = [System.Windows.Forms.Screen]::FromPoint($cursorPos)
    
    # Get bounds of the active screen
    $bounds = $activeScreen.Bounds
    
    # Create bitmap for active screen only
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    
    # Save screenshot
    $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Clean up
    $graphics.Dispose()
    $bitmap.Dispose()
    
    # Upload to Cloudinary with unsigned preset
    $uploadUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload"
    
    $response = curl.exe -s `
        -F "file=@$screenshotPath" `
        -F "upload_preset=$uploadPreset" `
        $uploadUrl
    
    # Parse JSON response
    $result = $response | ConvertFrom-Json
    $imageUrl = $result.secure_url
    
    # Copy URL to clipboard
    $imageUrl | Set-Clipboard
    
    # Clean up temp file
    Remove-Item $screenshotPath -Force -ErrorAction SilentlyContinue
    
    # Output the URL
    Write-Output $imageUrl
    
} catch {
    Write-Output "Error: $_"
    # Clean up temp file if it exists
    if (Test-Path $screenshotPath) {
        Remove-Item $screenshotPath -Force -ErrorAction SilentlyContinue
    }
}
