function Remove-BlueskyBlockedUser {
    <#
    .SYNOPSIS
        Unblocks a user on Bluesky.
    .DESCRIPTION
        Removes a user from your blocked users list by deleting the block record.
    .PARAMETER BlockUri
        The URI of the block record to remove.
    .EXAMPLE
        PS> Remove-BlueskyBlockedUser -BlockUri "at://did:plc:xyz/app.bsky.graph.block/abc123"
        Unblocks the user associated with the block record.
    .OUTPUTS
        PSCustomObject
        Returns the result of the unblock operation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The URI of the block record to remove.")]
        [ValidateNotNullOrEmpty()]
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
                # Parse the block URI to get components for deletion
                if (-not $BlockUri.StartsWith('at://')) {
                    throw "Invalid block URI format. Expected AT Protocol URI starting with 'at://'"
                }
                
                $uriParts = $BlockUri.Substring(5) -split '/', 3
                if ($uriParts.Length -ne 3) {
                    throw "Invalid block URI format. Expected format: at://did/collection/rkey"
                }
                
                $repo = $uriParts[0]
                $collection = $uriParts[1]
                $rkey = $uriParts[2]
                
                $endpoint = "/xrpc/com.atproto.repo.deleteRecord"
                $body = @{
                    repo = $repo
                    collection = $collection
                    rkey = $rkey
                }
                
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                Write-Host "User unblocked successfully" -ForegroundColor Green
                return [PSCustomObject]@{
                    Success = $true
                    BlockUri = $BlockUri
                    Action = "Unblocked"
                    Timestamp = Get-Date
                    _RawData = $result
                }
            } catch {
                $errorMessage = switch -Regex ($_.Exception.Message) {
                    '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                    '403|Forbidden' { "Access denied. You may not have permission to unblock this user." }
                    '404|Not Found' { "Block record not found or already removed." }
                    'Invalid.*URI' { "Invalid block URI format. Please provide a valid AT Protocol URI." }
                    default { "Failed to unblock user: $($_.Exception.Message)" }
                }
                Write-Error $errorMessage
                return $null
            }
        }
    }
}
