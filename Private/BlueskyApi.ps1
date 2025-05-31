function Get-BlueskyProfileApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to retrieve a user's profile.
    #>
    param(
        [Parameter(Mandatory=$false)]
        $Session,
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )
    $endpoint = "/xrpc/app.bsky.actor.getProfile"
    try {
        $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'GET' -Query $Params
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'profile') {
                return $response.profile
            }
            return $response
        }
    } catch {
        Write-Error "Failed to get profile: $_"
    }
    return $null
}

function Get-BlueskyTimelineApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to retrieve the user's timeline.
    #>
    param(
        [Parameter(Mandatory=$false)]
        $Session,
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )
    $endpoint = "/xrpc/app.bsky.feed.getTimeline"
    try {
        $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'GET' -Query $Params
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'feed') {
                return $response.feed
            }
            return $response
        }
    } catch {
        Write-Error "Failed to get timeline: $_"
    }
    return $null
}

function New-BlueskyPostApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to create a new post.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        $Session,
        [Parameter(Mandatory=$true)]
        $Body
    )
    
    if ($PSCmdlet.ShouldProcess("Bluesky", "Create new post")) {
        $endpoint = "/xrpc/com.atproto.repo.createRecord"
        try {
            $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'POST' -Body $Body
            if ($null -eq $response) { return $null }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                return $response
            }
        } catch {
            Write-Error "Failed to create post: $_"
            throw
        }
    }
    return $null
}

function Get-BlueskyNotificationApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to retrieve notifications.
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Session
    )
    $endpoint = "/xrpc/app.bsky.notification.listNotifications"
    try {
        $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'GET'
        if ($null -eq $response) { 
            Write-Verbose "API returned null response"
            return $null 
        }
        
        # Additional safety check for the response type
        if ($response -and $response.GetType() -and ($response -is [string])) { 
            $response = $response | ConvertFrom-Json 
        }
        
        if ($response -and $response.PSObject -and $response.PSObject.Properties.Name -contains 'notifications') {
            return $response.notifications
        } elseif ($response) {
            return $response
        }
    } catch {
        Write-Error "Failed to get notifications: $_"
        throw
    }
    return $null
}

function Search-BlueskyUserApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to search for a user by handle or DID.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query
    )
    $endpoint = "/xrpc/app.bsky.actor.searchActors"
    $queryParams = @{ q = $Query }
    try {
        $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'GET' -Query $queryParams
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'users') {
                return $response.users
            }
            return $response
        }
    } catch {
        Write-Error "Failed to search users: $_"
    }
    return $null
}

function Get-BlueskyFollowedUserApi {
    <#
    .SYNOPSIS
        Gets a list of users you are following on BlueSky.
    #>
    param()
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Error 'No active session found'
        return $null
    }
    
    $actor = $session.Username
    if (-not $actor) { $actor = $session.Handle }
    if (-not $actor) { $actor = $session.Did }
    if (-not $actor) {
        Write-Error 'Session does not contain a valid actor identifier (Username, Handle, or Did). Cannot call API.'
        return $null
    }
    $endpoint = "/xrpc/app.bsky.graph.getFollows"
    $params = @{ actor = $actor }
    try {
        $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'GET' -Query $params
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'follows') {
                return $response.follows
            }
            return $response
        }
    } catch {
        Write-Error "Failed to get followed users: $_"
    }
    return $null
}

function Set-BlueskyFollowedUserApi {
    <#
    .SYNOPSIS
        Follows a user on BlueSky.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserDid
    )
    
    if ($PSCmdlet.ShouldProcess($UserDid, "Follow user")) {
        $endpoint = "/xrpc/app.bsky.graph.follow"
        $body = @{ subject = $UserDid }
        try {
            $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'POST' -Body $body
            if ($null -eq $response) { return $null }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                return $response
            }
        } catch {
            Write-Error "Failed to follow user: $_"
        }
    }
    return $null
}

function Remove-BlueskyFollowedUserApi {
    <#
    .SYNOPSIS
        Unfollows a user on BlueSky.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FollowUri
    )
    
    if ($PSCmdlet.ShouldProcess($FollowUri, "Unfollow user")) {
        $endpoint = "/xrpc/com.atproto.repo.deleteRecord"
        $body = @{ uri = $FollowUri }
        try {
            $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'POST' -Body $body
            if ($null -eq $response) { return $null }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                return $response
            }
        } catch {
            Write-Error "Failed to unfollow user: $_"
        }
    }
    return $null
}

function Add-BlueskyLikeApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to like a post.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PostUri
    )
    
    if ($PSCmdlet.ShouldProcess($PostUri, "Like post")) {
        $endpoint = "/xrpc/app.bsky.feed.like"
        $body = @{ subject = @{ uri = $PostUri } }
        try {
            $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'POST' -Body $body
            if ($null -eq $response) { return $null }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                return $response
            }
        } catch {
            Write-Error "Failed to like post: $_"
        }
    }
    return $null
}

function Remove-BlueskyLikeApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to remove a like from a post.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LikeUri
    )
    
    if ($PSCmdlet.ShouldProcess($LikeUri, "Unlike post")) {
        $endpoint = "/xrpc/com.atproto.repo.deleteRecord"
        $body = @{ uri = $LikeUri }
        try {
            $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'POST' -Body $body
            if ($null -eq $response) { return $null }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                return $response
            }
        } catch {
            Write-Error "Failed to remove like: $_"
        }
    }
    return $null
}

function Remove-BlueskyPostApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to delete a post.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        $Session,
        [Parameter(Mandatory=$true)]
        [string]$PostUri
    )
    
    if ($PSCmdlet.ShouldProcess($PostUri, "Delete post")) {
        try {
            # Validate the PostUri format
            if (-not $PostUri.StartsWith('at://')) {
                throw "Invalid post URI format. Expected AT Protocol URI starting with 'at://'"
            }
            
            # Parse the AT URI to get the components
            $uriParts = $PostUri.Substring(5) -split '/', 3  # Remove 'at://' and split
            if ($uriParts.Length -ne 3) {
                throw "Invalid post URI format. Expected format: at://did/collection/rkey"
            }
            
            $repo = $uriParts[0]  # The DID
            $collection = $uriParts[1]  # Should be 'app.bsky.feed.post'
            $rkey = $uriParts[2]  # The record key
            
            if ($collection -ne 'app.bsky.feed.post') {
                throw "Invalid collection. Expected 'app.bsky.feed.post', got '$collection'"
            }
            
            # Use the deleteRecord endpoint
            $endpoint = "/xrpc/com.atproto.repo.deleteRecord"
            $body = @{
                repo = $repo
                collection = $collection
                rkey = $rkey
            }
            
            Write-Verbose "Deleting record: repo=$repo, collection=$collection, rkey=$rkey"
            
            $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'POST' -Body $body
            
            if ($response) {
                return $response
            } else {
                # For deleteRecord, a successful response might be empty
                return @{ success = $true }
            }
        } catch {
            Write-Error "Failed to delete post: $_"
            throw
        }
    }
}

function Get-BlueskyAllNotificationsApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to retrieve all notifications (with pagination).
    #>
    param(
        [Parameter(Mandatory=$false)]
        $Session,
        [int]$Limit = 1000
    )
    $endpoint = "/xrpc/app.bsky.notification.listNotifications"
    $allNotifications = @()
    $cursor = $null
    do {
        $query = @{ limit = 100 }
        if ($cursor) { $query.cursor = $cursor }
        try {
            $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'GET' -Query $query
            if ($null -eq $response) {
                break
            }
            if ($response -is [string]) { $response = $response | ConvertFrom-Json }
            if ($response) {
                $obj = $response
                if ($obj.PSObject.Properties.Name -contains 'notifications') {
                    $allNotifications += $obj.notifications
                }
                $cursor = $obj.cursor
            } else {
                $cursor = $null
            }
        } catch {
            Write-Error "Failed to retrieve notifications: $_"
            break
        }
    } while ($cursor -and ($allNotifications.Count -lt $Limit))
    return $allNotifications
}

function Search-BlueskyPostsApi {
    <#
    .SYNOPSIS
        Calls the BlueSky API to search for posts.
    #>
    param(
        [Parameter(Mandatory=$false)]
        $Session,
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )
    $endpoint = "/xrpc/app.bsky.feed.searchPosts"
    try {
        $response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $endpoint -Method 'GET' -Query $Params
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'posts') {
                return $response.posts
            }
            return $response
        }
    } catch {
        Write-Error "Failed to search posts: $_"
    }
    return $null
}

function Get-BlueskyFollowersApi {
    <#
    .SYNOPSIS
        Gets a list of users following the specified actor on BlueSky.
    #>
    param(
        [string]$Actor
    )
    $endpoint = "/xrpc/app.bsky.graph.getFollowers"
    $params = @{ actor = $Actor }
    try {
        $response = Invoke-BlueSkyApiRequest -Endpoint $endpoint -Method 'GET' -Query $params
        if ($null -eq $response) { return $null }
        if ($response -is [string]) { $response = $response | ConvertFrom-Json }
        if ($response) {
            if ($response.PSObject.Properties.Name -contains 'followers') {
                return $response.followers
            }
            return $response
        }
    } catch {
        Write-Error "Failed to get followers: $_"
    }
    return $null
}
