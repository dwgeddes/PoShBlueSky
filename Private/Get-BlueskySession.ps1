function Get-BlueskySessionInternal {
    <#
    .SYNOPSIS
        Retrieves or creates a BlueSky session for API requests.
    .DESCRIPTION
        Handles credential retrieval, authentication, and session caching. Abstracts session management for public cmdlets.
    #>
    param()
    
    if ($module:BlueskySession -and $module:BlueskySession.Expires -gt (Get-Date)) {
        return $module:BlueskySession
    }
    
    $username = $env:BLUESKY_USERNAME
    $password = $env:BLUESKY_PASSWORD
    if (-not $username -or -not $password) {
        Write-Warning 'BlueSky credentials not found. Set BLUESKY_USERNAME and BLUESKY_PASSWORD environment variables or use Connect-BlueskySession.'
        return $null
    }
    
    $authEndpoint = 'https://bsky.social/xrpc/com.atproto.server.createSession'
    $body = @{ identifier = $username; password = $password }
    
    try {
        Write-Warning "Using environment variable credentials. For better security, use Connect-BlueskySession with Get-Credential."
        $response = Invoke-RestMethod -Uri $authEndpoint -Method 'POST' -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        $session = [PSCustomObject]@{
            AccessToken = $response.accessJwt
            RefreshToken = $response.refreshJwt
            AccessJwt = $response.accessJwt
            RefreshJwt = $response.refreshJwt
            Expires = (Get-Date).AddHours(12)
            Username = $username
            Handle   = if ($response.PSObject.Properties.Name -contains 'handle') { $response.handle } else { $username }
            Did      = if ($response.PSObject.Properties.Name -contains 'did') { $response.did } else { $null }
        }
        $module:BlueskySession = $session
        return $session
    }
    catch {
        Write-Error "Failed to authenticate with BlueSky: $_"
        return $null
    }
}
