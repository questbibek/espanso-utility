# ocr-screenshot.ps1
# Extracts text from screenshot using OCR.space API

param()

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # OCR.space API key
    $apiKey = "K88701150388957"
    
    # Check if image in clipboard
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $image = [System.Windows.Forms.Clipboard]::GetImage()
        
        # Save to temp file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".png"
        $image.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Convert to base64
        $imageBytes = [System.IO.File]::ReadAllBytes($tempFile)
        $base64Image = [Convert]::ToBase64String($imageBytes)
        $base64String = "data:image/png;base64,$base64Image"
        
        # Clean up temp file
        Remove-Item $tempFile -Force
        
        # Call OCR.space API
        $headers = @{
            "apikey" = $apiKey
        }
        
        $body = @{
            base64Image = $base64String
            language = "eng"
            isOverlayRequired = $false
            detectOrientation = $true
            scale = $true
            OCREngine = 2
        }
        
        $response = Invoke-RestMethod -Uri "https://api.ocr.space/parse/image" -Method Post -Headers $headers -Body $body
        
        if ($response.OCRExitCode -eq 1 -or $response.OCRExitCode -eq 2) {
            $extractedText = $response.ParsedResults[0].ParsedText.Trim()
            
            # Copy to clipboard
            $extractedText | Set-Clipboard
            
            Write-Output $extractedText
        } else {
            Write-Output "ERROR: OCR failed - $($response.ErrorMessage)"
        }
        
    } else {
        Write-Output "ERROR: No image in clipboard. Take a screenshot first (Win+Shift+S)"
    }
    
} catch {
    Write-Output "Error: $_"
}
