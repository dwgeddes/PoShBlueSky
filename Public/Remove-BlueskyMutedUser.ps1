function Remove-BlueskyMutedUser {
    <#
    .SYNOPSIS
        Unmutes a user on Bluesky.
    .DESCRIPTION
        Removes a user from your muted users list, allowing their content to appear in your timeline again.
    .PARAMETER UserDid
        The DID (Decentralized Identifier) of the user to unmute.
    .EXAMPLE
        PS> Remove-BlueskyMutedUser -UserDid "did:plc:example123"
        Unmutes the specified user.
    .OUTPUTS
        PSCustomObject
        Returns the result of the unmute operation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The DID of the user to unmute.")]
        [ValidateNotNullOrEmpty()]
        [string]$UserDid
    )
    
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        if ($PSCmdlet.ShouldProcess($UserDid, "Unmute user")) {
            try {
                $endpoint = "/xrpc/app.bsky.graph.unmuteActor"
                $body = @{ actor = $UserDid }
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                if ($result) {
                    Write-Information "User unmuted successfully" -InformationAction Continue
                    return [PSCustomObject]@{
                        Success = $true
                        UserDid = $UserDid
                        Action = "Unmuted"
                        Timestamp = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Unmute operation failed: No response from API"
                }
            } catch {
                $errorMessage = switch -Regex ($_.Exception.Message) {
                    '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                    '403|Forbidden' { "Access denied. You may not have permission to unmute this user." }
                    '404|Not Found' { "User not found or not currently muted." }
                    default { "Failed to unmute user: $($_.Exception.Message)" }
                }
                Write-Error $errorMessage
                return $null
            }
        }
    }
}
