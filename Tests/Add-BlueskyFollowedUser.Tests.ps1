Describe 'Add-BlueskyFollowedUser/Remove-BlueskyFollowedUser' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    It 'Follows a user and returns result' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://follow/123'; followed = $true } }
        $result = Add-BlueskyFollowedUser -UserDid 'did:plc:abc'
        $result.uri | Should -Be 'at://follow/123'
    }
    It 'Unfollows a user and returns result' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ removed = $true } }
        $result = Remove-BlueskyFollowedUser -FollowUri 'at://test/follow/1'
        $result.removed | Should -Be $true
    }
    It 'Supports pipeline input for Add-BlueskyFollowedUser' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://follow/123'; followed = $true } }
        $result = 'did:plc:xyz' | Add-BlueskyFollowedUser
        $result.uri | Should -Be 'at://follow/123'
    }
    It 'Supports pipeline input for Remove-BlueskyFollowedUser' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ removed = $true } }
        $result = 'at://test/follow/2' | Remove-BlueskyFollowedUser
        $result.removed | Should -Be $true
    }
    It 'Throws on invalid UserDid' {
        { Add-BlueskyFollowedUser -UserDid '' } | Should -Throw
    }
    It 'Throws on invalid FollowUri' {
        { Remove-BlueskyFollowedUser -FollowUri '' } | Should -Throw
    }
}
