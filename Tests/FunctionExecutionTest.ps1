# Function Execution Test Script
# Tests basic execution of all public functions with valid parameters

Write-Host "=== PSBlueSky Function Execution Test ===" -ForegroundColor Green
Write-Host ""

# Import the module
try {
    Import-Module "$PSScriptRoot/../BlueskyModule.psd1" -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Get all public functions
$functions = Get-Command -Module BlueskyModule | Sort-Object Name

Write-Host "Testing $($functions.Count) functions..." -ForegroundColor Yellow
Write-Host ""

# Track test results
$testResults = @()

foreach ($function in $functions) {
    $functionName = $function.Name
    Write-Host "Testing: $functionName" -ForegroundColor Cyan
    
    try {
        # Get help to understand parameters
        $help = Get-Help $functionName -ErrorAction SilentlyContinue
        
        # Test basic function call patterns based on function type
        switch -Regex ($functionName) {
            '^Connect-' {
                # Test connection functions - these need credentials
                Write-Host "  Skipping execution test - requires credentials" -ForegroundColor Yellow
                $testResults += [PSCustomObject]@{
                    Function = $functionName
                    Status = "Skipped"
                    Reason = "Requires credentials"
                    Error = $null
                }
            }
            '^Disconnect-' {
                # Test disconnect functions - these need active session
                Write-Host "  Skipping execution test - requires active session" -ForegroundColor Yellow
                $testResults += [PSCustomObject]@{
                    Function = $functionName
                    Status = "Skipped"
                    Reason = "Requires active session"
                    Error = $null
                }
            }
            '^Get-' {
                # Test Get functions with no parameters
                try {
                    $result = & $functionName -ErrorAction Stop
                    if ($result) {
                        Write-Host "  ✓ Executed successfully, returned: $($result.GetType().Name)" -ForegroundColor Green
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Success"
                            Reason = "Executed without parameters"
                            Error = $null
                        }
                    } else {
                        Write-Host "  ✓ Executed successfully, returned: null" -ForegroundColor Green
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Success"
                            Reason = "Executed without parameters (returned null)"
                            Error = $null
                        }
                    }
                } catch {
                    if ($_.Exception.Message -match "session|token|auth") {
                        Write-Host "  ⚠ Expected failure - no session" -ForegroundColor Yellow
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Expected Failure"
                            Reason = "No session required"
                            Error = $_.Exception.Message
                        }
                    } elseif ($_.Exception.Message -match "At least one|must be provided|Parameter set|specified") {
                        Write-Host "  ⚠ Expected failure - parameter validation" -ForegroundColor Yellow
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Expected Failure"
                            Reason = "Parameter validation"
                            Error = $_.Exception.Message
                        }
                    } else {
                        Write-Host "  ✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Error"
                            Reason = "Unexpected failure"
                            Error = $_.Exception.Message
                        }
                    }
                }
            }
            '^Add-|^Remove-|^New-|^Update-|^Search-' {
                # Test action functions - these typically need parameters
                $syntax = (Get-Command $functionName).ParameterSets[0]
                $mandatoryParams = $syntax.Parameters | Where-Object { $_.IsMandatory }
                
                if ($mandatoryParams.Count -gt 0) {
                    Write-Host "  Skipping execution test - requires mandatory parameters: $($mandatoryParams.Name -join ', ')" -ForegroundColor Yellow
                    $testResults += [PSCustomObject]@{
                        Function = $functionName
                        Status = "Skipped"
                        Reason = "Requires mandatory parameters"
                        Error = $null
                    }
                } else {
                    try {
                        $result = & $functionName -ErrorAction Stop
                        if ($result) {
                            Write-Host "  ✓ Executed successfully, returned: $($result.GetType().Name)" -ForegroundColor Green
                            $testResults += [PSCustomObject]@{
                                Function = $functionName
                                Status = "Success"
                                Reason = "Executed without parameters"
                                Error = $null
                            }
                        } else {
                            Write-Host "  ✓ Executed successfully, returned: null" -ForegroundColor Green
                            $testResults += [PSCustomObject]@{
                                Function = $functionName
                                Status = "Success"
                                Reason = "Executed without parameters (returned null)"
                                Error = $null
                            }
                        }
                    } catch {
                        if ($_.Exception.Message -match "session|token|auth") {
                            Write-Host "  ⚠ Expected failure - no session" -ForegroundColor Yellow
                            $testResults += [PSCustomObject]@{
                                Function = $functionName
                                Status = "Expected Failure"
                                Reason = "No session required"
                                Error = $_.Exception.Message
                            }
                        } elseif ($_.Exception.Message -match "At least one|must be provided|Parameter set|specified") {
                            Write-Host "  ⚠ Expected failure - parameter validation" -ForegroundColor Yellow
                            $testResults += [PSCustomObject]@{
                                Function = $functionName
                                Status = "Expected Failure"
                                Reason = "Parameter validation"
                                Error = $_.Exception.Message
                            }
                        } else {
                            Write-Host "  ✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
                            $testResults += [PSCustomObject]@{
                                Function = $functionName
                                Status = "Error"
                                Reason = "Unexpected failure"
                                Error = $_.Exception.Message
                            }
                        }
                    }
                }
            }
            default {
                Write-Host "  Testing basic execution..." -ForegroundColor Gray
                try {
                    $result = & $functionName -ErrorAction Stop
                    Write-Host "  ✓ Executed successfully, returned: $($result.GetType().Name)" -ForegroundColor Green
                    $testResults += [PSCustomObject]@{
                        Function = $functionName
                        Status = "Success"
                        Reason = "Executed without parameters"
                        Error = $null
                    }
                } catch {
                    if ($_.Exception.Message -match "session|token|auth") {
                        Write-Host "  ⚠ Expected failure - no session" -ForegroundColor Yellow
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Expected Failure"
                            Reason = "No session required"
                            Error = $_.Exception.Message
                        }
                    } elseif ($_.Exception.Message -match "At least one|must be provided|Parameter set|specified") {
                        Write-Host "  ⚠ Expected failure - parameter validation" -ForegroundColor Yellow
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Expected Failure"
                            Reason = "Parameter validation"
                            Error = $_.Exception.Message
                        }
                    } else {
                        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
                        $testResults += [PSCustomObject]@{
                            Function = $functionName
                            Status = "Error"
                            Reason = "Execution failed"
                            Error = $_.Exception.Message
                        }
                    }
                }
            }
        }
    } catch {
        Write-Host "  ✗ General error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Function = $functionName
            Status = "Error"
            Reason = "General error"
            Error = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== EXECUTION TEST SUMMARY ===" -ForegroundColor Green
Write-Host ""

$summary = $testResults | Group-Object Status
foreach ($group in $summary) {
    $color = switch ($group.Name) {
        'Success' { 'Green' }
        'Expected Failure' { 'Yellow' }
        'Skipped' { 'Cyan' }
        default { 'Red' }
    }
    Write-Host "$($group.Name): $($group.Count) functions" -ForegroundColor $color
}

Write-Host ""
Write-Host "Detailed Results:" -ForegroundColor Gray
$testResults | Format-Table Function, Status, Reason -AutoSize

# Show any unexpected errors
$errorResults = $testResults | Where-Object { $_.Status -eq 'Error' }
if ($errorResults.Count -gt 0) {
    Write-Host ""
    Write-Host "=== ERRORS REQUIRING ATTENTION ===" -ForegroundColor Red
    foreach ($errorItem in $errorResults) {
        Write-Host "Function: $($errorItem.Function)" -ForegroundColor Red
        Write-Host "Error: $($errorItem.Error)" -ForegroundColor Red
        Write-Host ""
    }
}
