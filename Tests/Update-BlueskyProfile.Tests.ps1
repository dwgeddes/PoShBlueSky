Describe 'Update-BlueskyProfile' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        # Use module scope instead of global
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }

    Context 'Parameter validation' {
        It 'Returns null and warns if no parameters are specified' {
            $result = Update-BlueskyProfile
            $result | Should -Be $null
        }
        
        It 'Validates parameter sets correctly' {
            { Update-BlueskyProfile -AvatarPath 'foo.jpg' -AvatarBase64 'abc==' } | Should -Throw
        }
    }

    Context 'Normal operation' {
        It 'Updates display name only' {
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; displayName = 'NewName' } }
            Mock Get-BlueskyProfileApi { @{ displayName = 'OldName'; description = 'Bio' } }
            $result = Update-BlueskyProfile -DisplayName 'NewName'
            $result.DisplayName | Should -Be 'NewName'
        }
        
        It 'Updates description only' {
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; description = 'Bio' } }
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'OldBio' } }
            $result = Update-BlueskyProfile -Description 'Bio'
            $result.Description | Should -Be 'Bio'
        }
        
        It 'Updates avatar from path' {
            Mock Upload-BlueSkyImageApi { @{ blob = 'blobid' } }
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'Bio' } }
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; avatar = 'blobid' } }
            $result = Update-BlueskyProfile -AvatarPath 'foo.jpg'
            $result.Avatar | Should -Be 'Updated'
        }
        
        It 'Updates avatar from base64' {
            Mock Upload-BlueSkyImageApi { @{ blob = 'blobid' } }
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'Bio' } }
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; avatar = 'blobid' } }
            $result = Update-BlueskyProfile -AvatarBase64 'abc=='
            $result.Avatar | Should -Be 'Updated'
        }
    }

    Context 'Error handling' {
        It 'Returns null and writes error if Upload-BlueSkyImageApi fails for path' {
            Mock Upload-BlueSkyImageApi { $null }
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'Bio' } }
            $result = Update-BlueskyProfile -AvatarPath 'foo.jpg'
            $result | Should -Be $null
        }
        
        It 'Returns null and writes error if Upload-BlueSkyImageApi fails for base64' {
            Mock Upload-BlueSkyImageApi { $null }
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'Bio' } }
            $result = Update-BlueskyProfile -AvatarBase64 'abc=='
            $result | Should -Be $null
        }
        
        It 'Returns null and writes error if API call fails' {
            Mock Get-BlueskyProfileApi { @{ displayName = 'Name'; description = 'Bio' } }
            Mock Invoke-BlueSkyApiRequest { throw 'API error' }
            $result = Update-BlueskyProfile -DisplayName 'fail'
            $result | Should -Be $null
        }
    }
}
