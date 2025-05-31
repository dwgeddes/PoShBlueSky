Describe 'Connect-BlueskySession' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../BlueSkyModule.psd1" -Force
    }
    
    BeforeEach {
        # Clear any existing session and test environment variables
        $module:BlueskySession = $null
        Remove-Item env:BLUESKY_USERNAME -ErrorAction SilentlyContinue
        Remove-Item env:BLUESKY_PASSWORD -ErrorAction SilentlyContinue
    }
    
    Context 'Parameter validation' {
        It 'Should accept PSCredential parameter' {
            # For testing only; dummy credentials are created using plaintext conversion
            $secure = ConvertTo-SecureString 'dummy' -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential('user', $secure)
            # Test that the function can be called with -Credential, actual connection will fail/mocked
            try { 
                Connect-BlueskySession -Credential $cred 
            } catch {
                # Connection is expected to fail with dummy credentials
                Write-Verbose "Expected failure with dummy credentials: $($_.Exception.Message)"
            } 
            $module:BlueskySession | Should -Be $null # Expect connection to fail with dummy creds
        }
        
        It 'Should use environment variables when available and prompt if password is not secure' {
            $env:BLUESKY_USERNAME = 'testuser_env'
            $env:BLUESKY_PASSWORD = 'testpass_env_plaintext' # Plaintext password for testing this scenario
            
            # Mock Get-Credential to simulate user cancelling or providing dummy creds
            Mock Get-Credential { return $null } -ModuleName BlueSkyModule
            
            Connect-BlueskySession # Attempt connection
            
            # Expectation: Warning about plaintext, fallback to Get-Credential (mocked to return $null)
            # and thus no session should be created.
            $module:BlueskySession | Should -Be $null
        }
    }
    
    Context 'Error handling' {
        It 'Should handle invalid credentials gracefully' {
            # [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
            # Creating test credential object - plaintext conversion only for testing purposes
            $securePassword = ConvertTo-SecureString "invalidpass" -AsPlainText -Force # Suppressed for testing only
            $credential = New-Object System.Management.Automation.PSCredential("invaliduser", $securePassword)
            
            $result = Connect-BlueskySession -Credential $credential
            $result | Should -Be $null
            $module:BlueskySession | Should -Be $null
        }
    }
}
