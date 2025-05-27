Describe 'New-BlueskyPost' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    It 'Creates a post with text only' {
        Mock New-BlueskyPostApi { @{ uri = 'at://test/post/1' } }
        $result = New-BlueskyPost -Text 'Hello'
        $result.uri | Should -Be 'at://test/post/1'
    }
    It 'Creates a post with image path' {
        Mock Upload-BlueSkyImageApi { @{ blob = 'blobid'; mimeType = 'image/png'; size = 123 } }
        Mock New-BlueskyPostApi { param($Session, $Body) $Body.record.embed.images[0].image.ref }
        $result = New-BlueskyPost -ImagePath 'foo.png'
        $result | Should -Be 'blobid'
    }
    It 'Creates a post with image base64' {
        Mock Upload-BlueSkyImageApi { @{ blob = 'blobid'; mimeType = 'image/png'; size = 123 } }
        Mock New-BlueskyPostApi { param($Session, $Body) $Body.record.embed.images[0].image.ref }
        $result = New-BlueskyPost -ImageBase64 'abc=='
        $result | Should -Be 'blobid'
    }
    It 'Throws on invalid parameters' {
        { New-BlueskyPost -Text '' } | Should -Throw
    }
}
