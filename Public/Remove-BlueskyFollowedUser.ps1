function Remove-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Unfollows a user on BlueSky.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="The URI of the follow record to remove.")]
        [ValidateNotNullOrEmpty()]
        [string]$FollowUri
    )
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        $result = Remove-BlueskyFollowedUserApi -Session $session -FollowUri $FollowUri
        return $result
    }
}
