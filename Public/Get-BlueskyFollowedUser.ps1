function Get-BlueskyFollowedUser {
    <#
    .SYNOPSIS
        Retrieves the list of users the authenticated Bluesky user is following.
    .DESCRIPTION
        Calls the Bluesky API to get the list of users being followed by the specified session or the current session.
        Returns a list of followed user objects with their profile information.
    .PARAMETER Session
        The session object to use for authentication. If not provided, the current session is used.
    .PARAMETER Actor
        The actor (username, handle, or DID) to get following list for. If not specified, uses the current session's user.
    .PARAMETER Limit
        The maximum number of followed users to retrieve (default: 50, max: 100).
    .PARAMETER Cursor
        Pagination cursor for retrieving additional results.
    .EXAMPLE
        PS> Get-BlueskyFollowedUser
        Returns the users the current session is following.
    .EXAMPLE
        PS> Get-BlueskyFollowedUser -Actor 'username.bsky.social'
        Returns the users that the specified user is following.
    .EXAMPLE
        PS> Get-BlueskyFollowedUser -Limit 25
        Returns up to 25 followed users for the current session.
    .OUTPUTS
        PSCustomObject[]
        Returns an array of followed user objects containing profile information.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The session object to use for authentication.")]
        [ValidateNotNull()]
        $Session,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The actor (username, handle, or DID) to get following list for.")]
        [ValidateNotNullOrEmpty()]
        [string]$Actor,
        
        [Parameter(Mandatory = $false, HelpMessage = "The maximum number of followed users to retrieve.")]
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
                    throw 'Session does not contain a valid actor identifier (Username, Handle, or Did). Cannot retrieve following list.'
                }
            }
            
            $Endpoint = '/xrpc/app.bsky.graph.getFollows'
            $Params = @{ 
                actor = $Actor 
                limit = $Limit
            }
            if ($Cursor) {
                $Params.cursor = $Cursor
            }
            
            $Response = Invoke-BlueSkyApiRequest -Session $Session -Endpoint $Endpoint -Method 'GET' -Query $Params -ErrorAction Stop
            
            if ($Response -and $Response.PSObject.Properties.Name -contains 'follows') {
                # Transform followed users to user-friendly format
                return $Response.follows | ForEach-Object {
                    $followedUser = $_
                    
                    [PSCustomObject]@{
                        DisplayName = if ($followedUser.displayName) { $followedUser.displayName } else { $followedUser.handle }
                        Handle = "@$($followedUser.handle)"
                        ProfileUrl = "https://bsky.app/profile/$($followedUser.handle)"
                        Description = if ($followedUser.description) {
                            # Truncate long descriptions
                            if ($followedUser.description.Length -gt 100) {
                                $followedUser.description.Substring(0, 100) + "..."
                            } else {
                                $followedUser.description
                            }
                        } else { $null }
                        Avatar = $followedUser.avatar
                        CreatedAt = if ($followedUser.createdAt) { [DateTime]$followedUser.createdAt } else { $null }
                        IsFollowingMe = if ($followedUser.viewer -and $followedUser.viewer.followedBy) { $true } else { $false }
                        # Keep original data for advanced users
                        _RawData = $followedUser
                    }
                }
            } else {
                Write-Warning 'No followed users found or API call failed.'
                return @()
            }
        } catch {
            Write-Error "Failed to retrieve followed users: $_"
            return @()
        }
    }
}
