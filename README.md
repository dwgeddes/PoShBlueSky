# PSBlueSky PowerShell Module

A comprehensive PowerShell module for interacting with the [Bluesky](https://bsky.app) social network via the AT Protocol. PSBlueSky provides intuitive cmdlets for posting content, managing social connections, retrieving timelines, and performing advanced social media operations.

## ✨ Features

### 🔐 **Session Management**
- Secure authentication with credential protection
- Session information with masked tokens for security
- Support for environment variable credentials

### 📝 **Content Management**
- Create posts with text and image attachments
- Delete and manage your posts
- Search across the Bluesky network
- Retrieve personalized timelines with user-friendly formatting

### 👥 **Social Interactions**
- Follow and unfollow users
- Like and unlike posts
- Block and mute users for content control
- Manage your social graph

### 🔔 **Notifications & Communication**
- Retrieve and filter notifications with pagination support
- Track replies to your posts
- Get unresponded replies for easy engagement

### 📊 **Profile Management**
- Update profile information and avatars
- Retrieve detailed profile data
- Manage account settings

## 🚀 Quick Start

### Installation

Install from PowerShell Gallery:
```powershell
Install-Module -Name PSBlueSky -Scope CurrentUser
```

Or clone and import locally:
```powershell
git clone https://github.com/yourrepo/PSBlueSky.git
Import-Module ./PSBlueSky/BlueSkyModule.psd1
```

### Basic Usage

```powershell
# Connect to Bluesky
Connect-BlueskySession -Username 'your.handle.bsky.social'

# Create a post
New-BlueskyPost -Text "Hello from PowerShell! 🚀"

# Get your timeline with clean, user-friendly output
$timeline = Get-BlueskyTimeline -Limit 10
$timeline | Format-Table AuthorName, Text, LikeCount, CreatedAt

# Search for posts
$posts = Search-BlueskyPost -Query "PowerShell" -Limit 20
$posts | Where-Object { $_.AuthorHandle -like "*powershell*" }

# Check your profile
Get-BlueskyProfile

# Get notifications with pagination
Get-BlueskyNotification -All -Limit 500

# Disconnect when done
Disconnect-BlueskySession
```

## 📚 Available Commands

### Session Management
| Command | Description |
|---------|-------------|
| `Connect-BlueskySession` | Establish authenticated connection |
| `Disconnect-BlueskySession` | Close and clear session |
| `Get-BlueskySession` | View current session information (masked tokens) |

### Content Operations
| Command | Description |
|---------|-------------|
| `New-BlueskyPost` | Create posts with text and images |
| `Remove-BlueskyPost` | Delete your posts with confirmation |
| `Get-BlueskyTimeline` | Retrieve your personalized timeline |
| `Search-BlueskyPost` | Search for posts across the network |

### Social Interactions
| Command | Description |
|---------|-------------|
| `Add-BlueskyFollowedUser` | Follow users |
| `Remove-BlueskyFollowedUser` | Unfollow users |
| `Get-BlueskyFollowedUser` | List users you follow |
| `Get-BlueskyFollower` | List your followers |
| `Add-BlueskyLike` | Like posts |
| `Remove-BlueskyLike` | Unlike posts |

### Moderation & Safety
| Command | Description |
|---------|-------------|
| `Add-BlueskyBlockedUser` | Block users |
| `Remove-BlueskyBlockedUser` | Unblock users |
| `Add-BlueskyMutedUser` | Mute users |
| `Remove-BlueskyMutedUser` | Unmute users |

### Notifications & Communication
| Command | Description |
|---------|-------------|
| `Get-BlueskyNotification` | Get notifications (with -All for pagination) |
| `Get-BlueskyReply` | Get replies to your posts (with -Unresponded filter) |

### Profile Management
| Command | Description |
|---------|-------------|
| `Get-BlueskyProfile` | Retrieve profile information |
| `Update-BlueskyProfile` | Update profile details and avatar |

## 💡 Enhanced Examples

### User-Friendly Timeline Output

```powershell
# Get timeline with rich, clean output
$timeline = Get-BlueskyTimeline -Limit 20

# Display timeline with formatted output
$timeline | Select-Object AuthorName, AuthorHandle, Text, LikeCount, RepostCount, CreatedAt |
    Format-Table -AutoSize

# Filter and interact with timeline posts
$timeline | Where-Object { $_.Text -match "PowerShell" } |
    ForEach-Object { 
        Write-Host "💙 Liking post by $($_.AuthorName): $($_.Text)" -ForegroundColor Cyan
        Add-BlueskyLike -PostUri $_.PostUri
    }
```

### Enhanced Notification Management

```powershell
# Get all notifications with user-friendly formatting
$notifications = Get-BlueskyNotification -All -Limit 1000

# Group notifications by type with clean output
$notifications | Group-Object Type | Format-Table Name, Count -AutoSize

# Check for unresponded replies with rich data
$unresponded = Get-BlueskyReply -Unresponded
if ($unresponded) {
    Write-Host "📝 You have $($unresponded.Count) unresponded replies:" -ForegroundColor Yellow
    $unresponded | Select-Object AuthorName, Text, Date | Format-Table -AutoSize
}

# Filter recent notifications
$recent = $notifications | Where-Object { $_.Date -gt (Get-Date).AddDays(-1) }
Write-Host "🔔 $($recent.Count) notifications in the last 24 hours"
```

### Advanced Social Management

```powershell
# Find and follow PowerShell enthusiasts
$powerShellPosts = Search-BlueskyPost -Query "PowerShell automation" -Limit 50
$uniqueAuthors = $powerShellPosts | 
    Where-Object { $_.AuthorDescription -match "developer|engineer|automation" } |
    Select-Object -ExpandProperty AuthorDid -Unique |
    Select-Object -First 10

foreach ($authorDid in $uniqueAuthors) {
    try {
        Add-BlueskyFollowedUser -UserDid $authorDid
        Write-Host "✅ Followed user: $authorDid" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to follow $authorDid`: $($_.Exception.Message)"
    }
}
```

### Profile Management with Error Handling

```powershell
# Update profile with comprehensive error handling
try {
    Update-BlueskyProfile -DisplayName "PowerShell Expert" `
                         -Description "Automating the world with PowerShell 🚀💻" `
                         -AvatarPath "C:\Pictures\powershell_avatar.jpg"
    
    Write-Host "✅ Profile updated successfully!" -ForegroundColor Green
    
    # Verify the update
    $profile = Get-BlueskyProfile
    Write-Host "📊 Profile Stats: $($profile.FollowersCount) followers, $($profile.PostsCount) posts"
    
} catch {
    Write-Error "Failed to update profile: $($_.Exception.Message)"
}
```

### Content Management with Rich Output

```powershell
# Create post and track the result
$postResult = New-BlueskyPost -Text "Just deployed a new PowerShell automation! 🎉" `
                              -ImagePath "C:\Screenshots\deployment.png"

if ($postResult.Success) {
    Write-Host "📝 Post created successfully!" -ForegroundColor Green
    Write-Host "🔗 Post URL: $($postResult.PostUrl)" -ForegroundColor Cyan
    Write-Host "🆔 Post ID: $($postResult.PostIdentifier)" -ForegroundColor Gray
} else {
    Write-Error "Failed to create post"
}

# Later, delete the post if needed
if ($postResult.PostUri) {
    Remove-BlueskyPost -PostUri $postResult.PostUri -Confirm
}
```

## 🧪 Testing

Run the included tests to verify functionality:

```powershell
# Run all tests
Invoke-Pester ./Tests/

# Run specific test categories
Invoke-Pester ./Tests/Get-BlueskyTimeline.Tests.ps1
Invoke-Pester ./Tests/Get-BlueskyNotification.Tests.ps1

# Run comprehensive integration test
./Tests/ComprehensiveTest.ps1
```

## 📋 Requirements

- **PowerShell**: 5.1 or later (PowerShell 7+ recommended)
- **Operating System**: Windows, macOS, or Linux
- **Internet Connection**: Required for API communication
- **Bluesky Account**: Active account with app password

## 🔧 Configuration

### Environment Variables (Optional)
```powershell
# Set default credentials for automatic authentication
$env:BLUESKY_USERNAME = "your.handle.bsky.social"
$env:BLUESKY_PASSWORD = "your-app-password"
```

### Session Management
```powershell
# Check session status with masked tokens for security
$session = Get-BlueskySession
Write-Host "Status: $($session.Status)"
Write-Host "Expires: $($session.ExpiresAt)"
Write-Host "Handle: $($session.Handle)"
```

## 🎯 Key Improvements

### User-Friendly Output
- **Clean Property Names**: `AuthorName`, `PostUrl`, `LikeCount` instead of raw API responses
- **Helpful URLs**: Automatic conversion of AT URIs to clickable Bluesky URLs
- **Rich Metadata**: Comprehensive information with easy access to engagement metrics
- **Structured Objects**: Consistent object structure across all functions

### Enhanced Error Handling
- **Descriptive Messages**: Clear, actionable error messages with solution guidance
- **Graceful Degradation**: Functions handle errors gracefully and provide useful feedback
- **Validation**: Robust parameter validation with helpful error messages

### Professional Features
- **ShouldProcess Support**: Confirmation prompts for destructive operations
- **Pipeline Support**: All appropriate functions support pipeline input
- **Comprehensive Help**: Every function includes detailed help with examples
- **Pagination Support**: Efficient handling of large data sets

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Bluesky**: https://bsky.app
- **AT Protocol**: https://atproto.com
- **PowerShell Gallery**: https://www.powershellgallery.com/packages/PSBlueSky
- **Documentation**: https://github.com/yourrepo/PSBlueSky/wiki
- **Issues**: https://github.com/yourrepo/PSBlueSky/issues

## 📊 Project Status

✅ **Production Ready** - Fully implemented and tested  
🧪 **Comprehensive Testing** - Complete test suite included  
📚 **Fully Documented** - Complete documentation and examples  
🔄 **Actively Maintained** - Regular updates and improvements  
🎨 **User-Friendly** - Clean, intuitive interfaces and output

---

**Made with ❤️ by the PowerShell community**
