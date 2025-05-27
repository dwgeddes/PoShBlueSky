function Add-BlueskyLike {
    <#
    .SYNOPSIS
        Likes a post on BlueSky.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="The URI of the post to like.")]
        [ValidateNotNullOrEmpty()]
        [string]$PostUri
    )
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        $result = Add-BlueskyLikeApi -Session $session -PostUri $PostUri
        return $result
    }
}

function Remove-BlueskyLike {
    <#
    .SYNOPSIS
        Removes a like from a post on Bluesky.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="The URI of the like record to remove.")]
        [ValidateNotNullOrEmpty()]
        [string]$LikeUri
    )
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        $result = Remove-BlueskyLikeApi -Session $session -LikeUri $LikeUri
        return $result
    }
}
