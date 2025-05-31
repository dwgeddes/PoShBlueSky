function Connect-BlueskySession {
    <#
    .SYNOPSIS
        Establishes an authenticated session with the Bluesky service.
    .DESCRIPTION
        Authenticates a user with the Bluesky service using credentials and stores the session 
        information securely for subsequent API calls. Supports both interactive and programmatic authentication.
    .PARAMETER Username
        The Bluesky username or handle (e.g., 'user.bsky.social' or 'user@domain.com').
    .PARAMETER Password
        The Bluesky password as a SecureString for enhanced security.
    .PARAMETER Credential
        A PSCredential object containing username and password.
    .EXAMPLE
        PS> Connect-BlueskySession -Username 'myhandle.bsky.social'
        Prompts for password and establishes a session.
    .EXAMPLE
        PS> $credential = Get-Credential
        PS> Connect-BlueskySession -Credential $credential
        Establishes a session using a credential object.
    .OUTPUTS
        PSCustomObject
        Returns the established session object with authentication tokens.
    .NOTES
        Session tokens are cached in the module scope for subsequent API calls.
        Avoid using plaintext passwords - use Get-Credential or SecureString instead.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [securestring]$Password,
        
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )
    
    try {
        # Get credentials from various sources
        if ($Credential) {
            $Username = $Credential.UserName
            $Password = $Credential.Password
        } elseif (-not ($Username -and $Password)) { # Check if both are not provided
            $envUsername = $env:BLUESKY_USERNAME
            $envPasswordStr = $env:BLUESKY_PASSWORD # Read as string first
            
            if ($envUsername -and $envPasswordStr) {
                Write-Warning "Attempting to use credentials from environment variables. For production, ensure BLUESKY_PASSWORD is a securely stored (e.g., encrypted) string or use PSCredential objects/interactive prompts."
                $Username = $envUsername
                try {
                    # Attempt to convert assuming it might be an encrypted string.
                    # If it's plaintext, this will likely fail or produce a non-functional SecureString.
                    $Password = ConvertTo-SecureString $envPasswordStr
                    Write-Verbose "Successfully converted BLUESKY_PASSWORD environment variable to SecureString."
                } catch {
                    Write-Warning "Could not convert BLUESKY_PASSWORD environment variable to SecureString (was it plaintext?). Falling back to interactive prompt."
                    # Fallback to Get-Credential if conversion fails
                    $Credential = Get-Credential -Message "Enter Bluesky credentials for user '$envUsername'" -UserName $envUsername
                    if (-not $Credential) {
                        Write-Error "Credentials are required to connect."
                        return $null
                    }
                    $Username = $Credential.UserName
                    $Password = $Credential.Password
                }
            } else {
                # Prompt for credentials interactively if not fully provided by other means
                $Credential = Get-Credential -Message "Enter Bluesky credentials" -UserName $Username
                if (-not $Credential) {
                    Write-Error "Credentials are required to connect."
                    return $null
                }
                $Username = $Credential.UserName
                $Password = $Credential.Password
            }
        }
        
        if (-not $Username -or -not $Password -or $Password.Length -eq 0) {
            Write-Error "Username and a non-empty password are required."
            return $null
        }
        
        # Convert SecureString to plain text for API call
        $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        
        try {
            # Create session request
            $body = @{
                identifier = $Username
                password = $plaintextPassword
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "https://bsky.social/xrpc/com.atproto.server.createSession" -Method Post -Body $body -ContentType "application/json"
            
            # Store in module scope instead of global
            $module:BlueskySession = @{
                AccessJwt = $response.accessJwt
                RefreshJwt = $response.refreshJwt
                Handle = $response.handle
                Did = $response.did
                CreatedAt = Get-Date
                # Add AccessToken alias for compatibility
                AccessToken = $response.accessJwt
                RefreshToken = $response.refreshJwt
            }
            
            Write-Information "Successfully connected to Bluesky as $($response.handle)" -InformationAction Continue
            
            return [PSCustomObject]@{
                Handle = $response.handle
                Did = $response.did
                Status = "Connected"
                CreatedAt = Get-Date
            }
        } finally {
            # Clear the plaintext password from memory immediately
            if ($plaintextPassword) {
                $plaintextPassword = $null
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
        }
        
    } catch {
        Write-Error "Failed to connect to Bluesky: $($_.Exception.Message)"
        return $null
    }
}
