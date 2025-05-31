function Update-BlueskyProfile {
    <#
    .SYNOPSIS
        Updates the profile information for the authenticated Bluesky user.
    .DESCRIPTION
        Updates profile information including display name, description, and avatar.
        At least one parameter must be provided to update the profile.
    .PARAMETER DisplayName
        The new display name to set for the profile.
    .PARAMETER Description
        The new description/bio to set for the profile.
    .PARAMETER AvatarPath
        Path to a local image file to use as the avatar.
    .PARAMETER AvatarBase64
        Base64-encoded image data to use as the avatar.
    .EXAMPLE
        PS> Update-BlueskyProfile -DisplayName "New Display Name" -Description "Updated bio"
        Updates the display name and description.
    .EXAMPLE
        PS> Update-BlueskyProfile -AvatarPath "C:\Pictures\avatar.jpg"
        Updates only the avatar image.
    .OUTPUTS
        PSCustomObject
        Returns the result of the profile update operation.
    #>
    [CmdletBinding(DefaultParameterSetName = 'TextOnly', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The new display name for the profile.")]
        [ValidateLength(1, 64)]
        [string]$DisplayName,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The new description/bio for the profile.")]
        [ValidateLength(0, 256)]
        [string]$Description,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'WithAvatarPath',
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "Path to a local image file for the avatar.")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$AvatarPath,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'WithAvatarBase64',
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "Base64-encoded image data for the avatar.")]
        [ValidateNotNullOrEmpty()]
        [string]$AvatarBase64
    )
    
    # Add process block for pipeline support
    process {
        try {
            # Validate that at least one parameter is provided
            if (-not $DisplayName -and -not $Description -and -not $AvatarPath -and -not $AvatarBase64) {
                Write-Warning "At least one parameter (DisplayName, Description, AvatarPath, or AvatarBase64) must be provided to update the profile."
                return $null
            }
            
            $session = Get-BlueskySession -Raw
            if (-not $session) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }
            
            # Get current profile to merge with updates
            $currentProfile = Get-BlueskyProfile
            if (-not $currentProfile) {
                throw "Unable to retrieve current profile information"
            }
            
            if ($PSCmdlet.ShouldProcess("Profile", "Update Bluesky profile")) {
                # Build the updated record
                $record = @{
                    '$type' = "app.bsky.actor.profile"
                    displayName = if ($DisplayName) { $DisplayName } else { $currentProfile.DisplayName }
                    description = if ($PSBoundParameters.ContainsKey('Description')) { $Description } else { $currentProfile.Description }
                }
                
                # Handle avatar upload if provided
                if ($AvatarPath) {
                    Write-Verbose "Uploading avatar from file: $AvatarPath"
                    $avatarUpload = Send-BlueSkyImageApi -Session $session -Path $AvatarPath
                    if ($avatarUpload -and $avatarUpload.blob) {
                        $record.avatar = $avatarUpload.blob
                        Write-Verbose "Avatar uploaded successfully"
                    } else {
                        Write-Warning "Failed to upload avatar image"
                    }
                } elseif ($AvatarBase64) {
                    Write-Verbose "Uploading avatar from base64 data"
                    $avatarUpload = Send-BlueSkyImageApi -Session $session -Base64 $AvatarBase64
                    if ($avatarUpload -and $avatarUpload.blob) {
                        $record.avatar = $avatarUpload.blob
                        Write-Verbose "Avatar uploaded successfully"
                    } else {
                        Write-Warning "Failed to upload avatar image"
                    }
                }
                
                # Update the profile via API
                $endpoint = '/xrpc/com.atproto.repo.putRecord'
                $body = @{
                    repo = $session.Did
                    collection = "app.bsky.actor.profile"
                    rkey = "self"
                    record = $record
                }
                
                $result = Invoke-BlueSkyApiRequest -Session $session -Endpoint $endpoint -Method 'POST' -Body $body
                
                if ($result) {
                    Write-Information "Profile updated successfully" -InformationAction Continue
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
            }
            
        } catch {
            $errorMessage = switch -Regex ($_.Exception.Message) {
                '401|Unauthorized' { "Authentication failed. Please reconnect using Connect-BlueskySession." }
                '403|Forbidden' { "Access denied. You may not have permission to update this profile." }
                '413|Payload Too Large' { "Avatar image is too large. Please use a smaller image." }
                default { "Failed to update profile: $($_.Exception.Message)" }
            }
            Write-Error $errorMessage
            return $null
        }
    }
}
