Describe 'Get-BlueSkySession' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }
    
    Context 'When a session exists' {
        It 'Should return session details as a PSObject' {
            $global:BlueSkySession = [PSCustomObject]@{
                Username = 'testuser'
                AccessToken = 'token1234567890'
                RefreshToken = 'refresh1234567890'
                Expires = (Get-Date).AddHours(1)
            }
            $env:BLUESKY_USERNAME = 'testuser'
            $result = Get-BlueSkySession
            $result.Username | Should -Be 'testuser'
            $result.AccessToken | Should -Be 'token1234...'
            $result.RefreshToken | Should -Be 'refresh1...'
            $result.Expires | Should -BeGreaterThan (Get-Date)
        }
    }
    
    Context 'When no session exists' {
        It 'Should return null and warn' {
            Remove-Variable -Name BlueSkySession -Scope Global -ErrorAction SilentlyContinue
            $result = Get-BlueSkySession
            $result | Should -Be $null
        }
    }
}

Describe 'Get-BlueSkyNotification' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueSkySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token1234567890'
            RefreshToken = 'refresh1234567890'
            Expires = (Get-Date).AddHours(1)
        }
        $env:BLUESKY_USERNAME = 'testuser'
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
        It 'Should return null and warn' {
            Mock Get-BlueSkyNotificationApi -ModuleName BlueSkyModule { $null }
            $result = Get-BlueSkyNotification
            $result | Should -Be $null
        }
    }
    
    Context 'When not connected' {
        It 'Should throw if no session' {
            Remove-Variable -Name BlueSkySession -Scope Global -ErrorAction SilentlyContinue
            { Get-BlueSkyNotification } | Should -Throw
        }
    }
}
