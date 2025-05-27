function Disconnect-BlueskySession {
    <#
    .SYNOPSIS
        Disconnects and clears the current Bluesky session.
    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param()
    Remove-Variable -Name BlueskySession -Scope Global -ErrorAction SilentlyContinue
}
