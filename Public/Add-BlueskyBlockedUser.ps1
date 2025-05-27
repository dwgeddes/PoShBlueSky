function Add-BlueskyBlockedUser {
    <#
    .SYNOPSIS
        Blocks a user on BlueSky.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserDid
    )
    
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
        return $null
    }
    
    $endpoint = "/xrpc/app.bsky.graph.block"
    $body = @{ subject = $UserDid }
    $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
    return $result
}
