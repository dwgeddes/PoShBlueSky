Describe 'Get-BlueskyProfile' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    It 'Returns profile for current session' {
        Mock Get-BlueskyProfileApi { @{ handle = 'testuser' } }
        $result = Get-BlueskyProfile
        $result.handle | Should -Be 'testuser'
    }
    It 'Returns profile for specified actor' {
        Mock Get-BlueskyProfileApi { param($Params) @{ handle = $Params.actor } }
        $result = Get-BlueskyProfile -Actor 'bob'
        $result.handle | Should -Be 'bob'
    }
    It 'Returns $null if API returns nothing' {
        Mock Get-BlueskyProfileApi { $null }
        $result = Get-BlueskyProfile
        $result | Should -Be $null
    }
}
