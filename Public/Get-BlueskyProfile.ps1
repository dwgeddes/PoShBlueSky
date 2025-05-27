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
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="The handle or DID of the actor.")]
        [ValidateNotNullOrEmpty()]
        [string]$Actor
    )
    
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
        return $null
    }
    
    if (-not $Actor) {
        $Actor = $session.Username
    }
    $params = @{ actor = $Actor }
    $result = Get-BlueskyProfileApi -Session $session -Params $params
    
    if ($result) {
        # Transform profile to user-friendly format
        $profileUrl = "https://bsky.app/profile/$($result.handle)"
        
        return [PSCustomObject]@{
            DisplayName = $result.displayName
            Handle = "@$($result.handle)"
            ProfileUrl = $profileUrl
            Description = $result.description
            FollowersCount = if ($result.followersCount) { $result.followersCount } else { 0 }
            FollowingCount = if ($result.followsCount) { $result.followsCount } else { 0 }
            PostsCount = if ($result.postsCount) { $result.postsCount } else { 0 }
            Avatar = $result.avatar
            Banner = $result.banner
            CreatedAt = if ($result.createdAt) { [DateTime]$result.createdAt } else { $null }
            IsFollowing = if ($result.viewer -and $result.viewer.following) { $true } else { $false }
            IsFollowedBy = if ($result.viewer -and $result.viewer.followedBy) { $true } else { $false }
            IsBlocked = if ($result.viewer -and $result.viewer.blocking) { $true } else { $false }
            IsMuted = if ($result.viewer -and $result.viewer.muted) { $true } else { $false }
            # Keep original data for advanced users
            _RawData = $result
        }
    }
    
    return $null
}
