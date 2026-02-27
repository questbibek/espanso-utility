# r2-delete.ps1
# Ctrl+C one or multiple files anywhere in Explorer → :r2delete → deletes all from R2

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $accessKey = $env:R2_ACCESS_KEY_ID
    $secretKey = $env:R2_SECRET_ACCESS_KEY
    $accountId = $env:R2_ACCOUNT_ID
    $bucket    = $env:R2_BUCKET_NAME
    $endpoint  = "https://$accountId.r2.cloudflarestorage.com"

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

    function HmacSHA256Bytes([byte[]]$keyBytes, [string]$data) {
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = $keyBytes
        return $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data))
    }

    function SHA256Hex([string]$str) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($str)) | ForEach-Object { $_.ToString("x2") }) -join ""
    }

    function Invoke-R2Request($method, $path, $queryString = "") {
        $date      = [DateTime]::UtcNow
        $dateStamp = $date.ToString("yyyyMMdd")
        $amzDate   = $date.ToString("yyyyMMddTHHmmssZ")

        $payloadHash      = SHA256Hex ""
        $canonicalHeaders = "host:$accountId.r2.cloudflarestorage.com`nx-amz-content-sha256:$payloadHash`nx-amz-date:$amzDate`n"
        $signedHeaders    = "host;x-amz-content-sha256;x-amz-date"
        $canonicalRequest = "$method`n$path`n$queryString`n$canonicalHeaders`n$signedHeaders`n$payloadHash"

        $credentialScope = "$dateStamp/$region/$service/aws4_request"
        $stringToSign    = "AWS4-HMAC-SHA256`n$amzDate`n$credentialScope`n$(SHA256Hex $canonicalRequest)"

        $kSecret  = [System.Text.Encoding]::UTF8.GetBytes("AWS4$secretKey")
        $kDate    = HmacSHA256Bytes $kSecret  $dateStamp
        $kRegion  = HmacSHA256Bytes $kDate    $region
        $kService = HmacSHA256Bytes $kRegion  $service
        $kSigning = HmacSHA256Bytes $kService "aws4_request"
        $signature = (HmacSHA256Bytes $kSigning $stringToSign | ForEach-Object { $_.ToString("x2") }) -join ""

        $authorization = "AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
        $reqHeaders    = @{ "Authorization" = $authorization; "x-amz-date" = $amzDate; "x-amz-content-sha256" = $payloadHash }

        $uri = if ($queryString) { "$endpoint${path}?$queryString" } else { "$endpoint$path" }
        return Invoke-RestMethod -Uri $uri -Method $method -Headers $reqHeaders -ErrorAction SilentlyContinue
    }

    $results = @()

    foreach ($filePath in $filePaths) {
        $fileName = [System.IO.Path]::GetFileName($filePath.Trim())
        $encodedFileName = [Uri]::EscapeDataString($fileName)

        $listResult = Invoke-R2Request "GET" "/$bucket" "prefix=$encodedFileName"
        $keys = $listResult.ListBucketResult.Contents | ForEach-Object { $_.Key } | Where-Object { $_ -eq $fileName }

        if (-not $keys) {
            $results += "Not found: $fileName"
            continue
        }

        $deleted = 0
        foreach ($key in $keys) {
            Invoke-R2Request "DELETE" "/$bucket/$([Uri]::EscapeDataString($key))" | Out-Null
            $deleted++
        }
        $results += "Deleted: $fileName"
    }

    Write-Output ($results -join "`n")

} catch {
    Write-Output "Error: $_"
}