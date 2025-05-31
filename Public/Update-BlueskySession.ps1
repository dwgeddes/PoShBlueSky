function Update-BlueskySession {
    <#
    .SYNOPSIS
        Refreshes the current Bluesky session authentication tokens.
    .DESCRIPTION
        Updates the session tokens using the refresh token to extend the session lifetime.
        This should be called when the access token is nearing expiration.
    .EXAMPLE
        PS> Update-BlueskySession
        Refreshes the current session tokens.
    .OUTPUTS
        PSCustomObject
        Returns the updated session information or null on failure.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        if (-not $module:BlueskySession) {
            Write-Error "No active session found. Please connect first using Connect-BlueskySession"
            return $null
        }
        
        if ($PSCmdlet.ShouldProcess("Bluesky Session", "Refresh authentication tokens")) {
            $headers = @{
                "Authorization" = "Bearer $($module:BlueskySession.RefreshJwt)"
                "Content-Type" = "application/json"
            }
            
            $response = Invoke-RestMethod -Uri "https://bsky.social/xrpc/com.atproto.server.refreshSession" -Method Post -Headers $headers
            
            # Update module session
            $module:BlueskySession.AccessJwt = $response.accessJwt
            $module:BlueskySession.RefreshJwt = $response.refreshJwt
            $module:BlueskySession.Handle = $response.handle
            $module:BlueskySession.Did = $response.did
            
            Write-Information "Session refreshed successfully" -InformationAction Continue
            
            return [PSCustomObject]@{
                Handle = $response.handle
                Did = $response.did
                Status = "Refreshed"
                UpdatedAt = Get-Date
            }
        }
        
    } catch {
        Write-Error "Failed to refresh session: $($_.Exception.Message)"
        return $null
    }
}
