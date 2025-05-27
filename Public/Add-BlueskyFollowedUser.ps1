function Add-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Follows a user on BlueSky.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="The DID of the user to follow.")]
        [ValidateNotNullOrEmpty()]
        [string]$UserDid
    )
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        $result = Set-BlueskyFollowedUserApi -Session $session -UserDid $UserDid
        return $result
    }
}

function Remove-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Unfollows a user on BlueSky.
    .PARAMETER FollowUri
        The URI of the follow record to remove (unfollow).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="The URI of the follow record to remove.")]
        [ValidateNotNullOrEmpty()]
        [string]$FollowUri
    )
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        $result = Remove-BlueskyFollowedUserApi -Session $session -FollowUri $FollowUri
        return $result
    }
}
