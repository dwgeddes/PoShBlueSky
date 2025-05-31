function Remove-BlueskyBlockedUser {
    <#
    .SYNOPSIS
        Unblocks a user on Bluesky.
    .DESCRIPTION
        Removes a user from your blocked users list by deleting the block record.
    .PARAMETER BlockUri
        The URI of the block record to remove.
    .EXAMPLE
        PS> Remove-BlueskyBlockedUser -BlockUri "at://did:plc:example/app.bsky.graph.block/3k2l4j5h6g7"
        Unblocks the user associated with the block record.
    .OUTPUTS
        PSCustomObject
        Returns the result of the unblock operation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName,
                   HelpMessage = "The URI of the block record to remove.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^at://')]
        [string]$BlockUri
    )
    
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        if ($PSCmdlet.ShouldProcess($BlockUri, "Unblock user")) {
            try {
                # Parse the BlockUri to get the components needed for deleteRecord
                $uriParts = $BlockUri.Substring(5) -split '/', 3  # Remove 'at://' and split
                if ($uriParts.Length -ne 3 -or $uriParts[1] -ne 'app.bsky.graph.block') {
                    throw "Invalid block URI format. Expected format: at://did/app.bsky.graph.block/rkey"
                }
                
                $endpoint = "/xrpc/com.atproto.repo.deleteRecord"
                $body = @{
                    repo = $uriParts[0]  # The DID
                    collection = $uriParts[1]  # app.bsky.graph.block
                    rkey = $uriParts[2]  # The record key
                }
                
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                Write-Information "User unblocked successfully" -InformationAction Continue
                return [PSCustomObject]@{
                    Success = $true
                    UnblockedUri = $BlockUri
                    Action = "Unblocked"
                    Timestamp = Get-Date
                    _RawData = $result
                }
            } catch {
                $errorMessage = switch -Regex ($_.Exception.Message) {
                    '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                    '403|Forbidden' { "Access denied. You may not have permission to unblock this user." }
                    '404|Not Found' { "Block record not found or user not currently blocked." }
                    default { "Failed to unblock user: $($_.Exception.Message)" }
                }
                Write-Error $errorMessage
                return $null
            }
        }
    }
}
