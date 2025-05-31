function Remove-BlueskyLike {
    <#
    .SYNOPSIS
        Removes a like from a post on Bluesky.
    .DESCRIPTION
        Unlikes a previously liked post by removing the like record.
    .PARAMETER LikeUri
        The URI of the like record to remove.
    .EXAMPLE
        PS> Remove-BlueskyLike -LikeUri "at://did:plc:example/app.bsky.feed.like/abc123"
        Removes the like from the post.
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
