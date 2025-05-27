function Get-BlueskyFollower {
    <#
    .SYNOPSIS
        Retrieves the list of users following the authenticated Bluesky user.
    .DESCRIPTION
        Calls the Bluesky API to get followers for the specified session or the current session if none is provided.
        Returns a list of follower objects with their profile information.
    .PARAMETER Session
        The session object to use for authentication. If not provided, the current session is used.
    .PARAMETER Actor
        The actor (username, handle, or DID) to get followers for. If not specified, uses the current session's user.
    .PARAMETER Limit
        The maximum number of followers to retrieve (default: 50, max: 100).
    .PARAMETER Cursor
        Pagination cursor for retrieving additional results.
    .EXAMPLE
        PS> Get-BlueskyFollower
        Returns the followers for the current session.
    .EXAMPLE
        PS> Get-BlueskyFollower -Actor 'username.bsky.social'
        Returns the followers for the specified user.
    .EXAMPLE
        PS> Get-BlueskyFollower -Limit 25
        Returns up to 25 followers for the current session.
    .OUTPUTS
        PSCustomObject[]
        Returns an array of follower objects containing profile information.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "The session object to use for authentication.")]
        [ValidateNotNull()]
        $Session,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The actor (username, handle, or DID) to get followers for.")]
        [ValidateNotNullOrEmpty()]
        [string]$Actor,
        
        [Parameter(Mandatory = $false, HelpMessage = "The maximum number of followers to retrieve.")]
        [ValidateRange(1, 100)]
        [int]$Limit = 50,
        
        [Parameter(Mandatory = $false, HelpMessage = "Pagination cursor for retrieving additional results.")]
        [string]$Cursor
    )
    
    process {
        if (-not $Session) {
            $Session = Get-BlueskySession -Raw
            if (-not $Session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return @()
            }
        }
        
        try {
            if (-not $Actor) {
                $Actor = Resolve-BlueskyActor -Session $Session
                if (-not $Actor) {
                    throw 'Session does not contain a valid actor identifier (Username, Handle, or Did). Cannot retrieve followers.'
                }
            }
            
            $Endpoint = '/xrpc/app.bsky.graph.getFollowers'
            $Params = @{ 
                actor = $Actor 
                limit = $Limit
            }
            if ($Cursor) {
                $Params.cursor = $Cursor
            }
            
            $Response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $Endpoint -Method 'GET' -Query $Params -ErrorAction Stop
            
            if ($Response -and $Response.PSObject.Properties.Name -contains 'followers') {
                # Transform followers to user-friendly format
                return $Response.followers | ForEach-Object {
                    $follower = $_
                    
                    [PSCustomObject]@{
                        DisplayName = if ($follower.displayName) { $follower.displayName } else { $follower.handle }
                        Handle = "@$($follower.handle)"
                        ProfileUrl = "https://bsky.app/profile/$($follower.handle)"
                        Description = if ($follower.description) {
                            # Truncate long descriptions
                            if ($follower.description.Length -gt 100) {
                                $follower.description.Substring(0, 100) + "..."
                            } else {
                                $follower.description
                            }
                        } else { $null }
                        Avatar = $follower.avatar
                        CreatedAt = if ($follower.createdAt) { [DateTime]$follower.createdAt } else { $null }
                        IsFollowing = if ($follower.viewer -and $follower.viewer.following) { $true } else { $false }
                        # Keep original data for advanced users
                        _RawData = $follower
                    }
                }
            } else {
                Write-Warning 'No followers found or API call failed.'
                return @()
            }
        } catch {
            Write-Error "Failed to retrieve followers: $_"
            return @()
        }
    }
}