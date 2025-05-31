function Disconnect-BlueskySession {
    <#
    .SYNOPSIS
        Disconnects and clears the current Bluesky session.
    .DESCRIPTION
        Safely clears the active session and removes stored credentials from memory.
        This is recommended when finished using the module to protect your authentication tokens.
    .EXAMPLE
        PS> Disconnect-BlueskySession
        Clears the current session and credentials.
    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        if ($module:BlueskySession) {
            $previousHandle = $module:BlueskySession.Handle
            $module:BlueskySession = $null
            Write-Information "Disconnected from Bluesky session for $previousHandle" -InformationAction Continue
        } else {
            Write-Warning "No active Bluesky session found"
        }
        
        return [PSCustomObject]@{
            Status = "Disconnected"
            DisconnectedAt = Get-Date
        }
        
    } catch {
        Write-Error "Error during disconnect: $($_.Exception.Message)"
        return $null
    }
}
