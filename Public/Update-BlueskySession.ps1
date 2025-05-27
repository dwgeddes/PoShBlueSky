function Update-BlueskySession {
    <#
    .SYNOPSIS
        Refreshes the current Bluesky session using the refresh token.
    .DESCRIPTION
        Calls the Bluesky API to refresh expired or expiring session tokens 
        and updates the global session object with new authentication credentials.
    .EXAMPLE
        PS> Update-BlueskySession
        Refreshes the current session tokens.
    .OUTPUTS
        PSCustomObject
        Returns the updated session object with new tokens.
    .NOTES
        Requires an active session with a valid refresh token.
        Automatically updates the global BlueskySession variable.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $currentSession = $global:BlueskySession
    
    if (-not $currentSession) {
        Write-Warning "No active session found. Please connect first by running 'Connect-BlueskySession'."
        return $null
    }
    
    if (-not $currentSession.RefreshToken) {
        Write-Warning "No refresh token available in current session. Please reconnect using 'Connect-BlueskySession'."
        return $null
    }
    
    try {
        $refreshEndpoint = "/xrpc/com.atproto.server.refreshSession"
        $requestHeaders = @{
            'Authorization' = "Bearer $($currentSession.RefreshToken)"
            'Content-Type' = 'application/json'
            'User-Agent' = 'PowerShell-BlueskyCLI/1.0'
        }
        
        Write-Verbose "Refreshing session tokens for user: $($currentSession.Username)"
        
        $refreshResponse = Invoke-RestMethod -Uri ("https://bsky.social" + $refreshEndpoint) -Method POST -Headers $requestHeaders -ErrorAction Stop
        
        if (-not $refreshResponse -or -not $refreshResponse.accessJwt) {
            throw "Token refresh failed: Invalid response from Bluesky service."
        }
        
        # Update session with new tokens
        $global:BlueskySession.AccessToken = $refreshResponse.accessJwt
        $global:BlueskySession.RefreshToken = $refreshResponse.refreshJwt
        $global:BlueskySession.ExpiresAt = (Get-Date).AddHours(12)
        
        Write-Host "Session tokens refreshed successfully" -ForegroundColor Green
        return $global:BlueskySession
        
    } catch [System.Net.WebException] {
        $errorMessage = "Network error during token refresh: $($_.Exception.Message)"
        Write-Error $errorMessage
        return $null
    } catch {
        $errorMessage = switch -Regex ($_.Exception.Message) {
            'Unauthorized|401' { "Token refresh failed: Refresh token is invalid or expired. Please reconnect using 'Connect-BlueskySession'." }
            'Forbidden|403' { "Token refresh denied: Your session may have been revoked. Please reconnect using 'Connect-BlueskySession'." }
            'Not Found|404' { "Service unavailable: Unable to reach Bluesky token refresh service." }
            default { "Failed to refresh session tokens: $($_.Exception.Message)" }
        }
        Write-Error $errorMessage
        return $null
    }
}
