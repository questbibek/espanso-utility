# r2-clear-core.ps1
# Pass -OlderThanDays 0 to delete everything, or N to delete older than N days

param([int]$OlderThanDays = 0)

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $accessKey = $env:R2_ACCESS_KEY_ID
    $secretKey = $env:R2_SECRET_ACCESS_KEY
    $accountId = $env:R2_ACCOUNT_ID
    $bucket    = $env:R2_BUCKET_NAME
    $endpoint  = "https://$accountId.r2.cloudflarestorage.com"

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

    $cutoffDate        = if ($OlderThanDays -gt 0) { [DateTime]::UtcNow.AddDays(-$OlderThanDays) } else { $null }
    $totalDeleted      = 0
    $continuationToken = $null

    do {
        $qs = "list-type=2&max-keys=1000"
        if ($continuationToken) { $qs += "&continuation-token=$([Uri]::EscapeDataString($continuationToken))" }

        $listResult = Invoke-R2Request "GET" "/$bucket" $qs
        $contents   = $listResult.ListBucketResult.Contents

        if ($contents) {
            foreach ($obj in $contents) {
                $shouldDelete = $true
                if ($cutoffDate) {
                    $shouldDelete = ([DateTime]::Parse($obj.LastModified)) -lt $cutoffDate
                }
                if ($shouldDelete) {
                    Invoke-R2Request "DELETE" "/$bucket/$([Uri]::EscapeDataString($obj.Key))" | Out-Null
                    $totalDeleted++
                }
            }
        }

        $isTruncated       = $listResult.ListBucketResult.IsTruncated -eq "true"
        $continuationToken = $listResult.ListBucketResult.NextContinuationToken

    } while ($isTruncated)

    $label = if ($OlderThanDays -gt 0) { "older than $OlderThanDays day(s)" } else { "all" }
    Write-Output "Deleted $totalDeleted object(s) ($label) from bucket: $bucket"

} catch {
    Write-Output "Error: $_"
}