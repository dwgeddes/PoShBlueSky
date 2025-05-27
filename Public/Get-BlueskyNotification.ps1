function Get-BlueskyNotification {
    <#
    .SYNOPSIS
        Retrieves notifications for the authenticated BlueSky user.
    .DESCRIPTION
        Returns a list of notifications as PowerShell objects for the current session.
        Output is formatted for easy reading with user-friendly property names.
    .PARAMETER All
        If specified, retrieves all notifications with automatic pagination handling.
        Without this parameter, returns only the most recent notifications (default page).
    .PARAMETER Limit
        When using -All, specifies the maximum number of notifications to retrieve across all pages.
        When not using -All, this parameter is ignored as the API returns its default page size.
    .EXAMPLE
        PS> Get-BlueskyNotification
        Returns the most recent notifications (single page).
    .EXAMPLE
        PS> Get-BlueskyNotification -All
        Returns all notifications with automatic pagination.
    .EXAMPLE
        PS> Get-BlueskyNotification -All -Limit 500
        Returns up to 500 notifications across multiple pages.
    .OUTPUTS
        PSCustomObject[]
        Returns an array of notification objects with user-friendly properties.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve all notifications with pagination.")]
        [switch]$All,
        
        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of notifications to retrieve when using -All.")]
        [ValidateRange(1, 10000)]
        [int]$Limit = 1000
    )
    
    try {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        Write-Verbose "Session found, calling API..."
        
        if ($All) {
            # Use pagination to get all notifications
            $notifications = Get-BlueskyAllNotificationsApi -Session $session -Limit $Limit
        } else {
            # Get single page of recent notifications
            $notifications = Get-BlueskyNotificationApi -Session $session
        }
        
        if ($notifications) {
            # Transform notifications to user-friendly format
            return $notifications | ForEach-Object {
                $notification = $_
                
                # Convert URI to user-friendly URL if possible
                $referenceUrl = $null
                $referenceIdentifier = $null
                if ($notification.reasonSubject) {
                    $referenceUrl = Convert-AtUriToUrl -AtUri $notification.reasonSubject
                    $referenceIdentifier = Get-PostIdentifierFromUri -AtUri $notification.reasonSubject
                }
                
                # Extract useful information from record
                $notificationDate = $null
                if ($notification.record -and $notification.record.createdAt) {
                    $notificationDate = [DateTime]$notification.record.createdAt
                }
                
                # Extract reply-specific information with better data handling
                $replyToUri = $null
                $replyToUrl = $null
                $replyToIdentifier = $null
                $originalPostText = $null
                $rootPostUri = $null
                $parentPostText = $null
                
                if ($notification.reason -eq 'reply' -and $notification.record -and $notification.record.reply) {
                    # Parent post (the post being replied to directly)
                    $replyToUri = $notification.record.reply.parent.uri
                    $replyToUrl = Convert-AtUriToUrl -AtUri $replyToUri
                    $replyToIdentifier = Get-PostIdentifierFromUri -AtUri $replyToUri
                    
                    # Try to get parent post text if embedded
                    if ($notification.record.reply.parent -and $notification.record.reply.parent.record) {
                        $parentPostText = $notification.record.reply.parent.record.text
                    }
                    
                    # Root post (the original post in the thread)
                    if ($notification.record.reply.root) {
                        $rootPostUri = $notification.record.reply.root.uri
                        # Try to get root post text if embedded
                        if ($notification.record.reply.root.record) {
                            $originalPostText = $notification.record.reply.root.record.text
                        }
                    }
                }
                
                # Extract mention-specific information
                $mentionText = $null
                $mentionPositions = $null
                if ($notification.reason -eq 'mention' -and $notification.record) {
                    $mentionText = $notification.record.text
                    # Extract mention positions from facets
                    if ($notification.record.facets) {
                        $mentionPositions = $notification.record.facets | Where-Object { 
                            $_.features -and $_.features.'$type' -eq 'app.bsky.richtext.facet#mention' 
                        } | ForEach-Object {
                            @{
                                Start = $_.index.byteStart
                                End = $_.index.byteEnd
                                Text = $mentionText.Substring($_.index.byteStart, $_.index.byteEnd - $_.index.byteStart)
                                Did = $_.features | Where-Object { $_.'$type' -eq 'app.bsky.richtext.facet#mention' } | Select-Object -First 1 -ExpandProperty did
                            }
                        }
                    }
                }
                
                # For likes and reposts, get subject post information
                $subjectPostText = $null
                $subjectPostAuthor = $null
                if ($notification.reason -in @('like', 'repost', 'quote') -and $notification.reasonSubject) {
                    # Note: The reasonSubject URI points to the post that was liked/reposted
                    # The actual post content isn't always included in the notification
                    # To get the full content, you would need to make a separate API call:
                    # Get-BlueskyPost -PostUri $notification.reasonSubject
                }
                
                # Create clean, user-friendly object with all important data
                [PSCustomObject]@{
                    Type = switch ($notification.reason) {
                        'like' { 'Like' }
                        'repost' { 'Repost' }
                        'follow' { 'Follow' }
                        'mention' { 'Mention' }
                        'reply' { 'Reply' }
                        'quote' { 'Quote' }
                        default { $notification.reason }
                    }
                    AuthorName = if ($notification.author.displayName) { $notification.author.displayName } else { $notification.author.handle }
                    AuthorHandle = "@$($notification.author.handle)"
                    AuthorDid = $notification.author.did
                    
                    # Main reference (the subject of the notification)
                    Reference = $referenceUrl
                    ReferenceUri = $notification.reasonSubject
                    ReferenceIdentifier = $referenceIdentifier
                    
                    # Reply-specific fields (for when someone replies to your posts)
                    ReplyToUri = $replyToUri
                    ReplyToUrl = $replyToUrl
                    ReplyToIdentifier = $replyToIdentifier
                    ParentPostText = $parentPostText  # Text of the post being replied to
                    OriginalPostText = $originalPostText  # Text of the root post in thread
                    RootPostUri = $rootPostUri
                    
                    # The actual notification content (the reply text, mention text, etc.)
                    NotificationUri = $notification.uri
                    NotificationCid = $notification.cid
                    NotificationIdentifier = Get-PostIdentifierFromUri -AtUri $notification.uri
                    
                    # Content of the notification itself
                    Text = if ($notification.record -and $notification.record.text) { $notification.record.text } else { $null }
                    
                    # Mention-specific data
                    MentionPositions = $mentionPositions
                    
                    # Timestamps
                    Date = if ($notificationDate) { $notificationDate } else { [DateTime]$notification.indexedAt }
                    IndexedAt = [DateTime]$notification.indexedAt
                    
                    # Status
                    IsRead = [bool]$notification.isRead
                    
                    # Author details
                    Description = if ($notification.author.description) { 
                        # Truncate long descriptions
                        if ($notification.author.description.Length -gt 100) {
                            $notification.author.description.Substring(0, 100) + "..."
                        } else {
                            $notification.author.description
                        }
                    } else { $null }
                    Avatar = $notification.author.avatar
                    
                    # Labels for content moderation
                    Labels = $notification.labels
                    
                    # Note about missing data
                    _DataNote = if ($notification.reason -in @('like', 'repost') -and -not $subjectPostText) {
                        "Subject post content not included in notification. Use Reference URI to fetch full post details."
                    } elseif ($notification.reason -eq 'reply' -and -not $originalPostText -and -not $parentPostText) {
                        "Parent/root post content not fully embedded. Use ReplyToUri/RootPostUri to fetch complete thread context."
                    } else {
                        $null
                    }
                    
                    # Keep original data for advanced users and API calls
                    _RawData = $notification
                }
            }
        } else {
            Write-Warning 'No notifications found or API call failed.'
            return $null
        }
    } catch {
        Write-Error "Failed to get notifications: $_"
        throw
    }
}
