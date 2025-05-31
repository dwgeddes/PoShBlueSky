function Search-BlueskyPost {
    <#
    .SYNOPSIS
        Searches for posts on Bluesky using text queries.
    .DESCRIPTION
        Searches the Bluesky network for posts matching the specified query.
        Returns posts with user-friendly formatting and metadata.
    .PARAMETER Query
        The search query text to find posts.
    .PARAMETER Limit
        Maximum number of posts to return (default: 25, max: 100).
    .PARAMETER Cursor
        Pagination cursor for retrieving additional results.
    .EXAMPLE
        PS> Search-BlueskyPost -Query "PowerShell"
        Searches for posts containing "PowerShell".
    .EXAMPLE
        PS> Search-BlueskyPost -Query "from:user.bsky.social PowerShell" -Limit 50
        Searches for PowerShell posts from a specific user.
    .OUTPUTS
        PSCustomObject[]
        Returns an array of post objects with user-friendly properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The search query text.")]
        [ValidateNotNullOrEmpty()]
        [string]$Query,
        
        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of posts to return.")]
        [ValidateRange(1, 100)]
        [int]$Limit = 25,
        
        [Parameter(Mandatory = $false, HelpMessage = "Pagination cursor.")]
        [string]$Cursor
    )
    
    try {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return @()
        }
        
        $params = @{ 
            q = $Query
            limit = $Limit
        }
        if ($Cursor) { $params.cursor = $Cursor }
        
        $searchResult = Search-BlueskyPostsApi -Session $session -Params $params
        
        if ($searchResult) {
            # Transform search results to user-friendly format
            return $searchResult | ForEach-Object {
                $post = $_
                
                # Convert AT URI to user-friendly URL
                $postUrl = Convert-AtUriToUrl -AtUri $post.uri
                $postIdentifier = Get-PostIdentifierFromUri -AtUri $post.uri
                
                # Extract reply information
                $isReply = $false
                $replyToUri = $null
                $replyToUrl = $null
                $replyToIdentifier = $null
                if ($post.record -and $post.record.reply) {
                    $isReply = $true
                    $replyToUri = $post.record.reply.parent.uri
                    $replyToUrl = Convert-AtUriToUrl -AtUri $replyToUri
                    $replyToIdentifier = Get-PostIdentifierFromUri -AtUri $replyToUri
                }
                
                [PSCustomObject]@{
                    # Basic post information
                    AuthorName = if ($post.author.displayName) { $post.author.displayName } else { $post.author.handle }
                    AuthorHandle = "@$($post.author.handle)"
                    AuthorDid = $post.author.did
                    Text = $post.record.text
                    PostUrl = $postUrl
                    PostUri = $post.uri
                    PostCid = $post.cid
                    PostIdentifier = $postIdentifier
                    
                    # Timestamps
                    CreatedAt = [DateTime]$post.record.createdAt
                    IndexedAt = [DateTime]$post.indexedAt
                    
                    # Engagement metrics
                    LikeCount = if ($post.likeCount) { $post.likeCount } else { 0 }
                    RepostCount = if ($post.repostCount) { $post.repostCount } else { 0 }
                    ReplyCount = if ($post.replyCount) { $post.replyCount } else { 0 }
                    QuoteCount = if ($post.quoteCount) { $post.quoteCount } else { 0 }
                    
                    # User's interaction with this post
                    IsLiked = if ($post.viewer -and $post.viewer.like) { $true } else { $false }
                    LikeUri = if ($post.viewer -and $post.viewer.like) { $post.viewer.like } else { $null }
                    IsReposted = if ($post.viewer -and $post.viewer.repost) { $true } else { $false }
                    RepostUri = if ($post.viewer -and $post.viewer.repost) { $post.viewer.repost } else { $null }
                    
                    # Reply information
                    IsReply = $isReply
                    ReplyToUri = $replyToUri
                    ReplyToUrl = $replyToUrl
                    ReplyToIdentifier = $replyToIdentifier
                    
                    # Embed information
                    HasEmbed = if ($post.embed) { $true } else { $false }
                    EmbedType = if ($post.embed) { $post.embed.'$type' } else { $null }
                    
                    # Legacy fields for backward compatibility
                    HasImages = if ($post.embed -and $post.embed.images) { $true } else { $false }
                    ImageCount = if ($post.embed -and $post.embed.images) { $post.embed.images.Count } else { 0 }
                    
                    # Content moderation
                    Labels = $post.labels
                    
                    # Languages
                    Languages = $post.record.langs
                    
                    # Keep original data for advanced users
                    _RawData = $post
                }
            }
        } else {
            Write-Warning "No posts found matching query: '$Query'"
            return @()
        }
        
    } catch {
        Write-Error "Failed to search posts: $_"
        return @()
    }
}
