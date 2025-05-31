Describe 'Get-BlueskyFollowers' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    
    It 'Returns $null if API returns nothing' {
        Mock Invoke-BlueSkyApiRequest { $null }
        $result = Get-BlueskyFollowers
        $result | Should -Be $null
    }
    
    It 'Returns followers list when API succeeds' {
        Mock Invoke-BlueSkyApiRequest { @{ followers = @(@{ handle = 'user1' }, @{ handle = 'user2' }) } }
        $result = Get-BlueskyFollowers
        $result.Count | Should -Be 2
    }
}
