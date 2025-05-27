Describe 'Get-BlueskyReply' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    
    Context 'Basic functionality' {
        It 'Returns reply notifications from API' {
            Mock Get-BlueskyNotificationApi { 
                @(
                    @{ reason = 'reply'; text = 'Reply 1' },
                    @{ reason = 'like'; text = 'Like 1' },
                    @{ reason = 'reply'; text = 'Reply 2' }
                ) 
            }
            $result = Get-BlueskyReply
            $result.Count | Should -Be 2
            $result[0].reason | Should -Be 'reply'
            $result[1].reason | Should -Be 'reply'
        }
        
        It 'Returns empty array when no replies found' {
            Mock Get-BlueskyNotificationApi { 
                @(
                    @{ reason = 'like'; text = 'Like 1' },
                    @{ reason = 'follow'; text = 'Follow 1' }
                ) 
            }
            $result = Get-BlueskyReply
            $result.Count | Should -Be 0
        }
        
        It 'Returns null when API returns null' {
            Mock Get-BlueskyNotificationApi { $null }
            $result = Get-BlueskyReply
            $result | Should -Be $null
        }
        
        It 'Throws when no session found' {
            $global:BlueskySession = $null
            { Get-BlueskyReply } | Should -Throw '*No active Bluesky session*'
        }
    }
    
    Context 'Unresponded filter' {
        BeforeEach {
            $global:BlueskySession = [PSCustomObject]@{
                Username = 'testuser'
                AccessToken = 'token'
                RefreshToken = 'refresh'
                Expires = (Get-Date).AddHours(1)
            }
        }
        
        It 'Filters unresponded replies when -Unresponded specified' {
            Mock Get-BlueskyNotificationApi { 
                @(
                    @{ 
                        reason = 'reply'
                        uri = 'at://reply1'
                        record = @{ reply = @{ root = @{ uri = 'at://root1' } } }
                    }
                ) 
            }
            Mock Invoke-BlueSkyApiRequest { 
                @{ thread = @{ replies = @() } }
            }
            $result = Get-BlueskyReply -Unresponded
            $result.Count | Should -Be 1
        }
        
        It 'Excludes replies already responded to' {
            Mock Get-BlueskyNotificationApi { 
                @(
                    @{ 
                        reason = 'reply'
                        uri = 'at://reply1'
                        record = @{ reply = @{ root = @{ uri = 'at://root1' } } }
                    }
                ) 
            }
            Mock Invoke-BlueSkyApiRequest { 
                @{ 
                    thread = @{ 
                        replies = @(
                            @{ post = @{ author = @{ handle = 'testuser' } } }
                        )
                    } 
                }
            }
            $result = Get-BlueskyReply -Unresponded
            $result.Count | Should -Be 0
        }
    }
}
