function Get-BlueskyTimeline {
    <#
    .SYNOPSIS
        Retrieves the timeline for the authenticated Bluesky user.
    .PARAMETER Limit
        The maximum number of timeline items to retrieve.
    .PARAMETER Cursor
        The pagination cursor.
    .OUTPUTS
        PSCustomObject[]
        Returns user-friendly timeline objects with clean property names.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The maximum number of timeline items to retrieve.")]
        [int]$Limit = 20,
        [Parameter(Mandatory = $false, HelpMessage = "The pagination cursor.")]
        [string]$Cursor = ""
    )
    
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
        return @()
    }
    
    $params = @{ limit = $Limit }
    if ($Cursor) { $params.cursor = $Cursor }
    $result = Get-BlueskyTimelineApi -Session $session -Params $params
    
    if ($result) {
        # Transform timeline posts to user-friendly format
        return $result | ForEach-Object {
            $post = $_.post
            $reason = $_.reason
            
            # Convert AT URI to user-friendly URL
            $postUrl = Convert-AtUriToUrl -AtUri $post.uri
            $postIdentifier = Get-PostIdentifierFromUri -AtUri $post.uri
            
            # Extract reply information
            $isReply = $false
            $replyToUri = $null
            $replyToUrl = $null
            $replyToIdentifier = $null
            $rootPostUri = $null
            $rootPostIdentifier = $null
            if ($post.record -and $post.record.reply) {
                $isReply = $true
                $replyToUri = $post.record.reply.parent.uri
                $replyToUrl = Convert-AtUriToUrl -AtUri $replyToUri
                $replyToIdentifier = Get-PostIdentifierFromUri -AtUri $replyToUri
                $rootPostUri = $post.record.reply.root.uri
                $rootPostIdentifier = Get-PostIdentifierFromUri -AtUri $rootPostUri
            }
            
            # Extract embed information
            $embedType = $null
            $embedData = $null
            if ($post.embed) {
                $embedType = $post.embed.'$type'
                $embedData = switch ($embedType) {
                    'app.bsky.embed.images#view' { 
                        @{
                            Type = 'Images'
                            Count = $post.embed.images.Count
                            Images = $post.embed.images | ForEach-Object { 
                                @{
                                    Alt = $_.alt
                                    Thumb = $_.thumb
                                    Fullsize = $_.fullsize
                                    AspectRatio = $_.aspectRatio
                                }
                            }
                        }
                    }
                    'app.bsky.embed.external#view' {
                        @{
                            Type = 'External'
                            Title = $post.embed.external.title
                            Description = $post.embed.external.description
                            Uri = $post.embed.external.uri
                            Thumb = $post.embed.external.thumb
                        }
                    }
                    'app.bsky.embed.record#view' {
                        $quotedPostUri = $post.embed.record.uri
                        @{
                            Type = 'Quote'
                            QuotedPostUri = $quotedPostUri
                            QuotedPostUrl = Convert-AtUriToUrl -AtUri $quotedPostUri
                            QuotedPostIdentifier = Get-PostIdentifierFromUri -AtUri $quotedPostUri
                            QuotedAuthor = $post.embed.record.author.handle
                            QuotedText = $post.embed.record.value.text
                        }
                    }
                    default { $post.embed }
                }
            }
            
            # Extract facets (mentions, links, hashtags) with proper bounds checking
            $mentions = @()
            $links = @()
            $hashtags = @()
            if ($post.record.facets -and $post.record.text) {
                $postText = $post.record.text
                $textLength = $postText.Length
                
                foreach ($facet in $post.record.facets) {
                    if ($facet.index -and $facet.features) {
                        $startIndex = [int]$facet.index.byteStart
                        $endIndex = [int]$facet.index.byteEnd
                        
                        # Validate indices to prevent substring errors
                        if ($startIndex -ge 0 -and $endIndex -gt $startIndex -and $startIndex -lt $textLength) {
                            # Ensure end index doesn't exceed string length
                            $endIndex = [Math]::Min($endIndex, $textLength)
                            $length = $endIndex - $startIndex
                            
                            if ($length -gt 0) {
                                try {
                                    $facetText = $postText.Substring($startIndex, $length)
                                    
                                    foreach ($feature in $facet.features) {
                                        switch ($feature.'$type') {
                                            'app.bsky.richtext.facet#mention' {
                                                $mentions += @{
                                                    Did = $feature.did
                                                    Text = $facetText
                                                }
                                            }
                                            'app.bsky.richtext.facet#link' {
                                                $links += @{
                                                    Uri = $feature.uri
                                                    Text = $facetText
                                                }
                                            }
                                            'app.bsky.richtext.facet#tag' {
                                                $hashtags += @{
                                                    Tag = $feature.tag
                                                    Text = $facetText
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    $errorMsg = $_.Exception.Message
                                    Write-Verbose "Failed to extract facet text at position $startIndex-$endIndex`: $errorMsg"
                                }
                            }
                        }
                    }
                }
            }
            
            # Create clean, user-friendly timeline object
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
                RootPostUri = $rootPostUri
                RootPostIdentifier = $rootPostIdentifier
                
                # Embed information
                HasEmbed = if ($post.embed) { $true } else { $false }
                EmbedType = $embedType
                EmbedData = $embedData
                
                # Legacy image fields for backward compatibility
                HasImages = if ($post.embed -and $post.embed.images) { $true } else { $false }
                ImageCount = if ($post.embed -and $post.embed.images) { $post.embed.images.Count } else { 0 }
                
                # Rich text features
                Mentions = $mentions
                Links = $links
                Hashtags = $hashtags
                
                # Timeline-specific information
                ReasonType = if ($reason) { $reason.type } else { $null }
                ReasonBy = if ($reason -and $reason.by) { "@$($reason.by.handle)" } else { $null }
                ReasonByName = if ($reason -and $reason.by) { 
                    if ($reason.by.displayName) { $reason.by.displayName } else { $reason.by.handle } 
                } else { $null }
                
                # Content moderation
                Labels = $post.labels
                
                # Languages
                Languages = $post.record.langs
                
                # Author additional info
                AuthorAvatar = $post.author.avatar
                AuthorDescription = if ($post.author.description) {
                    # Truncate long descriptions
                    if ($post.author.description.Length -gt 100) {
                        $post.author.description.Substring(0, 100) + "..."
                    } else {
                        $post.author.description
                    }
                } else { $null }
                
                # Keep original data for advanced users
                _RawData = $_
            }
        }
    }
    
    return $result
}
