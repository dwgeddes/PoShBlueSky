function Add-BlueskyLike {
    <#
    .SYNOPSIS
        Likes a post on BlueSky.
    .DESCRIPTION
        Adds a like to the specified post.
    .PARAMETER PostUri
        The URI of the post to like.
    .OUTPUTS
        PSCustomObject
        Returns the result of the like operation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
                   HelpMessage = "The URI of the post to like.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^at://')]
        [string]$PostUri
    )
    
    process {
        try {
            $session = Get-BlueskySession -Raw
            if (-not $session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }
            
            if ($PSCmdlet.ShouldProcess($PostUri, "Like post")) {
                $result = Add-BlueskyLikeApi -Session $session -PostUri $PostUri
                
                if ($result) {
                    Write-Information "Post liked successfully" -InformationAction Continue
                    
                    return [PSCustomObject]@{
                        Success = $true
                        LikedUri = $PostUri
                        LikeUri = $result.uri
                        LikedAt = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Like operation failed: No response from API"
                }
            }
        } catch {
            Write-Error "Failed to like post: $($_.Exception.Message)"
            return $null
        }
    }
}

function Remove-BlueskyLike {
    <#
    .SYNOPSIS
        Removes a like from a post on Bluesky.
    .DESCRIPTION
        Unlikes a previously liked post by removing the like record.
    .PARAMETER LikeUri
        The URI of the like record to remove.
    .OUTPUTS
        PSCustomObject
        Returns the result of the unlike operation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
                   HelpMessage = "The URI of the like record to remove.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^at://')]
        [string]$LikeUri
    )
    
    process {
        try {
            $session = Get-BlueskySession -Raw
            if (-not $session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }
            
            if ($PSCmdlet.ShouldProcess($LikeUri, "Unlike post")) {
                $result = Remove-BlueskyLikeApi -Session $session -LikeUri $LikeUri
                
                if ($result) {
                    Write-Information "Post unliked successfully" -InformationAction Continue
                    
                    return [PSCustomObject]@{
                        Success = $true
                        UnlikedUri = $LikeUri
                        UnlikedAt = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Unlike operation failed: No response from API"
                }
            }
        } catch {
            Write-Error "Failed to unlike post: $($_.Exception.Message)"
            return $null
        }
    }
}
