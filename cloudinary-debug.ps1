$cloudName = $env:CLOUDINARY_CLOUD_NAME
$apiKey    = $env:CLOUDINARY_API_KEY
$apiSecret = $env:CLOUDINARY_API_SECRET

Write-Output "cloud: $cloudName"
Write-Output "key:   $apiKey"
Write-Output "secret len: $($apiSecret.Length)"

function Get-Sha1Hex([string]$str) {
    $sha1  = [System.Security.Cryptography.SHA1]::Create()
    $bytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($str))
    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

# Cloudinary signature: ONLY the params being sent, sorted, NO api_key in sig
# params: max_results, timestamp  → alphabetical: max_results < timestamp ✓
$sigString = "max_results=10&timestamp=$timestamp$apiSecret"
Write-Output "sigString: $sigString"
$signature = Get-Sha1Hex $sigString
Write-Output "signature: $signature"

$url = "https://api.cloudinary.com/v1_1/$cloudName/resources/image?max_results=10&timestamp=$timestamp&api_key=$apiKey&signature=$signature"
Write-Output "url: $url"

$response = curl.exe -s $url
Write-Output "RAW: $response"
