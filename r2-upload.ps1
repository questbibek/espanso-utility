# r2-upload.ps1
# Ctrl+C one or multiple files anywhere in Explorer → :r2upload → returns all links

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $accessKey  = $env:R2_ACCESS_KEY_ID
    $secretKey  = $env:R2_SECRET_ACCESS_KEY
    $accountId  = $env:R2_ACCOUNT_ID
    $bucket     = $env:R2_BUCKET_NAME
    $publicBase = $env:R2_PUBLIC_BASE_URL
    $endpoint   = "https://$accountId.r2.cloudflarestorage.com"

    Add-Type -AssemblyName System.Windows.Forms

    $filePaths = @()
    if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
        $filePaths = [System.Windows.Forms.Clipboard]::GetFileDropList()
    } elseif ([System.Windows.Forms.Clipboard]::ContainsText()) {
        $filePaths = @(([System.Windows.Forms.Clipboard]::GetText()).Trim())
    }
    if (-not $filePaths) { Write-Output "No file in clipboard"; exit 1 }

    $region  = "auto"
    $service = "s3"

    # Sanitize filename — replace spaces and special chars with hyphens
    function Sanitize-Filename([string]$name) {
        $ext      = [System.IO.Path]::GetExtension($name)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($name)
        $clean    = $baseName -replace '[^a-zA-Z0-9._-]', '-'
        $clean    = $clean -replace '-{2,}', '-'   # collapse multiple hyphens
        $clean    = $clean.Trim('-')
        return "$clean$ext"
    }

    function Sign-Data {
        param([byte[]]$key, [string]$data)
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = $key
        return [byte[]]($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data)))
    }

    function Get-Sha256Hex([string]$str) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return [System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($str))).Replace("-","").ToLower()
    }

    function Get-Sha256HexBytes([byte[]]$bytes) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-","").ToLower()
    }

    function Get-Signature([string]$dateStamp, [string]$stringToSign) {
        [byte[]]$kSecret  = [System.Text.Encoding]::UTF8.GetBytes("AWS4$secretKey")
        [byte[]]$kDate    = Sign-Data -key $kSecret   -data $dateStamp
        [byte[]]$kRegion  = Sign-Data -key $kDate     -data $region
        [byte[]]$kService = Sign-Data -key $kRegion   -data $service
        [byte[]]$kSigning = Sign-Data -key $kService  -data "aws4_request"
        [byte[]]$sigBytes = Sign-Data -key $kSigning  -data $stringToSign
        return [System.BitConverter]::ToString($sigBytes).Replace("-","").ToLower()
    }

    $links = @()

    foreach ($filePath in $filePaths) {
        $filePath = $filePath.Trim()
        if (-not (Test-Path $filePath)) { $links += "Not found: $filePath"; continue }

        $originalName = [System.IO.Path]::GetFileName($filePath)
        $fileName     = Sanitize-Filename $originalName   # clean name used in R2
        [byte[]]$fileBytes = [System.IO.File]::ReadAllBytes($filePath)

        $ext = [System.IO.Path]::GetExtension($fileName).ToLower()
        $contentType = switch ($ext) {
            ".png"  { "image/png" }   ".jpg"  { "image/jpeg" }
            ".jpeg" { "image/jpeg" }  ".gif"  { "image/gif" }
            ".webp" { "image/webp" }  ".pdf"  { "application/pdf" }
            ".zip"  { "application/zip" } ".txt" { "text/plain" }
            ".json" { "application/json" } ".csv" { "text/csv" }
            ".mp4"  { "video/mp4" }   ".html" { "text/html" }
            default { "application/octet-stream" }
        }

        $date        = [DateTime]::UtcNow
        $dateStamp   = $date.ToString("yyyyMMdd")
        $amzDate     = $date.ToString("yyyyMMddTHHmmssZ")
        $payloadHash = Get-Sha256HexBytes $fileBytes

        # Safe filename — no special chars so no encoding issues in canonical URI
        $canonicalUri     = "/$bucket/$fileName"
        $canonicalHeaders = "content-type:$contentType`nhost:$accountId.r2.cloudflarestorage.com`nx-amz-content-sha256:$payloadHash`nx-amz-date:$amzDate`n"
        $signedHeaders    = "content-type;host;x-amz-content-sha256;x-amz-date"
        $canonicalRequest = "PUT`n$canonicalUri`n`n$canonicalHeaders`n$signedHeaders`n$payloadHash"

        $credentialScope = "$dateStamp/$region/$service/aws4_request"
        $stringToSign    = "AWS4-HMAC-SHA256`n$amzDate`n$credentialScope`n$(Get-Sha256Hex $canonicalRequest)"
        $signature       = Get-Signature -dateStamp $dateStamp -stringToSign $stringToSign

        $authorization = "AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
        $headers = @{
            "Authorization"        = $authorization
            "x-amz-date"           = $amzDate
            "x-amz-content-sha256" = $payloadHash
            "Content-Type"         = $contentType
        }

        Invoke-RestMethod -Uri "$endpoint/$bucket/$fileName" -Method PUT -Headers $headers -Body $fileBytes | Out-Null

        $link = if ($publicBase) { "$publicBase/$fileName" } else { "$endpoint/$bucket/$fileName" }
        $links += $link
    }

    $output = $links -join "`n"
    $output | Set-Clipboard
    Write-Output $output

} catch {
    Write-Output "Error: $_"
}