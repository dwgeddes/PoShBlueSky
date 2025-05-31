# BlueSkyModule.psm1
# Main module file for BlueSky PowerShell module

# Module-scoped session variable instead of global
$module:BlueskySession = $null

# Import all functions from Public and Private folders
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Export module variable for session management
Export-ModuleMember -Variable BlueskySession
