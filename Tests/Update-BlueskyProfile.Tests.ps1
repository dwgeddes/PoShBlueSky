Describe 'Update-BlueskyProfile' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }

    Context 'Parameter validation' {
        It 'Throws if no parameters are specified' {
            { Update-BlueskyProfile } | Should -Throw -ErrorMessage '*at least one property*'
        }
        It 'Throws if both AvatarPath and AvatarBase64 are specified' {
            { Update-BlueskyProfile -AvatarPath 'foo.jpg' -AvatarBase64 'abc==' } | Should -Throw -ErrorMessage '*only one of AvatarPath or AvatarBase64*'
        }
    }

    Context 'Normal operation' {
        It 'Updates display name only' {
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; displayName = 'NewName' } }
            $result = Update-BlueskyProfile -DisplayName 'NewName'
            $result.displayName | Should -Be 'NewName'
        }
        It 'Updates description only' {
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; description = 'Bio' } }
            $result = Update-BlueskyProfile -Description 'Bio'
            $result.description | Should -Be 'Bio'
        }
        It 'Updates avatar from path' {
            Mock Upload-BlueSkyImageApi { @{ blob = 'blobid' } }
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; avatar = 'blobid' } }
            $result = Update-BlueskyProfile -AvatarPath 'foo.jpg'
            $result.avatar | Should -Be 'blobid'
        }
        It 'Updates avatar from base64' {
            Mock Upload-BlueSkyImageApi { @{ blob = 'blobid' } }
            Mock Invoke-BlueSkyApiRequest { @{ success = $true; avatar = 'blobid' } }
            $result = Update-BlueskyProfile -AvatarBase64 'abc=='
            $result.avatar | Should -Be 'blobid'
        }
    }

    Context 'Error handling' {
        It 'Throws if Upload-BlueSkyImageApi fails for path' {
            Mock Upload-BlueSkyImageApi { $null }
            { Update-BlueskyProfile -AvatarPath 'foo.jpg' } | Should -Throw -ErrorMessage '*Failed to upload avatar image from path*'
        }
        It 'Throws if Upload-BlueSkyImageApi fails for base64' {
            Mock Upload-BlueSkyImageApi { $null }
            { Update-BlueskyProfile -AvatarBase64 'abc==' } | Should -Throw -ErrorMessage '*Failed to upload avatar image from base64*'
        }
        It 'Returns $null and writes error if API call fails' {
            Mock Invoke-BlueSkyApiRequest { throw 'API error' }
            $result = Update-BlueskyProfile -DisplayName 'fail'
            $result | Should -Be $null
        }
    }
}
