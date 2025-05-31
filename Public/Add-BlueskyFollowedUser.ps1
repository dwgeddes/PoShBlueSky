function Add-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Follows a user on BlueSky.
    .DESCRIPTION
        Adds a user to your following list.
    .PARAMETER UserDid
        The DID of the user to follow.
    .OUTPUTS
        PSCustomObject
        Returns the result of the follow operation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
                   HelpMessage = "The DID of the user to follow.")]
        [ValidateNotNullOrEmpty()]
        [string]$UserDid
    )
    
    process {
        try {
            $session = Get-BlueskySession -Raw
            if (-not $session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }
            
            if ($PSCmdlet.ShouldProcess($UserDid, "Follow user")) {
                $result = Set-BlueskyFollowedUserApi -Session $session -UserDid $UserDid
                
                if ($result) {
                    Write-Information "User followed successfully" -InformationAction Continue
                    
                    return [PSCustomObject]@{
                        Success = $true
                        FollowedUserDid = $UserDid
                        FollowUri = $result.uri
                        FollowedAt = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Follow operation failed: No response from API"
                }
            }
        } catch {
            Write-Error "Failed to follow user: $($_.Exception.Message)"
            return $null
        }
    }
}

function Remove-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Unfollows a user on BlueSky.
    .DESCRIPTION
        Removes a user from your following list by deleting the follow record.
    .PARAMETER FollowUri
        The URI of the follow record to remove (unfollow).
    .OUTPUTS
        PSCustomObject
        Returns the result of the unfollow operation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
                   HelpMessage = "The URI of the follow record to remove.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^at://')]
        [string]$FollowUri
    )
    
    process {
        try {
            $session = Get-BlueskySession -Raw
            if (-not $session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }
            
            if ($PSCmdlet.ShouldProcess($FollowUri, "Unfollow user")) {
                $result = Remove-BlueskyFollowedUserApi -Session $session -FollowUri $FollowUri
                
                if ($result) {
                    Write-Information "User unfollowed successfully" -InformationAction Continue
                    
                    return [PSCustomObject]@{
                        Success = $true
                        UnfollowedUri = $FollowUri
                        UnfollowedAt = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Unfollow operation failed: No response from API"
                }
            }
        } catch {
            Write-Error "Failed to unfollow user: $($_.Exception.Message)"
            return $null
        }
    }
}
