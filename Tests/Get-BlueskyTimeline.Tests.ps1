Describe 'Get-BlueskyTimeline' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    
    Context 'Basic functionality' {
        It 'Should return timeline posts' {
            Mock Get-BlueskyTimelineApi { 
                @(
                    @{ 
                        post = @{
                            uri = 'at://test/post/1'
                            author = @{ handle = 'testuser'; displayName = 'Test User' }
                            record = @{ text = 'Test post'; createdAt = '2024-01-01T10:00:00Z' }
                            likeCount = 5
                            repostCount = 2
                        }
                    }
                )
            }
            
            $result = Get-BlueskyTimeline -Limit 10
            $result.Count | Should -Be 1
            $result[0].AuthorName | Should -Be 'Test User'
            $result[0].Text | Should -Be 'Test post'
        }
        
        It 'Should handle cursor parameter' {
            Mock Get-BlueskyTimelineApi { 
                param($Params)
                # Verify cursor is passed to API
                $Params.cursor | Should -Be 'testcursor'
                return @()
            }
            
            Get-BlueskyTimeline -Cursor 'testcursor'
        }
    }
    
    Context 'Error handling' {
        It 'Should return empty array when no session found' {
            $module:BlueskySession = $null
            $result = Get-BlueskyTimeline
            $result | Should -Be @()
        }
    }
}
