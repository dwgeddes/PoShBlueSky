@{
    # Script module or binary module file associated with this manifest
    RootModule = 'BlueSkyModule.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'e2b7c1e2-1c2b-4e2a-9b2a-123456789abc'

    # Author of this module
    Author = 'PSBlueSky Development Team'

    # Company or vendor of this module
    CompanyName = 'Open Source'

    # Copyright statement for this module
    Copyright = '(c) 2024 PSBlueSky Development Team. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A comprehensive PowerShell module for interacting with the Bluesky social network via the AT Protocol. Provides cmdlets for posting, searching, social interactions, and account management.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module - only include implemented functions
    FunctionsToExport = @(
        'Add-BlueskyBlockedUser',
        'Add-BlueskyFollowedUser', 
        'Add-BlueskyLike',
        'Add-BlueskyMutedUser',
        'Connect-BlueskySession',
        'Disconnect-BlueskySession',
        'Get-BlueskyFollowedUser',
        'Get-BlueskyFollower',
        'Get-BlueskyNotification',
        'Get-BlueskyProfile',
        'Get-BlueskyReply',
        'Get-BlueskySession',
        'Get-BlueskyTimeline',
        'New-BlueskyPost',
        'Remove-BlueskyBlockedUser',
        'Remove-BlueskyFollowedUser',
        'Remove-BlueskyLike',
        'Remove-BlueskyMutedUser',
        'Remove-BlueskyPost',
        'Search-BlueskyPost',
        'Update-BlueskyProfile',
        'Update-BlueskySession'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module  
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Required modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module to aid in module discovery
            Tags = @('Bluesky', 'Social', 'API', 'AT-Protocol', 'Decentralized', 'Microblogging', 'SocialMedia')
            
            # A URL to the license for this module
            LicenseUri = 'https://github.com/yourrepo/PSBlueSky/blob/main/LICENSE'
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/yourrepo/PSBlueSky'
            
            # A URL to an icon representing this module
            IconUri = 'https://github.com/yourrepo/PSBlueSky/blob/main/icon.png'
            
            # Indicates this is a prerelease version of the module
            Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
            
            # Release notes for this version of the module
            ReleaseNotes = @'
Version 1.0.0: Professional release with comprehensive functionality
- Complete session management with automatic token refresh
- Full social interaction support (follow, like, block, mute)
- Robust posting with image support (files and base64)
- Advanced search and timeline retrieval
- Comprehensive error handling and user feedback
- Professional PowerShell standards compliance
- User-friendly output objects with clean property names
- Extensive documentation and examples
'@
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/yourrepo/PSBlueSky/blob/main/docs/'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = ''
}
