Describe 'New-BlueskyPost' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $module:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    
    It 'Creates a post with image path' {
        Mock Upload-BlueSkyImageApi { @{ blob = 'blobid'; mimeType = 'image/png'; size = 123 } }
        Mock New-BlueskyPostApi { @{ uri = 'at://test/post/123'; cid = 'cid123' } }
        $result = New-BlueskyPost -ImagePath 'foo.png'
        $result.PostUri | Should -Be 'at://test/post/123'
    }
    
    It 'Creates a post with image base64' {
        Mock Upload-BlueSkyImageApi { @{ blob = 'blobid'; mimeType = 'image/png'; size = 123 } }
        Mock New-BlueskyPostApi { @{ uri = 'at://test/post/123'; cid = 'cid123' } }
        $result = New-BlueskyPost -ImageBase64 'abc=='
        $result.PostUri | Should -Be 'at://test/post/123'
    }
    
    It 'Creates a post with text' {
        Mock New-BlueskyPostApi { @{ uri = 'at://test/post/123'; cid = 'cid123' } }
        $result = New-BlueskyPost -Text 'Hello World'
        $result.PostUri | Should -Be 'at://test/post/123'
    }
    
    It 'Returns null on invalid parameters' {
        $result = New-BlueskyPost
        $result | Should -Be $null
    }
}
