function Get-BlueskyReply {
    <#
    .SYNOPSIS
        Gets notifications that are replies to your posts.
    .DESCRIPTION
        Retrieves notifications for the current session and returns only those where the type is 'reply'.
        Optionally filters to only those replies you have not responded to.
    .PARAMETER Unresponded
        If specified, only returns replies you have not responded to.
    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Only show replies you have not responded to.")]
        [switch]$Unresponded
    )
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
        return $null
    }
    $myHandle = $session.Username
    $notifications = Get-BlueskyNotificationApi -Session $session
    if (-not $notifications) {
        Write-Warning 'No notifications found or API call failed.'
        return $null
    }
    $replies = $notifications | Where-Object { $_.reason -eq 'reply' }
    if (-not $Unresponded) {
        return $replies
    }

    # Filter for unresponded replies
    $unresponded = @()
    foreach ($reply in $replies) {
        # The reply notification should have a uri or post reference
        $replyUri = $reply.uri
        $rootUri = $null
        if ($reply.PSObject.Properties.Name -contains 'record' -and $reply.record.PSObject.Properties.Name -contains 'reply') {
            # Try to get the root post URI from the reply record
            $rootUri = $reply.record.reply.root.uri
        }
        if (-not $rootUri) {
            # Fallback: skip if we can't determine the root post
            $unresponded += $reply
            continue
        }
        # Fetch the thread for the root post
        $threadEndpoint = '/xrpc/app.bsky.feed.getPostThread'
        $threadParams = @{ uri = $rootUri }
        $thread = Invoke-BlueSkyApiRequest -Session $session -Endpoint $threadEndpoint -Method 'GET' -Query $threadParams
        if ($thread -and $thread.PSObject.Properties.Name -contains 'thread') {
            $allReplies = @()
            function Get-AllReplies($node) {
                if ($node.PSObject.Properties.Name -contains 'replies' -and $node.replies) {
                    foreach ($r in $node.replies) {
                        $allReplies += $r.post
                        Get-AllReplies $r
                    }
                }
            }
            Get-AllReplies $thread.thread
            # Check if any reply is authored by the current user
            $alreadyReplied = $false
            foreach ($r in $allReplies) {
                if ($r.author.handle -eq $myHandle) {
                    $alreadyReplied = $true
                    break
                }
            }
            if (-not $alreadyReplied) {
                $unresponded += $reply
            }
        } else {
            # If thread fetch fails, include the reply (conservative)
            $unresponded += $reply
        }
    }
    return $unresponded
}
