Describe 'Get-BlueskyFollowers' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    It 'Returns followers from API' {
        Mock Invoke-BlueSkyApiRequest { @{ followers = @( @{ handle = 'bob' } ) } }
        $result = Get-BlueskyFollowers
        $result[0].handle | Should -Be 'bob'
    }
    It 'Throws if session has no actor identifier' {
        $badSession = [PSCustomObject]@{ AccessToken = 'token' }
        { Get-BlueskyFollowers -Session $badSession } | Should -Throw -ErrorMessage '*valid actor identifier*'
    }
    It 'Returns $null if API returns nothing' {
        Mock Invoke-BlueSkyApiRequest { $null }
        $result = Get-BlueskyFollowers
        $result | Should -Be $null
    }
}
