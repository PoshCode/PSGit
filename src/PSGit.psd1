@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSGit.psm1'

# Version number of this module.
ModuleVersion = '2.0.3'

# ID used to uniquely identify this module
GUID = 'df52529c-a328-4ee1-b52c-839646292588'

# Author of this module
Author = 'PoshCode Team'

# Company or vendor of this module
CompanyName = 'PoshCode'

# Copyright statement for this module
Copyright = 'Copyright (c) Joel Bennett, Justin Rich 2015'

# Description of the functionality provided by this module
Description = 'A PowerShell implementation of Git, providing a new command-line interface and object pipeline'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName="Configuration"; ModuleVersion="0.9"})

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = 'lib\LibGit2Sharp.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @("PSGit.types.ps1xml")

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @("PSGit.formats.ps1xml")

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'git', 'SourceControl', 'RCS'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PoshCode/PSGit/blob/master/License.md'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PoshCode/PSGit/'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
            Added a PowerLine function
            Upgraded to Configuration 0.9 to get the UTF8 encoding
        '


    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
DefaultCommandPrefix = 'Git'

}
