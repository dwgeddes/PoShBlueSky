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
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Only show replies you have not responded to.")]
        [switch]$Unresponded,

        [Parameter(Mandatory = $false, HelpMessage = "Limit the number of replies returned.")]
        [int]$Limit = 50
    )

    try {
        if (-not $module:BlueskySession) {
            Write-Error "Not connected to Bluesky. Use Connect-BlueskySession first."
            return @()
        }

        # Internal helper function (renamed from Get-AllReplies to avoid plural noun)
        function Get-BlueskyReplyInternal {
            param($Uri, $Limit)

            $headers = @{
                "Authorization" = "Bearer $($module:BlueskySession.AccessJwt)"
            }

            $response = Invoke-RestMethod -Uri $Uri -Headers $headers
            return $response.notifications | Where-Object { $_.reason -eq "reply" } | Select-Object -First $Limit
        }

        $uri = "https://bsky.social/xrpc/app.bsky.notification.listNotifications?limit=$Limit"
        $replies = Get-BlueskyReplyInternal -Uri $uri -Limit $Limit

        if ($Unresponded) {
            # Filter for unresponded replies (simplified logic)
            $replies = $replies | Where-Object { -not $_.isRead }
        }

        return $replies | ForEach-Object {
            [PSCustomObject]@{
                AuthorHandle = $_.author.handle
                AuthorName   = $_.author.displayName
                Text          = $_.record.text
                Date          = [DateTime]$_.indexedAt
                Uri           = $_.uri
                IsRead        = $_.isRead
            }
        }

    } catch {
        Write-Error "Failed to get replies: $($_.Exception.Message)"
        return @()
    }
}
