Describe 'Get-BlueSkyNotification' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueSkySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token1234567890'
            RefreshToken = 'refresh1234567890'
            ExpiresAt = (Get-Date).AddHours(1)
        }
        $env:BLUESKY_USERNAME = 'testuser'
    }
    
    Context 'Default behavior (single page)' {
        It 'Should return a list of notifications with user-friendly format' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { 
                @( 
                    @{ 
                        reason = 'like'
                        author = @{ handle = 'testuser'; displayName = 'Test User' }
                        reasonSubject = 'at://did:plc:test/app.bsky.feed.post/123'
                        indexedAt = '2024-01-01T10:00:00Z'
                        isRead = $false
                    },
                    @{ 
                        reason = 'reply'
                        author = @{ handle = 'replyuser'; displayName = 'Reply User' }
                        record = @{ text = 'Great post!' }
                        indexedAt = '2024-01-01T11:00:00Z'
                        isRead = $true
                    }
                ) 
            }
            $result = Get-BlueSkyNotification
            $result.Count | Should -Be 2
            $result[0].Type | Should -Be 'Like'
            $result[0].AuthorName | Should -Be 'Test User'
            $result[0].AuthorHandle | Should -Be '@testuser'
            $result[1].Type | Should -Be 'Reply'
            $result[1].Text | Should -Be 'Great post!'
        }
        
        It 'Should return null when no notifications found' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { $null }
            $result = Get-BlueSkyNotification
            $result | Should -Be $null
        }
    }
    
    Context 'With -All parameter (pagination)' {
        It 'Should call pagination API when -All specified' {
            Mock Get-BlueSkyAllNotificationsApi -ModuleName BlueSkyModule { 
                @( 
                    @{ 
                        reason = 'follow'
                        author = @{ handle = 'follower1' }
                        indexedAt = '2024-01-01T09:00:00Z'
                        isRead = $false
                    }
                ) 
            }
            $result = Get-BlueSkyNotification -All
            $result.Count | Should -Be 1
            $result[0].Type | Should -Be 'Follow'
        }
        
        It 'Should respect Limit parameter with -All' {
            Mock Get-BlueSkyAllNotificationsApi -ModuleName BlueSkyModule { 
                param($Session, $Limit) 
                @(1..$Limit | ForEach-Object { 
                    @{ 
                        reason = 'like'
                        author = @{ handle = "user$_" }
                        indexedAt = '2024-01-01T09:00:00Z'
                        isRead = $false
                    } 
                })
            }
            $result = Get-BlueSkyNotification -All -Limit 5
            $result.Count | Should -Be 5
        }
        
        It 'Should use default limit when -All specified without -Limit' {
            Mock Get-BlueSkyAllNotificationsApi -ModuleName BlueSkyModule { 
                param($Session, $Limit) 
                $Limit | Should -Be 1000  # Default value
                @( @{ 
                    reason = 'like'
                    author = @{ handle = 'testuser' }
                    indexedAt = '2024-01-01T09:00:00Z'
                    isRead = $false
                } )
            }
            $result = Get-BlueSkyNotification -All
            $result | Should -Not -Be $null
        }
    }
    
    Context 'Error handling' {
        It 'Should warn when no session found' {
            $global:BlueSkySession = $null
            $result = Get-BlueSkyNotification
            $result | Should -Be $null
        }
        
        It 'Should handle API errors gracefully' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { throw "API Error" }
            { Get-BlueSkyNotification } | Should -Throw "Failed to get notifications*"
        }
    }
    
    Context 'Parameter validation' {
        It 'Should validate Limit range' {
            { Get-BlueSkyNotification -All -Limit 0 } | Should -Throw
            { Get-BlueSkyNotification -All -Limit 10001 } | Should -Throw
        }
        
        It 'Should accept valid Limit values' {
            Mock Get-BlueSkyAllNotificationsApi -ModuleName BlueSkyModule { @() }
            { Get-BlueSkyNotification -All -Limit 1 } | Should -Not -Throw
            { Get-BlueSkyNotification -All -Limit 5000 } | Should -Not -Throw
            { Get-BlueSkyNotification -All -Limit 10000 } | Should -Not -Throw
        }
    }
    
    Context 'User-friendly output validation' {
        BeforeEach {
            $global:BlueSkySession = [PSCustomObject]@{
                Username = 'testuser'
                AccessToken = 'token1234567890'
                RefreshToken = 'refresh1234567890'
                ExpiresAt = (Get-Date).AddHours(1)
            }
        }
        
        It 'Should include all expected user-friendly properties' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { 
                @( @{ 
                    reason = 'mention'
                    author = @{ handle = 'mentioner'; displayName = 'Mention User'; description = 'A test user' }
                    reasonSubject = 'at://did:plc:test/app.bsky.feed.post/456'
                    record = @{ text = 'Hey @testuser, check this out!' }
                    indexedAt = '2024-01-01T12:00:00Z'
                    isRead = $false
                    uri = 'at://did:plc:test/app.bsky.feed.post/mention123'
                    cid = 'bafyreiabc123'
                } )
            }
            
            $result = Get-BlueSkyNotification
            $notification = $result[0]
            
            # Check core properties
            $notification.Type | Should -Be 'Mention'
            $notification.AuthorName | Should -Be 'Mention User'
            $notification.AuthorHandle | Should -Be '@mentioner'
            $notification.Text | Should -Be 'Hey @testuser, check this out!'
            $notification.IsRead | Should -Be $false
            
            # Check computed properties
            $notification.Reference | Should -Match 'https://bsky.app/profile/'
            $notification.ReferenceIdentifier | Should -Be '456'
            $notification.NotificationIdentifier | Should -Be 'mention123'
            
            # Check metadata
            $notification.Date | Should -BeOfType [DateTime]
            $notification.IndexedAt | Should -BeOfType [DateTime]
            $notification._RawData | Should -Not -Be $null
        }
    }
}
