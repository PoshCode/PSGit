[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "PACKAGING $($PSGit.ModuleVersion) build $ENV:APPVEYOR_BUILD_VERSION"

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion

Write-Verbose "COPY   $Release\"
$null = robocopy $Release .\PSGit /MIR /NP /LOG+:build.log

$zipFile = Join-Path $Pwd PSGit.zip
Add-Type -assemblyname System.IO.Compression.FileSystem

Write-Verbose "ZIP    $zipFile"
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $Pwd PSGit), $zipFile)

# You can add other artifacts here
ls $zipFile
ls build.log
