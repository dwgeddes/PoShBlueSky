function New-BlueskyPost {
    <#
    .SYNOPSIS
        Creates a new post on Bluesky with optional images.
    .DESCRIPTION
        Creates a new post with text content and optional image attachments. 
        Supports both local image files and base64-encoded image data.
        At least one of Text, ImagePath, or ImageBase64 must be provided.
    .PARAMETER Text
        The text content of the post. Maximum 300 characters.
    .PARAMETER ImagePath
        One or more local image file paths to attach to the post.
        Supported formats: JPG, PNG, GIF, WebP.
    .PARAMETER ImageBase64
        One or more base64-encoded image strings to attach to the post.
    .PARAMETER Languages
        The languages of the post content. Defaults to English ("en").
    .PARAMETER ReplyToUri
        The URI of the post this is replying to (creates a reply thread).
    .EXAMPLE
        PS> New-BlueskyPost -Text "Hello from PowerShell!"
        Creates a simple text post.
    .EXAMPLE
        PS> New-BlueskyPost -Text "Check out this image!" -ImagePath "C:\Pictures\sunset.jpg"
        Creates a post with text and an attached image.
    .EXAMPLE
        PS> New-BlueskyPost -ImagePath "C:\Pictures\photo.png"
        Creates an image-only post.
    .OUTPUTS
        PSCustomObject
        Returns the created post object with URI and other properties.
    .NOTES
        Requires an active Bluesky session.
        Images are uploaded to Bluesky's blob storage before posting.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Text', SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "The text content of the post (max 300 characters).")]
        [ValidateLength(1, 300)]
        [string]$Text,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'TextWithImagePath',
                   ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "Local image file paths to attach.")]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImagePathOnly')]
        [ValidateScript({ 
            foreach ($imagePath in $_) { 
                if (-not (Test-Path $imagePath -PathType Leaf)) { 
                    throw "Image file not found: $imagePath" 
                }
                $extension = [System.IO.Path]::GetExtension($imagePath).ToLower()
                if ($extension -notin @('.jpg', '.jpeg', '.png', '.gif', '.webp')) {
                    throw "Unsupported image format: $extension. Supported formats: .jpg, .jpeg, .png, .gif, .webp"
                }
            }
            $true 
        })]
        [string[]]$ImagePath,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'TextWithImageBase64',
                   ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "Base64-encoded image strings to attach.")]
        [Parameter(Mandatory = $true, ParameterSetName = 'ImageBase64Only')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ImageBase64,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "The languages of the post content.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Languages = @("en"),
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "The URI of the post this is replying to.")]
        [ValidatePattern('^at://')]
        [string]$ReplyToUri
    )
    
    begin {
        # Begin block initialization if needed
    }
    
    process {
        # Validate that at least one content parameter is provided
        if (-not $Text -and -not $ImagePath -and -not $ImageBase64) {
            throw "At least one of Text, ImagePath, or ImageBase64 must be provided."
        }
        try {
            $currentSession = Get-BlueskySession -Raw
            if (-not $currentSession) {
                Write-Warning "No active Bluesky session found. Please connect first by running 'Connect-BlueskySession'."
                return $null
            }

            # Build the post record
            $postRecord = @{
                '$type' = 'app.bsky.feed.post'
                langs = $Languages
                createdAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
            
            if ($Text) {
                $postRecord.text = $Text
            }
            
            if ($ReplyToUri) {
                Write-Warning "Reply functionality not yet implemented. Creating as standalone post."
            }

            # Handle image attachments
            $embedImages = @()

            if ($ImagePath) {
                Write-Verbose "Processing $($ImagePath.Count) image file(s)"
                foreach ($imagePath in $ImagePath) {
                    try {
                        $imageUploadResult = Upload-BlueSkyImageApi -Session $currentSession -Path $imagePath -ErrorAction Stop
                        if ($imageUploadResult -and $imageUploadResult.blob) {
                            $embedImages += @{
                                alt = [System.IO.Path]::GetFileNameWithoutExtension($imagePath)
                                image = @{
                                    '$type' = "blob"
                                    ref = $imageUploadResult.blob
                                    mimeType = $imageUploadResult.mimeType
                                    size = $imageUploadResult.size
                                }
                            }
                        } else {
                            throw "Failed to upload image: $imagePath"
                        }
                    } catch {
                        throw "Error uploading image '$imagePath': $($_.Exception.Message)"
                    }
                }
            }

            if ($ImageBase64) {
                Write-Verbose "Processing $($ImageBase64.Count) base64 image(s)"
                foreach ($base64Image in $ImageBase64) {
                    try {
                        $imageUploadResult = Upload-BlueSkyImageApi -Session $currentSession -Base64 $base64Image -ErrorAction Stop
                        if ($imageUploadResult -and $imageUploadResult.blob) {
                            $embedImages += @{
                                alt = "Uploaded Image"
                                image = @{
                                    '$type' = "blob"
                                    ref = $imageUploadResult.blob
                                    mimeType = $imageUploadResult.mimeType
                                    size = $imageUploadResult.size
                                }
                            }
                        } else {
                            throw "Failed to upload base64 image data"
                        }
                    } catch {
                        throw "Error uploading base64 image: $($_.Exception.Message)"
                    }
                }
            }

            if ($embedImages.Count -gt 0) {
                $postRecord.embed = @{
                    '$type' = "app.bsky.embed.images"
                    images = $embedImages
                }
            }

            # Prepare post data for API
            $postData = @{
                repo = $currentSession.Username
                collection = "app.bsky.feed.post"
                record = $postRecord
            }
            
            if ($PSCmdlet.ShouldProcess("Bluesky", "Create new post")) {
                Write-Verbose "Creating post on Bluesky"
                $postResult = New-BlueskyPostApi -Session $currentSession -Body $postData -ErrorAction Stop
                
                if ($postResult) {
                    Write-Host "Post created successfully" -ForegroundColor Green
                    
                    # Return user-friendly result with essential information
                    $postUrl = Convert-AtUriToUrl -AtUri $postResult.uri
                    $postIdentifier = Get-PostIdentifierFromUri -AtUri $postResult.uri
                    
                    return [PSCustomObject]@{
                        PostUri = $postResult.uri
                        PostUrl = $postUrl
                        PostCid = $postResult.cid
                        PostIdentifier = $postIdentifier
                        CreatedAt = if ($postResult.validationStatus) { Get-Date } else { $null }
                        Text = $Text
                        HasImages = ($embedImages.Count -gt 0)
                        ImageCount = $embedImages.Count
                        Languages = $Languages
                        ValidationStatus = if ($postResult.validationStatus) { $postResult.validationStatus } else { 'Success' }
                        # Keep original response for advanced users
                        _RawData = $postResult
                    }
                } else {
                    throw "Post creation failed: No response from API"
                }
            }
        } catch {
            $errorMessage = "Failed to create post: $($_.Exception.Message)"
            Write-Error $errorMessage
            return $null
        }
    }
}
