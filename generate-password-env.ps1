# generate-password-env.ps1
# Reads length from ESPANSO_LENGTH environment variable

try {
    # Set UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Get length from environment variable
    $Length = [int]$env:ESPANSO_LENGTH
    
    # Validate length
    if ($Length -lt 4) {
        $Length = 4
    }
    if ($Length -gt 128) {
        $Length = 128
    }
    
    # Character sets
    $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lowercase = "abcdefghijklmnopqrstuvwxyz"
    $numbers = "0123456789"
    $specialChars = "!@#$%^&*()-_=+[]{}|;:,.<>?"
    
    # Build character pool
    $charPool = $uppercase + $lowercase + $numbers + $specialChars
    
    # Generate password
    $password = ""
    $random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] 1
    
    for ($i = 0; $i -lt $Length; $i++) {
        $random.GetBytes($bytes)
        $password += $charPool[$bytes[0] % $charPool.Length]
    }
    
    # Ensure at least one character from each category
    if ($Length -ge 4) {
        $ensureChars = @(
            $uppercase[(Get-Random -Maximum $uppercase.Length)],
            $lowercase[(Get-Random -Maximum $lowercase.Length)],
            $numbers[(Get-Random -Maximum $numbers.Length)],
            $specialChars[(Get-Random -Maximum $specialChars.Length)]
        )
        
        # Replace random positions
        for ($i = 0; $i -lt 4; $i++) {
            $pos = Get-Random -Maximum $Length
            $password = $password.Remove($pos, 1).Insert($pos, $ensureChars[$i])
        }
    }
    
    # Copy to clipboard
    $password | Set-Clipboard
    
    # Output password
    Write-Output $password
    
} catch {
    Write-Output "Error: $_"
}
