function Get-BlueskySessionInternal {
    <#
    .SYNOPSIS
        Retrieves or creates a BlueSky session for API requests.
    .DESCRIPTION
        Handles credential retrieval, authentication, and session caching. Abstracts session management for public cmdlets.
    #>
    param()
    if ($global:BlueskySession -and $global:BlueskySession.Expires -gt (Get-Date)) {
        return $global:BlueskySession
    }
    $username = $env:BLUESKY_USERNAME
    $password = $env:BLUESKY_PASSWORD
    if (-not $username -or -not $password) {
        throw 'BlueSky credentials not found. Set BLUESKY_USERNAME and BLUESKY_PASSWORD environment variables.'
    }
    $authEndpoint = 'https://bsky.social/xrpc/com.atproto.server.createSession'
    $body = @{ identifier = $username; password = $password }
    try {
        $response = Invoke-RestMethod -Uri $authEndpoint -Method 'POST' -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        $session = [PSCustomObject]@{
            AccessToken = $response.accessJwt
            RefreshToken = $response.refreshJwt
            Expires = (Get-Date).AddHours(12)
            Username = $username
            Handle   = if ($response.PSObject.Properties.Name -contains 'handle') { $response.handle } else { $username }
            Did      = if ($response.PSObject.Properties.Name -contains 'did') { $response.did } else { $null }
        }
        $global:BlueskySession = $session
        return $session
    }
    catch {
        Write-Error "Failed to authenticate with BlueSky: $_"
        return $null
    }
}
