# cloudinary-clear-core.ps1
# Pass -OlderThanDays 0 to delete everything, N to delete older than N days

param([int]$OlderThanDays = 0)

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    $cloudName = $env:CLOUDINARY_CLOUD_NAME
    $apiKey    = $env:CLOUDINARY_API_KEY
    $apiSecret = $env:CLOUDINARY_API_SECRET

    function Get-Sha1Hex([string]$str) {
        $sha1  = [System.Security.Cryptography.SHA1]::Create()
        $bytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($str))
        return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
    }

    function Get-AllResources([string]$resourceType) {
        $resources  = @()
        $nextCursor = $null

        do {
            # Use Basic Auth for listing — more reliable than signed params
            $qs  = "max_results=500"
            if ($nextCursor) { $qs += "&next_cursor=$nextCursor" }
            $url = "https://api.cloudinary.com/v1_1/$cloudName/resources/$resourceType`?$qs"

            $response = curl.exe -s -u "${apiKey}:${apiSecret}" $url
            $result   = $response | ConvertFrom-Json

            if ($result.error) {
                Write-Output "API Error ($resourceType): $($result.error.message)"
                return @()
            }

            if ($result.resources) { $resources += $result.resources }
            $nextCursor = $result.next_cursor

        } while ($nextCursor)

        return $resources
    }

    function Invoke-CloudinaryDelete([string]$publicId, [string]$resourceType) {
        $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $sigString = "public_id=$publicId&timestamp=$timestamp$apiSecret"
        $signature = Get-Sha1Hex $sigString

        $response = curl.exe -s -X POST `
            "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy" `
            -F "public_id=$publicId" `
            -F "timestamp=$timestamp" `
            -F "api_key=$apiKey" `
            -F "signature=$signature"

        return ($response | ConvertFrom-Json).result
    }

    $cutoffDate   = if ($OlderThanDays -gt 0) { [DateTime]::UtcNow.AddDays(-$OlderThanDays) } else { $null }
    $totalDeleted = 0

    foreach ($resourceType in @("image", "video", "raw")) {
        $resources = Get-AllResources $resourceType
        Write-Output "Found $($resources.Count) $resourceType resource(s)..."

        foreach ($res in $resources) {
            $shouldDelete = $true
            if ($cutoffDate) {
                $shouldDelete = ([DateTime]::Parse($res.created_at)) -lt $cutoffDate
            }

            if ($shouldDelete) {
                $result = Invoke-CloudinaryDelete $res.public_id $resourceType
                if ($result -eq "ok") { $totalDeleted++ }
                else { Write-Output "Failed: $($res.public_id) ($result)" }
            }
        }
    }

    $label = if ($OlderThanDays -gt 0) { "older than $OlderThanDays day(s)" } else { "all" }
    Write-Output "Deleted $totalDeleted resource(s) ($label) from Cloudinary"

} catch {
    Write-Output "Error: $_"
}