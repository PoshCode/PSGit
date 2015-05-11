[CmdletBinding()]
param()
$OutputPath = Join-Path $PSScriptRoot output
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "PACKAGING $($PSGit.ModuleVersion) build $ENV:APPVEYOR_BUILD_VERSION"

$Release = Join-Path $OutputPath $PSGit.ModuleVersion

Write-Verbose "COPY   $Release\"
$null = robocopy $Release $OutputPath\PSGit /MIR /NP /LOG+:build.log

$zipFile = Join-Path $OutputPath PSGit.zip
Add-Type -assemblyname System.IO.Compression.FileSystem

Write-Verbose "ZIP    $zipFile"
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $OutputPath PSGit), $zipFile)

# You can add other artifacts here
ls build.log
ls OutputPath