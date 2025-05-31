Describe 'Get-BlueSkySession' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }
    
    BeforeEach {
        # Clear any existing session - use module scope
        $module:BlueskySession = $null
    }
    
    Context 'When session exists' {
        It 'Should return session with masked tokens' {
            $module:BlueskySession = [PSCustomObject]@{
                Handle = 'testuser.bsky.social'
                Did = 'did:plc:testuser'
                AccessJwt = 'very-long-access-token-12345'
                RefreshJwt = 'very-long-refresh-token-67890'
                CreatedAt = (Get-Date).AddHours(-1)
            }
            
            $result = Get-BlueskySession
            $result.Handle | Should -Be 'testuser.bsky.social'
            $result.AccessToken | Should -Be '***MASKED***'
            $result.RefreshToken | Should -Be '***MASKED***'
        }
    }
    
    Context 'When no session exists' {
        It 'Should return null and warn' {
            $result = Get-BlueskySession
            $result | Should -Be $null
        }
    }
    
    Context 'Raw parameter' {
        It 'Should return unmasked session when -Raw specified' {
            $module:BlueskySession = [PSCustomObject]@{
                Handle = 'testuser.bsky.social'
                Did = 'did:plc:testuser'
                AccessJwt = 'actual-token'
                RefreshJwt = 'actual-refresh'
                CreatedAt = (Get-Date).AddHours(-1)
            }
            
            $result = Get-BlueskySession -Raw
            $result.AccessJwt | Should -Be 'actual-token'
            $result.RefreshJwt | Should -Be 'actual-refresh'
        }
    }
}
