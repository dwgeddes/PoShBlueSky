Describe 'Get-BlueSkyFollowedUser' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }
    
    Context 'When session is missing all actor identifiers' {
        It 'Should throw an error about missing actor identifier' {
            $badSession = [PSCustomObject]@{ AccessToken = 'token'; RefreshToken = 'refresh'; Expires = (Get-Date).AddHours(1) }
            { Get-BlueSkyFollowedUser -Session $badSession } | Should -Throw -ErrorMessage 'Session does not contain a valid actor identifier*'
        }
    }
    Context 'When session has Username' {
        It 'Should call API with Username as actor' {
            $goodSession = [PSCustomObject]@{ Username = 'testuser'; AccessToken = 'token'; RefreshToken = 'refresh'; Expires = (Get-Date).AddHours(1) }
            Mock Invoke-BlueSkyApiRequest { '{"follows":[{"handle":"bob"}]}' }
            $result = Get-BlueSkyFollowedUser -Session $goodSession
            $result[0].handle | Should -Be 'bob'
        }
    }
    Context 'When session has Handle but not Username' {
        It 'Should call API with Handle as actor' {
            $goodSession = [PSCustomObject]@{ Handle = 'testhandle'; AccessToken = 'token'; RefreshToken = 'refresh'; Expires = (Get-Date).AddHours(1) }
            Mock Invoke-BlueSkyApiRequest { '{"follows":[{"handle":"bob"}]}' }
            $result = Get-BlueSkyFollowedUser -Session $goodSession
            $result[0].handle | Should -Be 'bob'
        }
    }
    Context 'When session has Did but not Username or Handle' {
        It 'Should call API with Did as actor' {
            $goodSession = [PSCustomObject]@{ Did = 'did:plc:123'; AccessToken = 'token'; RefreshToken = 'refresh'; Expires = (Get-Date).AddHours(1) }
            Mock Invoke-BlueSkyApiRequest { '{"follows":[{"handle":"bob"}]}' }
            $result = Get-BlueSkyFollowedUser -Session $goodSession
            $result[0].handle | Should -Be 'bob'
        }
    }
}
