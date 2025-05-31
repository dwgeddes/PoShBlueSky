# Tests for Get-BlueSkyNotification
Describe 'Get-BlueSkyNotification' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }
    
    BeforeEach {
        # Ensure a consistent module session state for tests
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser' # Or Handle/Did depending on what Get-BlueSkyNotificationApi expects
            AccessJwt = 'token1234567890' # Renamed from AccessToken to match Connect-BlueskySession output
            RefreshJwt = 'refresh1234567890' # Renamed from RefreshToken
            Expires = (Get-Date).AddHours(1) # Keep if relevant for session validity checks
        }
        # $env:BLUESKY_USERNAME = 'testuser' # Avoid relying on environment variables in unit tests directly if possible
    }
    
    Context 'When notifications are returned' {
        It 'Should return a list of notifications' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { @( @{ text = 'hi' }, @{ text = 'hello' } ) }
            $result = Get-BlueSkyNotification
            $result.Count | Should -Be 2
            $result[0].text | Should -Be 'hi'
        }
    }
    
    Context 'When no notifications are returned' {
        It 'Should return empty array and warn (as per Get-* standards)' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { $null }
            $result = Get-BlueSkyNotification
            $result | Should -BeOfType([array])
            $result.Count | Should -Be 0
        }
    }
    
    Context 'When not connected' {
        It 'Should return empty array and error if no session' {
            $module:BlueskySession = $null # Clear the session for this test
            $result = Get-BlueSkyNotification
            $result | Should -BeOfType([array])
            $result.Count | Should -Be 0
            # Pester assertion for Write-Error might be needed if strict error checking is desired
        }
    }
}
