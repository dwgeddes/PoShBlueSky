Describe 'Add/Remove-BlueskyLike' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    
    It 'Likes a post and returns result' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://like/123'; liked = $true } }
        $result = Add-BlueskyLike -PostUri 'at://test/post/abc'
        $result.uri | Should -Be 'at://like/123'
    }
    
    It 'Removes a like and returns result' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ removed = $true } }
        $result = Remove-BlueskyLike -LikeUri 'at://test/like/1'
        $result.removed | Should -Be $true
    }
    
    It 'Supports pipeline input for Add-BlueskyLike' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ uri = 'at://like/123'; liked = $true } }
        $result = 'at://test/post/xyz' | Add-BlueskyLike
        $result.uri | Should -Be 'at://like/123'
    }
    
    It 'Supports pipeline input for Remove-BlueskyLike' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { @{ removed = $true } }
        $result = 'at://test/like/2' | Remove-BlueskyLike
        $result.removed | Should -Be $true
    }
    
    It 'Throws on invalid PostUri' {
        { Add-BlueskyLike -PostUri '' } | Should -Throw
    }
    
    It 'Throws on invalid LikeUri' {
        { Remove-BlueskyLike -LikeUri '' } | Should -Throw
    }
}
