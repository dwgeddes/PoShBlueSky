function Resolve-BlueskyActor {
    <#
    .SYNOPSIS
        Resolves the actor identifier (Username, Handle, or Did) from a session object.
    .DESCRIPTION
        Returns the first available actor identifier from the session object, prioritizing Username, then Handle, then Did.
    .PARAMETER Session
        The session object containing actor identifiers.
    .EXAMPLE
        PS> Resolve-BlueskyActor -Session $session
        Returns the Username, Handle, or Did from the session.
    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Session
    )
    if ($null -eq $Session) {
        Write-Error 'Session object is null.'
        return $null
    }
    if ($Session.PSObject.Properties.Name -contains 'Username' -and $Session.Username) {
        return $Session.Username
    }
    if ($Session.PSObject.Properties.Name -contains 'Handle' -and $Session.Handle) {
        return $Session.Handle
    }
    if ($Session.PSObject.Properties.Name -contains 'Did' -and $Session.Did) {
        return $Session.Did
    }
    Write-Error 'No valid actor identifier (Username, Handle, or Did) found in session.'
    return $null
}
