function Upload-BlueSkyImageApi {
    <#
    .SYNOPSIS
        Uploads an image to BlueSky and returns the blob reference.
    .DESCRIPTION
        Internal API function to upload images to BlueSky for use in posts and profile updates.
        Supports both file paths and base64-encoded image data.
    .PARAMETER Session
        The authenticated session object.
    .PARAMETER Path
        The file path to the image to upload.
    .PARAMETER Base64
        Base64-encoded image data to upload.
    .PARAMETER MimeType
        The MIME type of the image. If not specified, attempts to detect from file extension or data.
    .OUTPUTS
        PSCustomObject
        Returns an object with blob, mimeType, and size properties.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Session,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Path',
                   HelpMessage = "The file path to the image to upload.")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Base64',
                   HelpMessage = "Base64-encoded image data to upload.")]
        [ValidateNotNullOrEmpty()]
        [string]$Base64,
        
        [Parameter(Mandatory = $false, HelpMessage = "The MIME type of the image.")]
        [ValidateNotNullOrEmpty()]
        [string]$MimeType
    )
    
    try {
        $endpoint = '/xrpc/com.atproto.repo.uploadBlob'
        $baseUrl = 'https://bsky.social'
        
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            # Handle file upload
            if (-not $MimeType) {
                $extension = [System.IO.Path]::GetExtension($Path).ToLower()
                $MimeType = switch ($extension) {
                    '.jpg'  { 'image/jpeg' }
                    '.jpeg' { 'image/jpeg' }
                    '.png'  { 'image/png' }
                    '.gif'  { 'image/gif' }
                    '.webp' { 'image/webp' }
                    default { 'image/jpeg' }
                }
            }
            
            $fileBytes = [System.IO.File]::ReadAllBytes($Path)
        } else {
            # Handle base64 upload
            if (-not $MimeType) {
                # Try to detect from base64 header
                if ($Base64.StartsWith('data:')) {
                    $headerEnd = $Base64.IndexOf(';')
                    if ($headerEnd -gt 0) {
                        $MimeType = $Base64.Substring(5, $headerEnd - 5)
                        $Base64 = $Base64.Substring($Base64.IndexOf(',') + 1)
                    }
                } else {
                    $MimeType = 'image/jpeg' # Default
                }
            }
            
            $fileBytes = [System.Convert]::FromBase64String($Base64)
        }
        
        $headers = @{
            'Authorization' = "Bearer $($Session.AccessToken)"
            'Content-Type' = $MimeType
            'User-Agent' = 'PowerShell-BlueskyCLI/1.0'
        }
        
        $uri = "$baseUrl$endpoint"
        
        $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $fileBytes
        
        if ($response -and $response.PSObject.Properties.Name -contains 'blob') {
            return [PSCustomObject]@{
                blob = $response.blob
                mimeType = $MimeType
                size = $fileBytes.Length
            }
        } else {
            throw "Upload failed: No blob reference returned"
        }
    } catch {
        Write-Error "Failed to upload image: $_"
        return $null
    }
}
