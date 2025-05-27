function Get-BlueskySession {
    <#
    .SYNOPSIS
        Retrieves information about the current Bluesky session.
    .DESCRIPTION
        Returns the session object for the current Bluesky connection. By default, 
        sensitive tokens are masked for security. Use -Raw to get the complete 
        session object for internal API operations.
    .PARAMETER Raw
        If specified, returns the full session object including authentication 
        tokens. Required for internal API calls.
    .EXAMPLE
        PS> Get-BlueskySession
        Returns session information with masked tokens for display purposes.
    .EXAMPLE
        PS> Get-BlueskySession -Raw
        Returns the complete session object including tokens for API calls.
    .OUTPUTS
        PSCustomObject
        Returns the session object or null if no active session exists.
    .NOTES
        Masked session objects are safe for display and logging.
        Raw session objects contain sensitive authentication data.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Return the complete session object including authentication tokens.")]
        [switch]$Raw
    )
    
    if (-not $global:BlueskySession) {
        # Write-Warning 'No active Bluesky session found.'
        return $null
    }
    
    if ($Raw) {
        return $global:BlueskySession
    }
    
    # Create masked version for safe display
    $maskedSession = [PSCustomObject]@{
        Username = $global:BlueskySession.Username
        Handle = $global:BlueskySession.Handle
        DistributedIdentifier = $global:BlueskySession.DistributedIdentifier
        AccessToken = if ($global:BlueskySession.AccessToken) { 
            $global:BlueskySession.AccessToken.Substring(0, [Math]::Min(10, $global:BlueskySession.AccessToken.Length)) + '...' 
        } else { $null }
        RefreshToken = if ($global:BlueskySession.RefreshToken) { 
            $global:BlueskySession.RefreshToken.Substring(0, [Math]::Min(10, $global:BlueskySession.RefreshToken.Length)) + '...' 
        } else { $null }
        ExpiresAt = $global:BlueskySession.ExpiresAt
        IsExpired = if ($global:BlueskySession.ExpiresAt) { 
            $global:BlueskySession.ExpiresAt -lt (Get-Date) 
        } else { $true }
        CreatedAt = $global:BlueskySession.CreatedAt
        Status = if ($global:BlueskySession.ExpiresAt -and $global:BlueskySession.ExpiresAt -gt (Get-Date)) { 
            'Active' 
        } else { 
            'Expired' 
        }
    }
    
    return $maskedSession
}
