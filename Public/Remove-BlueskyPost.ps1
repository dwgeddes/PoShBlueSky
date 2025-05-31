function Remove-BlueskyPost {
    <#
    .SYNOPSIS
        Removes (deletes) a post from Bluesky.
    .DESCRIPTION
        Deletes a post from your Bluesky account using the post URI.
        You can only delete your own posts.
    .PARAMETER PostUri
        The URI of the post to delete (e.g., "at://did:plc:xyz/app.bsky.feed.post/abc123").
    .EXAMPLE
        PS> Remove-BlueskyPost -PostUri "at://did:plc:ixen5i426cpidtesanwni5hu/app.bsky.feed.post/3lq45lj4q7y23"
        Deletes the specified post.
    .EXAMPLE
        PS> $post = Get-BlueskyTimeline | Select-Object -First 1
        PS> Remove-BlueskyPost -PostUri $post.PostUri
        Deletes your most recent post.
    .OUTPUTS
        PSCustomObject
        Returns the result of the delete operation.
    .NOTES
        You can only delete posts that you authored.
        Once deleted, a post cannot be recovered.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The URI of the post to delete.")]
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
            
            if ($PSCmdlet.ShouldProcess($PostUri, "Delete post")) {
                $result = Remove-BlueskyPostApi -Session $session -PostUri $PostUri
                
                if ($result) {
                    Write-Information "Post deleted successfully" -InformationAction Continue
                    
                    return [PSCustomObject]@{
                        Success = $true
                        DeletedUri = $PostUri
                        DeletedAt = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Delete operation failed: No response from API"
                }
            }
            
        } catch {
            $errorMessage = switch -Regex ($_.Exception.Message) {
                '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                '403|Forbidden' { "Access denied. You can only delete your own posts." }
                '404|Not Found' { "Post not found. It may have already been deleted or the URI is invalid." }
                'Invalid.*URI' { "Invalid post URI format. Please provide a valid AT Protocol URI." }
                default { "Failed to delete post: $($_.Exception.Message)" }
            }
            Write-Error $errorMessage
            return $null
        }
    }
}
