function Remove-BlueskyLike {
    <#
    .SYNOPSIS
        Removes a like from a post on Bluesky.
    .OUTPUTS
        PSCustomObject
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
