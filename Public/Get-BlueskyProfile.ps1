function Get-BlueskyProfile {
    <#
    .SYNOPSIS
        Retrieves the profile information for the authenticated BlueSky user or a specified actor.
    .PARAMETER Actor
        The handle or DID of the actor to retrieve the profile for. Defaults to the current session's handle.
    .OUTPUTS
        PSCustomObject
        Returns a user-friendly profile object with clean property names.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipeline)]
        [string]$Handle
    )
    
    process {
        try {
            if (-not $module:BlueskySession) {
                Write-Error "Not connected to Bluesky. Use Connect-BlueskySession first."
                return $null
            }
            
            $targetHandle = $Handle ?? $module:BlueskySession.Handle
            
            $headers = @{
                "Authorization" = "Bearer $($module:BlueskySession.AccessJwt)"
            }
            
            $uri = "https://bsky.social/xrpc/app.bsky.actor.getProfile?actor=$targetHandle"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers
            
            return [PSCustomObject]@{
                Handle = $response.handle
                DisplayName = $response.displayName
                Description = $response.description
                FollowersCount = $response.followersCount
                FollowsCount = $response.followsCount
                PostsCount = $response.postsCount
                Avatar = $response.avatar
                Did = $response.did
            }
            
        } catch {
            Write-Error "Failed to get profile for '$targetHandle': $($_.Exception.Message)"
            return $null
        }
    }
}
