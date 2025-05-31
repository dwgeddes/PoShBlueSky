function Get-BlueskySessionInternal {
    <#
    .SYNOPSIS
        Retrieves the current BlueSky session from module scope.
    .DESCRIPTION
        Internal helper to get the active session. Does not create a new session.
        Session creation should be handled by Connect-BlueskySession.
    #>
    param()
    
    if ($module:BlueskySession -and $module:BlueskySession.AccessJwt -and $module:BlueskySession.Expires -gt (Get-Date)) {
        return $module:BlueskySession
    } elseif ($module:BlueskySession) {
        Write-Verbose "Existing module session is invalid or expired."
    } else {
        Write-Verbose "No active module session found by Get-BlueskySessionInternal."
    }
    
    # This function will no longer attempt to create a session from environment variables.
    # Connect-BlueskySession is responsible for session creation.
    return $null
}
