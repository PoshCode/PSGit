[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [String]$BuildVersion = ${Env:APPVEYOR_BUILD_VERSION}
)
$OutputPath = Join-Path $PSScriptRoot output
$null = mkdir $OutputPath -Force

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "PACKAGING $($PSGit.ModuleVersion) build ${BuildVersion}"

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion

Write-Verbose "COPY   $Release\"
$null = robocopy $Release $OutputPath\PSGit /MIR /NP /LOG+:"$OutputPath\build.log"

$zipFile = Join-Path $OutputPath "PSGit-$($PSGit.ModuleVersion).zip"
Add-Type -assemblyname System.IO.Compression.FileSystem
Remove-Item $zipFile -ErrorAction SilentlyContinue
Write-Verbose "ZIP    $zipFile"
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $OutputPath PSGit), $zipFile)

# You can add other artifacts here
ls $OutputPath -File