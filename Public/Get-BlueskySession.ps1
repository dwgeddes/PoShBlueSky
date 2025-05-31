function Get-BlueskySession {
    <#
    .SYNOPSIS
        Retrieves the current Bluesky session information.
    .DESCRIPTION
        Returns the current session details with masked authentication tokens for security.
        Use -Raw parameter to get unmasked tokens for internal API calls.
    .PARAMETER Raw
        Returns the session with unmasked tokens (for internal use).
    .EXAMPLE
        PS> Get-BlueskySession
        Returns session info with masked tokens for display.
    .EXAMPLE
        PS> Get-BlueskySession -Raw
        Returns session with actual tokens for API calls.
    .OUTPUTS
        PSCustomObject
        Returns the session object or null if no session exists.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Return unmasked session for internal use.")]
        [switch]$Raw
    )
    
    try {
        if (-not $module:BlueskySession) {
            Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
            return $null
        }
        
        if ($Raw) {
            return $module:BlueskySession
        }
        
        # Return session info with masked tokens for security
        return [PSCustomObject]@{
            Handle = $module:BlueskySession.Handle
            Did = $module:BlueskySession.Did
            Status = "Connected"
            CreatedAt = $module:BlueskySession.CreatedAt
            AccessToken = "***MASKED***"
            RefreshToken = "***MASKED***"
        }
        
    } catch {
        Write-Error "Error retrieving session: $($_.Exception.Message)"
        return $null
    }
}
