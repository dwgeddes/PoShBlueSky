Describe 'Get-BlueskyTimeline' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
        $global:BlueskySession = [PSCustomObject]@{
            Username = 'testuser'
            AccessToken = 'token'
            RefreshToken = 'refresh'
            Expires = (Get-Date).AddHours(1)
        }
    }
    It 'Returns timeline from API' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { 
            @(
                @{ post = @{ uri = 'at://test1'; author = @{ handle = 'user1' }; record = @{ text = 'Test post 1'; createdAt = '2024-01-01T12:00:00Z' }; indexedAt = '2024-01-01T12:00:00Z' } },
                @{ post = @{ uri = 'at://test2'; author = @{ handle = 'user2' }; record = @{ text = 'Test post 2'; createdAt = '2024-01-01T12:01:00Z' }; indexedAt = '2024-01-01T12:01:00Z' } },
                @{ post = @{ uri = 'at://test3'; author = @{ handle = 'user3' }; record = @{ text = 'Test post 3'; createdAt = '2024-01-01T12:02:00Z' }; indexedAt = '2024-01-01T12:02:00Z' } }
            )
        }
        $result = Get-BlueskyTimeline -Limit 3
        $result.Count | Should -Be 3
    }
    It 'Passes Cursor parameter to API' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { 
            param($Session, $Endpoint, $Method, $Query)
            return @( @{ post = @{ uri = 'at://cursor-test'; author = @{ handle = 'testuser' }; record = @{ text = "Cursor: $($Query.cursor)"; createdAt = '2024-01-01T12:00:00Z' }; indexedAt = '2024-01-01T12:00:00Z' } } )
        }
        $result = Get-BlueskyTimeline -Cursor 'abc'
        $result[0].Text | Should -Match 'abc'
    }
    It 'Returns $null if API returns nothing' {
        Mock Invoke-BlueSkyApiRequest -ModuleName BlueSkyModule { $null }
        $result = Get-BlueskyTimeline
        $result | Should -Be $null
    }
}
