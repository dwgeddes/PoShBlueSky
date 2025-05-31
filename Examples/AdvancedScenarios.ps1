<#
.SYNOPSIS
    Fixes BOM encoding for all PowerShell files in the repository.
.DESCRIPTION
    Recursively looks for all .ps1 files and ensures they're saved with UTF-8 BOM encoding,
    which is required to avoid PSUseBOMForUnicodeEncodedFile warning from PSScriptAnalyzer.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$WhatIf
)

# Get all .ps1 files
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1"
Write-Information "Found $($files.Count) PowerShell files" -InformationAction Continue

foreach ($file in $files) {
    Write-Verbose "Processing $($file.FullName)"
    
    # Read the file content
    $content = Get-Content -Path $file.FullName -Raw
    
    if ($WhatIf) {
        Write-Information "Would save $($file.FullName) with UTF-8 BOM encoding" -InformationAction Continue
    } else {
        # Save with UTF-8 BOM encoding
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText("YourFile.ps1", $content, $utf8WithBom)
        Write-Information "Fixed encoding for $($file.FullName)" -InformationAction Continue
    }
}

Write-Information "Encoding fix complete. Run Invoke-ScriptAnalyzer to verify." -InformationAction Continue
