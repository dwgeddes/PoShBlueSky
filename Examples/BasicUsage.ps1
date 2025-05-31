<#
.SYNOPSIS
    Basic usage examples for the PSBlueSky PowerShell module.
.DESCRIPTION
    This script demonstrates the fundamental operations available in the PSBlueSky module
    including authentication, posting, and basic social interactions.
#>

# Import the module
Import-Module PSBlueSky

try {
    # Example 1: Connect to Bluesky
    Write-Information "=== Example 1: Authentication ===" -InformationAction Continue
    
    # Interactive authentication (most secure)
    $session = Connect-BlueskySession
    if ($session) {
        Write-Information "✅ Connected as: $($session.Handle)" -InformationAction Continue
    } else {
        throw "Failed to connect to Bluesky"
    }
    
    # Example 2: Create a simple post
    Write-Information "=== Example 2: Creating Posts ===" -InformationAction Continue
    
    $postResult = New-BlueskyPost -Text "Hello from PowerShell! 🚀 #PowerShell #Automation"
    if ($postResult) {
        Write-Information "✅ Post created: $($postResult.PostUrl)" -InformationAction Continue
    }
    
    # Example 3: Get your profile information
    Write-Information "=== Example 3: Profile Information ===" -InformationAction Continue
    
    $userProfile = Get-BlueskyProfile # Changed from $profile to $userProfile to avoid automatic variable
    if ($userProfile) {
        Write-Information "📊 Profile: $($userProfile.DisplayName) (@$($userProfile.Handle))" -InformationAction Continue
        Write-Information "📈 Stats: $($userProfile.FollowersCount) followers, $($userProfile.PostsCount) posts" -InformationAction Continue
    }
    
    # Example 4: Get your timeline
    Write-Information "=== Example 4: Timeline Retrieval ===" -InformationAction Continue
    
    $timeline = Get-BlueskyTimeline -Limit 5
    if ($timeline) {
        Write-Information "📰 Recent timeline posts:" -InformationAction Continue
        $timeline | ForEach-Object {
            Write-Information "  - $($_.AuthorName): $($_.Text)" -InformationAction Continue
        }
    }
    
    # Example 5: Search for posts
    Write-Information "=== Example 5: Searching Posts ===" -InformationAction Continue
    
    $searchResults = Search-BlueskyPost -Query "PowerShell" -Limit 3
    if ($searchResults) {
        Write-Information "🔍 PowerShell posts found: $($searchResults.Count)" -InformationAction Continue
        $searchResults | ForEach-Object {
            Write-Information "  - $($_.AuthorName): $($_.Text)" -InformationAction Continue
        }
    }
    
    # Example 6: Get notifications
    Write-Information "=== Example 6: Notifications ===" -InformationAction Continue
    
    $notifications = Get-BlueskyNotification -Limit 3
    if ($notifications) {
        Write-Information "🔔 Recent notifications: $($notifications.Count)" -InformationAction Continue
        $notifications | ForEach-Object {
            Write-Information "  - $($_.Type): $($_.AuthorName)" -InformationAction Continue
        }
    }
    
    Write-Information "=== Examples completed successfully! ===" -InformationAction Continue
    
} catch {
    Write-Error "Example failed: $($_.Exception.Message)"
} finally {
    # Always disconnect when done
    Disconnect-BlueskySession
    Write-Information "🔒 Session disconnected" -InformationAction Continue
}
