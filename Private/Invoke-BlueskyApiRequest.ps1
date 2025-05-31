function Invoke-BlueskyApiRequest {
    <#
    .SYNOPSIS
        Executes authenticated HTTP requests to the Bluesky API.
    .DESCRIPTION
        Handles HTTP requests to the Bluesky API with automatic authentication, 
        session management, and comprehensive error handling. Abstracts API 
        communication details for public functions.
    .PARAMETER Session
        The authenticated session object containing access tokens.
    .PARAMETER Endpoint
        The API endpoint path (relative to the Bluesky API base URL).
    .PARAMETER Method
        The HTTP method to use for the request.
    .PARAMETER Body
        The request body data (for POST/PUT requests).
    .PARAMETER Query
        Query parameters as a hashtable for GET requests.
    .EXAMPLE
        PS> Invoke-BlueskyApiRequest -Session $session -Endpoint '/xrpc/app.bsky.actor.getProfile' -Method 'GET'
        Makes a GET request to retrieve profile information.
    .OUTPUTS
        PSCustomObject
        Returns the API response data or null on failure.
    .NOTES
        This is an internal function used by public API wrapper functions.
        Handles authentication, rate limiting, and error responses automatically.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "The authenticated session object.")]
        $Session,
        
        [Parameter(Mandatory = $true, HelpMessage = "The API endpoint path.")]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false, HelpMessage = "The HTTP method to use.")]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [string]$Method = 'GET',
        
        [Parameter(Mandatory = $false, HelpMessage = "The request body data.")]
        $Body,
        
        [Parameter(Mandatory = $false, HelpMessage = "Query parameters as hashtable.")]
        [hashtable]$Query
    )

    try {
        $blueskyBaseUrl = 'https://bsky.social'
        
        # Get session if not provided
        $activeSession = $Session
        if (-not $activeSession) {
            $activeSession = Get-BlueskySession -Raw
            if (-not $activeSession) {
                throw 'No valid Bluesky session found. Please connect first by running "Connect-BlueskySession".'
            }
        }
        
        # Validate session has required tokens
        $accessToken = $activeSession.AccessToken ?? $activeSession.AccessJwt
        if (-not $accessToken) {
            throw 'Session does not contain a valid access token. Please reconnect by running "Connect-BlueskySession".'
        }
        
        # Prepare request headers
        $requestHeaders = @{
            'Authorization' = "Bearer $accessToken"
            'Content-Type'  = 'application/json'
            'User-Agent'    = 'PowerShell-BlueskyCLI/1.0'
            'Accept'        = 'application/json'
        }
        
        # Build request URI
        $requestUri = "$blueskyBaseUrl$Endpoint"
        if ($Query -and $Query.Count -gt 0) {
            $queryString = ""
            foreach ($key in $Query.Keys) {
                if ($queryString) { $queryString += "&" }
                $queryString += "$([System.Uri]::EscapeDataString($key))=$([System.Uri]::EscapeDataString($Query[$key]))"
            }
            $requestUri = "$requestUri`?$queryString"
        }
        
        # Prepare request parameters
        $requestParams = @{
            Uri     = $requestUri
            Headers = $requestHeaders
            Method  = $Method
            ErrorAction = 'Stop'
        }
        
        # Add body for POST/PUT requests
        if ($null -ne $Body -and $Method -in @('POST', 'PUT')) {
            $requestParams.Body = if ($Body -is [string]) { 
                $Body 
            } else { 
                $Body | ConvertTo-Json -Depth 10 -Compress
            }
            Write-Verbose "Request body: $($requestParams.Body)"
        }
        
        Write-Verbose "Making $Method request to: $requestUri"
        
        # Execute the API request
        $apiResponse = Invoke-RestMethod @requestParams
        
        Write-Verbose "API request completed successfully"
        return $apiResponse
        
    } catch [System.Net.WebException] {
        $httpResponse = $_.Exception.Response
        $statusCode = if ($httpResponse) { [int]$httpResponse.StatusCode } else { 0 }
        
        # Try to get the response body for more details
        $responseBody = ""
        if ($httpResponse -and $httpResponse.GetResponseStream) {
            try {
                $stream = $httpResponse.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                $stream.Close()
            } catch {
                Write-Verbose "Could not read response body: $_"
            }
        }
        
        $errorMessage = switch ($statusCode) {
            400 { "Bad Request: The request was invalid or malformed. $responseBody" }
            401 { "Unauthorized: Authentication failed or token expired. Please reconnect using Connect-BlueskySession." }
            403 { "Forbidden: Access denied. You may not have permission for this operation. $responseBody" }
            404 { "Not Found: The requested resource or endpoint does not exist. $responseBody" }
            429 { "Rate Limited: Too many requests. Please wait before trying again." }
            500 { "Internal Server Error: Bluesky service is experiencing issues. $responseBody" }
            503 { "Service Unavailable: Bluesky service is temporarily unavailable." }
            default { "Network error (HTTP $statusCode): $($_.Exception.Message). $responseBody" }
        }
        
        throw $errorMessage
        
    } catch [System.ArgumentException] {
        throw "Invalid request parameters: $($_.Exception.Message)"
    } catch {
        $errorMessage = switch -Regex ($_.Exception.Message) {
            'timeout|timed out' { "Request timeout: The API request took too long to complete." }
            'SSL|TLS|certificate' { "SSL/TLS error: There was a problem with the secure connection." }
            'DNS|resolve' { "DNS error: Unable to resolve the Bluesky API hostname." }
            'JSON|parse' { "Response parsing error: The API returned invalid JSON data." }
            default { "API request failed: $($_.Exception.Message)" }
        }
        
        throw $errorMessage
    }
}
