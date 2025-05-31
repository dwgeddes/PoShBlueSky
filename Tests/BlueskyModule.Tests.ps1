# Pester tests for BlueSkyModule public and private functions
# Run with: Invoke-Pester -Path BlueSkyModule/Tests

Describe 'BlueSkyModule Public Cmdlets' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        # Dot-source all private functions for testing
        Get-ChildItem "$PSScriptRoot/../Private" -Filter '*.ps1' | ForEach-Object { . $_.FullName }
        $testSession = [PSCustomObject]@{
            AccessToken = 'testtoken'
            RefreshToken = 'testrefresh'
            Expires = (Get-Date).AddHours(1)
            Username = 'testuser'
            Handle   = 'testuser.bsky.social'
            Did      = 'did:plc:testuser1234'
        }
        $module:BlueskySession = $testSession
    }

    Context 'Remove-BlueSkyPost' {
        It 'Should call Remove-BlueSkyPostApi and return result' {
            Mock Remove-BlueSkyPostApi -ModuleName BlueSkyModule { @{ success = $true } }
            $result = Remove-BlueSkyPost -PostUri 'at://test/post/123'
            $result.success | Should -Be $true
        }
    }

    Context 'Get-BlueSkyProfile' {
        It 'Should call Get-BlueSkyProfileApi and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { 
                @{ 
                    handle = 'testuser'
                    displayName = 'Test User'
                    description = 'Test profile'
                    avatar = 'https://test.com/avatar.jpg'
                    banner = 'https://test.com/banner.jpg'
                    followersCount = 100
                    followsCount = 50
                    postsCount = 25
                    createdAt = '2024-01-01T12:00:00Z'
                } 
            }
            $result = Get-BlueSkyProfile
            $result.Handle | Should -Be '@testuser'
        }
    }

    Context 'Get-BlueSkyTimeline' {
        It 'Should call Get-BlueSkyTimelineApi and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { 
                @(
                    @{ post = @{ uri = 'at://test1'; author = @{ handle = 'user1' }; record = @{ text = 'Test 1'; createdAt = '2024-01-01T12:00:00Z' }; indexedAt = '2024-01-01T12:00:00Z' } },
                    @{ post = @{ uri = 'at://test2'; author = @{ handle = 'user2' }; record = @{ text = 'Test 2'; createdAt = '2024-01-01T12:01:00Z' }; indexedAt = '2024-01-01T12:01:00Z' } },
                    @{ post = @{ uri = 'at://test3'; author = @{ handle = 'user3' }; record = @{ text = 'Test 3'; createdAt = '2024-01-01T12:02:00Z' }; indexedAt = '2024-01-01T12:02:00Z' } }
                )
            }
            $result = Get-BlueSkyTimeline -Limit 3
            $result.Count | Should -Be 3
        }
    }

    Context 'New-BlueSkyPost' {
        It 'Should call New-BlueSkyPostApi and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://test/post/123' } }
            $result = New-BlueSkyPost -Text 'Hello!'
            $result.PostUri | Should -Be 'at://test/post/123'
        }
    }

    Context 'Get-BlueSkyNotification' {
        It 'Should call Get-BlueSkyNotificationApi and return a PSObject' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { 
                @(
                    @{ 
                        reason = 'like'
                        author = @{ handle = 'testuser'; displayName = 'Test User' }
                        record = @{ text = 'Nice post!' }
                        indexedAt = '2024-01-01T10:00:00Z'
                        isRead = $false
                    }
                ) 
            }
            $result = Get-BlueSkyNotification
            $result.Count | Should -Be 1
            $result[0].Type | Should -Be 'Like'
        }
    }

    Context 'Add-BlueskyBlockedUser' {
        It 'Should call API to block a user' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://test/block/123' } }
            $result = Add-BlueskyBlockedUser -UserDid 'did:plc:testuser'
            $result.uri | Should -Be 'at://test/block/123'
        }
    }

    Context 'Remove-BlueskyBlockedUser' {
        It 'Should call API to unblock a user' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ success = $true } }
            $result = Remove-BlueskyBlockedUser -BlockUri 'at://test/block/123'
            $result.Success | Should -Be $true
        }
    }

    Context 'Add-BlueskyMutedUser' {
        It 'Should call API to mute a user' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://mute/123' } }
            $result = Add-BlueskyMutedUser -UserDid 'did:plc:testuser'
            $result.uri | Should -Be 'at://mute/123'
        }
    }

    Context 'Remove-BlueskyMutedUser' {
        It 'Should call API to unmute a user' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ success = $true } }
            $result = Remove-BlueskyMutedUser -UserDid 'did:plc:testuser'
            $result.Success | Should -Be $true
        }
    }

    Context 'Remove-BlueskyFollowedUser' {
        It 'Should call Remove-BlueskyFollowedUserApi and return result' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ success = $true } }
            $result = Remove-BlueskyFollowedUser -FollowUri 'at://test/follow/123'
            $result.success | Should -Be $true
        }
    }

    Context 'Remove-BlueskyLike' {
        It 'Should call Remove-BlueskyLikeApi and return result' {
            Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ success = $true } }
            $result = Remove-BlueskyLike -LikeUri 'at://test/like/123'
            $result.success | Should -Be $true
        }
    }

    Context 'Session Management' {
        It 'Should use module scope for session storage' {
            $module:BlueskySession | Should -Not -Be $null
            $module:BlueskySession.Username | Should -Be 'testuser'
        }
    }
}

Describe 'BlueSkyModule Private API Functions' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        # Dot-source all private functions for testing
        Get-ChildItem "$PSScriptRoot/../Private" -Filter '*.ps1' | ForEach-Object { . $_.FullName }
        $testSession = [PSCustomObject]@{
            AccessJwt = 'testtoken' # Changed from AccessToken to AccessJwt
            RefreshJwt = 'testrefresh' # Changed from RefreshToken to RefreshJwt
            Expires = (Get-Date).AddHours(1) # Keep if relevant
            Username = 'testuser'
            Handle   = 'testuser.bsky.social'
            Did      = 'did:plc:testuser1234'
        }
        # Use module scope for session variable
        $module:BlueSkySession = $testSession
    }

    Context 'Get-BlueSkyProfileApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ handle = 'testuser' } }
            # Pass the module session to the API function if it expects one
            $result = Get-BlueSkyProfileApi -Session $module:BlueSkySession -Params @{ actor = 'testuser.bsky.social' }
            $result.handle | Should -Be 'testuser'
        }
    }

    Context 'Get-BlueSkyTimelineApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ feed = @(1,2,3) } }
            $result = Get-BlueSkyTimelineApi -Session $module:BlueSkySession -Params @{ limit = 3 }
            $result.feed.Count | Should -Be 3
        }
    }

    Context 'New-BlueSkyPostApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ uri = 'at://test/post/123' } }
            $postBody = @{ repo = $module:BlueskySession.Did; collection = 'app.bsky.feed.post'; record = @{ text = 'Hello!' } }
            $result = New-BlueSkyPostApi -Session $module:BlueSkySession -Body $postBody
            $result.uri | Should -Be 'at://test/post/123'
        }
    }

    Context 'Get-BlueSkyNotificationApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ notifications = @(1,2) } }
            $result = Get-BlueSkyNotificationApi -Session $module:BlueSkySession
            $result.notifications.Count | Should -Be 2
        }
    }

    Context 'Search-BlueSkyUserApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { '{"users":[{"handle":"testuser"}]}' }
            $result = Search-BlueSkyUserApi -Session $testSession -Query 'testuser'
            $result[0].handle | Should -Be 'testuser'
        }
    }

    Context 'Add-BlueSkyLikeApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ like = 'ok' } }
            # Use the variable in the test (was defined but not used)
            $likeBody = @{ 
                collection = 'app.bsky.feed.like'
                repo = $module:BlueskySession.Did
                record = @{ 
                    subject = @{ uri = 'at://test/post/123'; cid = 'cid123'}
                    createdAt = (Get-Date -AsUtc).ToString("o") 
                } 
            }
            # Pass the body to the API call
            $result = Add-BlueSkyLikeApi -Session $module:BlueskySession -PostUri 'at://test/post/123' -Body $likeBody
            $result.like | Should -Be 'ok'
        }
    }

    Context 'Remove-BlueSkyLikeApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ removed = $true } }
            $result = Remove-BlueSkyLikeApi -Session $testSession -LikeUri 'at://test/like/123'
            $result.removed | Should -Be $true
        }
    }

    Context 'Remove-BlueSkyPostApi' {
        It 'Should call Invoke-BlueSkyApiRequest and return a PSObject' {
            Mock Invoke-BlueSkyApiRequest { @{ success = $true } }
            # Use the variable in the test (was defined but not used)
            $deleteBody = @{ 
                repo = $module:BlueskySession.Did
                collection = 'app.bsky.feed.post'
                rkey = '123' 
            }
            # Pass the body to the API call
            $result = Remove-BlueSkyPostApi -Session $module:BlueSkySession -PostUri 'at://did:plc:testuser1234/app.bsky.feed.post/123' -Body $deleteBody
            $result.success | Should -Be $true
        }
    }
}
