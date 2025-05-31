function Add-BlueskyBlockedUser {
    <#
    .SYNOPSIS
        Blocks a user on Bluesky.
    .DESCRIPTION
        Adds a user to your blocked users list, preventing them from seeing your content 
        and hiding their content from your timeline.
    .PARAMETER UserDid
        The DID (Decentralized Identifier) of the user to block.
    .EXAMPLE
        PS> Add-BlueskyBlockedUser -UserDid "did:plc:example123"
        Blocks the specified user.
    .OUTPUTS
        PSCustomObject
        Returns the result of the block operation including the block URI.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The DID of the user to block.")]
        [ValidateNotNullOrEmpty()]
        [string]$UserDid
    )
    
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        if ($PSCmdlet.ShouldProcess($UserDid, "Block user")) {
            try {
                $endpoint = "/xrpc/com.atproto.repo.createRecord"
                $body = @{
                    repo = $session.Username
                    collection = 'app.bsky.graph.block'
                    record = @{
                        '$type' = 'app.bsky.graph.block'
                        subject = $UserDid
                        createdAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    }
                }
                
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                if ($result) {
                    Write-Information "User blocked successfully" -InformationAction Continue
                    return [PSCustomObject]@{
                        Success = $true
                        UserDid = $UserDid
                        BlockUri = $result.uri
                        Action = "Blocked"
                        Timestamp = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Block operation failed: No response from API"
                }
            } catch {
                $errorMessage = switch -Regex ($_.Exception.Message) {
                    '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                    '403|Forbidden' { "Access denied. You may not have permission to block this user." }
                    '404|Not Found' { "User not found." }
                    default { "Failed to block user: $($_.Exception.Message)" }
                }
                Write-Error $errorMessage
                return $null
            }
        }
    }
}
