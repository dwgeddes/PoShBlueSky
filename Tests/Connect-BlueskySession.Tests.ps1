Describe 'Connect-BlueSkySession' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }

    Context 'With valid credentials (mocked)' {
        It 'Should set environment variables and global session on success' {
            Mock Invoke-RestMethod -ModuleName BlueSkyModule {
                [PSCustomObject]@{
                    accessJwt = 'mocktoken'
                    refreshJwt = 'mockrefresh'
                }
            }
            $username = 'testuser'
            $password = ConvertTo-SecureString 'testpass' -AsPlainText -Force
            Connect-BlueSkySession -Username $username -Password $password
            $env:BLUESKY_USERNAME | Should -Be $username
            $env:BLUESKY_PASSWORD | Should -Be 'testpass'
            $global:BlueSkySession.AccessToken | Should -Be 'mocktoken'
        }
    }

    Context 'With invalid credentials (mocked)' {
        It 'Should throw and not set session or env vars' {
            Mock Invoke-RestMethod -ModuleName BlueSkyModule { throw 'Authentication failed: No access token returned.' }
            $username = 'baduser'
            $password = ConvertTo-SecureString 'badpass' -AsPlainText -Force
            { Connect-BlueSkySession -Username $username -Password $password -ErrorAction Stop } | Should -Throw -ErrorId *
        }
    }
}
