function Update-BlueskyProfile {
    <#
    .SYNOPSIS
        Updates your Bluesky profile information.
    .DESCRIPTION
        Updates various aspects of your Bluesky profile including display name, 
        description, and avatar image.
    .PARAMETER DisplayName
        The display name to set for your profile.
    .PARAMETER Description
        The bio/description text for your profile.
    .PARAMETER AvatarPath
        Path to an image file to use as your avatar.
    .PARAMETER AvatarBase64
        Base64-encoded image data to use as your avatar.
    .EXAMPLE
        PS> Update-BlueskyProfile -DisplayName "PowerShell Expert" -Description "Automating the world! 🚀"
        Updates display name and description.
    .EXAMPLE
        PS> Update-BlueskyProfile -AvatarPath "C:\Pictures\avatar.jpg"
        Updates profile avatar from a local image file.
    .OUTPUTS
        PSCustomObject
        Returns the updated profile information.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'NoAvatar')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'NoAvatar',
                   HelpMessage = "Display name for the profile.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarPath',
                   HelpMessage = "Display name for the profile.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarBase64',
                   HelpMessage = "Display name for the profile.")]
        [string]$DisplayName,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'NoAvatar',
                   HelpMessage = "Bio/description for the profile.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarPath',
                   HelpMessage = "Bio/description for the profile.")]
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarBase64',
                   HelpMessage = "Bio/description for the profile.")]
        [string]$Description,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarPath',
                   HelpMessage = "Path to avatar image file.")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$AvatarPath,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'AvatarBase64',
                   HelpMessage = "Base64-encoded avatar image data.")]
        [ValidateNotNullOrEmpty()]
        [string]$AvatarBase64
    )
    
    # Validate that at least one parameter is provided
    if (-not $PSBoundParameters.Count -or 
        (-not $DisplayName -and -not $Description -and -not $AvatarPath -and -not $AvatarBase64)) {
        Write-Warning "At least one property must be specified to update (DisplayName, Description, AvatarPath, or AvatarBase64)."
        return $null
    }
    
    $session = Get-BlueskySession -Raw
    if (-not $session) {
        Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
        return $null
    }
    
    if ($PSCmdlet.ShouldProcess("Profile", "Update Bluesky profile")) {
        try {
            # Get current profile first
            $currentProfile = Get-BlueskyProfileApi -Session $session -Params @{ actor = $session.Username }
            if (-not $currentProfile) {
                throw "Failed to retrieve current profile information"
            }
            
            # Prepare the update record
            $record = @{
                '$type' = 'app.bsky.actor.profile'
                displayName = if ($DisplayName) { $DisplayName } else { $currentProfile.displayName }
                description = if ($Description) { $Description } else { $currentProfile.description }
            }
            
            # Handle avatar upload if provided
            if ($AvatarPath -or $AvatarBase64) {
                $avatarBlob = if ($AvatarPath) {
                    Upload-BlueSkyImageApi -Session $session -Path $AvatarPath
                } else {
                    Upload-BlueSkyImageApi -Session $session -Base64 $AvatarBase64
                }
                
                if (-not $avatarBlob) {
                    throw "Failed to upload avatar image"
                }
                
                $record.avatar = $avatarBlob.blob
            } elseif ($currentProfile.avatar) {
                $record.avatar = $currentProfile.avatar
            }
            
            # Update the profile
            $endpoint = "/xrpc/com.atproto.repo.putRecord"
            $body = @{
                repo = $session.Username
                collection = 'app.bsky.actor.profile'
                rkey = 'self'
                record = $record
            }
            
            $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
            
            if ($result) {
                Write-Host "Profile updated successfully" -ForegroundColor Green
                return [PSCustomObject]@{
                    Success = $true
                    DisplayName = $record.displayName
                    Description = $record.description
                    Avatar = if ($record.avatar) { "Updated" } else { "Unchanged" }
                    UpdatedAt = Get-Date
                    _RawData = $result
                }
            } else {
                throw "Profile update failed: No response from API"
            }
        } catch {
            $errorMessage = switch -Regex ($_.Exception.Message) {
                '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                '403|Forbidden' { "Access denied. You may not have permission to update this profile." }
                'Failed to upload' { "Avatar upload failed. Please check the image file and try again." }
                default { "Failed to update profile: $($_.Exception.Message)" }
            }
            Write-Error $errorMessage
            return $null
        }
    }
}
