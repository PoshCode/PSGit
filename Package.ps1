[CmdletBinding()]
param(
    [Alias("PSPath")]
    [string]$Path = $PSScriptRoot,

    [string]$ModuleName = $(Split-Path $Path -Leaf),

    [Nullable[int]]$RevisionNumber = ${Env:APPVEYOR_BUILD_NUMBER}
)
$OutputPath = Join-Path $Path output
$null = mkdir $OutputPath -Force

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Write-Host "TESTING: $ModuleName with $Path\Test"

$Version = &"${PSScriptRoot}\Get-Version.ps1" -Module (Join-Path $Path\src "${ModuleName}.psd1") -DevBuild:$RevisionNumber -RevisionNumber:$RevisionNumber
$ReleasePath = Join-Path $Path $Version

Write-Verbose "COPY   $ReleasePath\"
$null = robocopy $ReleasePath "${OutputPath}\${ModuleName}" /MIR /NP /LOG+:"$OutputPath\build.log"

$zipFile = Join-Path $OutputPath "${ModuleName}-${Version}.zip"
Add-Type -assemblyname System.IO.Compression.FileSystem
Remove-Item $zipFile -ErrorAction SilentlyContinue
Write-Verbose "ZIP    $zipFile"
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $OutputPath $ModuleName), $zipFile)

# You can add other artifacts here
ls $OutputPath -File