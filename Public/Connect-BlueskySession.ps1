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
    .EXAMPLE
        PS> Connect-BlueskySession -Username 'myhandle.bsky.social'
        Prompts for password and establishes a session.
    .EXAMPLE
        PS> $securePassword = ConvertTo-SecureString 'mypassword' -AsPlainText -Force
        PS> Connect-BlueskySession -Username 'myhandle.bsky.social' -Password $securePassword
        Establishes a session using provided credentials.
    .OUTPUTS
        PSCustomObject
        Returns the established session object with authentication tokens.
    .NOTES
        Stores credentials in environment variables for session duration.
        Session tokens are cached in the global BlueskySession variable.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "The Bluesky username or handle.")]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, 
                   HelpMessage = "The Bluesky password as a SecureString.")]
        [System.Security.SecureString]$Password
    )
    
    process {
        $ErrorActionPreference = 'Stop'
        
        try {
            # Prompt for password if not provided
            if (-not $Password) {
                Write-Host "Enter password for user: $Username" -ForegroundColor Cyan
                $Password = Read-Host -AsSecureString -Prompt "Password"
            }
            
            # Convert SecureString to plain text for API call
            $networkCredential = [System.Net.NetworkCredential]::new('', $Password)
            $plainTextPassword = $networkCredential.Password
            
            # Prepare authentication request
            $authenticationEndpoint = 'https://bsky.social/xrpc/com.atproto.server.createSession'
            $requestBody = @{ 
                identifier = $Username
                password = $plainTextPassword 
            }
            
            Write-Verbose "Attempting authentication for user: $Username"
            
            # Make authentication request
            $authResponse = Invoke-RestMethod -Uri $authenticationEndpoint -Method 'POST' -Body ($requestBody | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop
            
            # Validate response
            if (-not $authResponse -or -not $authResponse.accessJwt) {
                throw "Authentication failed: Invalid response from Bluesky service. Please verify your credentials."
            }
            
            # Store credentials in environment for session
            $env:BLUESKY_USERNAME = $Username
            $env:BLUESKY_PASSWORD = $plainTextPassword
            
            # Create and store session object
            $sessionObject = [PSCustomObject]@{
                AccessToken = $authResponse.accessJwt
                RefreshToken = $authResponse.refreshJwt
                ExpiresAt = (Get-Date).AddHours(12) # Default 12-hour expiry
                Username = $Username
                Handle = if ($authResponse.PSObject.Properties.Name -contains 'handle') { $authResponse.handle } else { $Username }
                DistributedIdentifier = if ($authResponse.PSObject.Properties.Name -contains 'did') { $authResponse.did } else { $null }
                CreatedAt = Get-Date
            }
            
            $global:BlueskySession = $sessionObject
            
            Write-Host "Successfully connected to Bluesky as: $($sessionObject.Handle)" -ForegroundColor Green
            return $sessionObject
            
        } catch [System.Net.WebException] {
            $errorMessage = "Network error connecting to Bluesky: $($_.Exception.Message)"
            Write-Error $errorMessage
            throw $errorMessage
        } catch {
            $errorMessage = switch -Regex ($_.Exception.Message) {
                'Unauthorized|401' { "Authentication failed: Invalid username or password. Please verify your credentials." }
                'Forbidden|403' { "Access denied: Your account may be restricted or suspended." }
                'Not Found|404' { "Service unavailable: Unable to reach Bluesky authentication service." }
                'timeout|timed out' { "Connection timeout: Please check your internet connection and try again." }
                default { "Authentication failed: $($_.Exception.Message)" }
            }
            Write-Error $errorMessage
            throw $errorMessage
        } finally {
            # Clear sensitive data from memory
            if ($networkCredential) {
                $networkCredential.Password = ''
            }
            $plainTextPassword = $null
        }
    }
}
