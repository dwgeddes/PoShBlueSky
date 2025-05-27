function Convert-AtUriToUrl {
    <#
    .SYNOPSIS
        Converts an AT Protocol URI to a user-friendly Bluesky URL.
    .DESCRIPTION
        Transforms AT URIs (like at://did:plc:123/app.bsky.feed.post/abc) into 
        readable Bluesky URLs (like https://bsky.app/profile/user.bsky.social/post/abc).
        Also handles converting DIDs to handles when possible.
    .PARAMETER AtUri
        The AT Protocol URI to convert.
    .PARAMETER Session
        Optional session object to resolve DIDs to handles.
    .EXAMPLE
        PS> Convert-AtUriToUrl -AtUri "at://did:plc:ixen5i426cpidtesanwni5hu/app.bsky.feed.post/3lka6e75c3z2k"
        Returns: "https://bsky.app/profile/did:plc:ixen5i426cpidtesanwni5hu/post/3lka6e75c3z2k"
    .OUTPUTS
        String
        Returns the converted URL or the original URI if conversion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AtUri,
        
        [Parameter(Mandatory = $false)]
        $Session
    )
    
    if (-not $AtUri -or -not $AtUri.StartsWith('at://')) {
        return $AtUri
    }
    
    try {
        # Parse AT URI: at://did:plc:identifier/collection/record
        $uriParts = $AtUri.Substring(5) -split '/', 3  # Remove 'at://' and split
        
        if ($uriParts.Length -lt 3) {
            return $AtUri
        }
        
        $did = $uriParts[0]
        $collection = $uriParts[1]
        $record = $uriParts[2]
        
        # Try to resolve DID to handle if session is available
        # For now, just use the DID directly - handle resolution could be added later
        $identifier = $did
        
        # Convert based on collection type
        switch ($collection) {
            'app.bsky.feed.post' {
                return "https://bsky.app/profile/$identifier/post/$record"
            }
            'app.bsky.feed.like' {
                # For likes, we want to link to the original post, not the like record
                # This would require additional processing to extract the subject
                return "https://bsky.app/profile/$identifier"
            }
            'app.bsky.feed.repost' {
                return "https://bsky.app/profile/$identifier"
            }
            'app.bsky.graph.follow' {
                return "https://bsky.app/profile/$identifier"
            }
            'app.bsky.actor.profile' {
                return "https://bsky.app/profile/$identifier"
            }
            default {
                return "https://bsky.app/profile/$identifier"
            }
        }
    } catch {
        Write-Verbose "Failed to convert AT URI '$AtUri': $_"
        return $AtUri
    }
}

function Get-PostIdentifierFromUri {
    <#
    .SYNOPSIS
        Extracts the post identifier (rkey) from an AT Protocol URI.
    .DESCRIPTION
        Parses an AT URI and returns the record key (rkey) which can be used
        for API lookups and operations.
    .PARAMETER AtUri
        The AT Protocol URI to parse.
    .EXAMPLE
        PS> Get-PostIdentifierFromUri -AtUri "at://did:plc:ixen5i426cpidtesanwni5hu/app.bsky.feed.post/3lka6e75c3z2k"
        Returns: "3lka6e75c3z2k"
    .OUTPUTS
        String
        Returns the post identifier or null if parsing fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AtUri
    )
    
    if (-not $AtUri -or -not $AtUri.StartsWith('at://')) {
        return $null
    }
    
    try {
        # Parse AT URI: at://did:plc:identifier/collection/record
        $uriParts = $AtUri.Substring(5) -split '/', 3  # Remove 'at://' and split
        
        if ($uriParts.Length -ge 3) {
            return $uriParts[2]  # Return the record identifier
        }
        
        return $null
    } catch {
        Write-Verbose "Failed to extract post identifier from URI '$AtUri': $_"
        return $null
    }
}
