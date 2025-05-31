function Add-BlueskyMutedUser {
    <#
    .SYNOPSIS
        Mutes a user on Bluesky.
    .DESCRIPTION
        Adds a user to your muted users list, hiding their content from your timeline.
    .PARAMETER UserDid
        The DID (Decentralized Identifier) of the user to mute.
    .EXAMPLE
        PS> Add-BlueskyMutedUser -UserDid "did:plc:example123"
        Mutes the specified user.
    .OUTPUTS
        PSCustomObject
        Returns the result of the mute operation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The DID of the user to mute.")]
        [ValidateNotNullOrEmpty()]
        [string]$UserDid
    )
    
    process {
        $session = Get-BlueskySession -Raw
        if (-not $session) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        if ($PSCmdlet.ShouldProcess($UserDid, "Mute user")) {
            try {
                $endpoint = "/xrpc/app.bsky.graph.muteActor"
                $body = @{ actor = $UserDid }
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                if ($result) {
                    Write-Information "User muted successfully" -InformationAction Continue
                    return [PSCustomObject]@{
                        Success = $true
                        UserDid = $UserDid
                        Action = "Muted"
                        Timestamp = Get-Date
                        _RawData = $result
                    }
                } else {
                    throw "Mute operation failed: No response from API"
                }
            } catch {
                $errorMessage = switch -Regex ($_.Exception.Message) {
                    '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                    '403|Forbidden' { "Access denied. You may not have permission to mute this user." }
                    '404|Not Found' { "User not found or already muted." }
                    default { "Failed to mute user: $($_.Exception.Message)" }
                }
                Write-Error $errorMessage
                return $null
            }
        }
    }
}
