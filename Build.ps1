[CmdletBinding()]
param([switch]$Monitor)

$OutputPath = Join-Path $PSScriptRoot output
$null = mkdir $OutputPath -Force

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion
if(Test-Path $Release) {
    Write-Verbose "DELETE $Release\"
    rm $Release -Recurse -Force -ErrorAction SilentlyContinue
}

## Find Library Files
if(!(Test-Path Variable:global:LibGit2Sharp) -or !(Test-Path $global:LibGit2Sharp)) {
    $global:LibGit2Sharp = Resolve-Path $PSScriptRoot\packages\libgit2sharp\lib\*\LibGit2Sharp.dll -ErrorAction SilentlyContinue
}

## Copy Library Files
$LibSource = $(Split-Path $global:LibGit2Sharp)
Write-Verbose "COPY   $LibSource\"
$null = robocopy $LibSource $Release\lib /MIR /NP /LOG:"$OutputPath\build.log"
if($LASTEXITCODE -gt 1) {
    throw "Failed to copy Libraries (${LASTEXITCODE}), see build.log for details"
}
## Copy Source Files
Write-Verbose "COPY   $PSScriptRoot\src\"
$null = robocopy $PSScriptRoot\src\  $Release /E /NP /LOG+:"$OutputPath\build.log"
if($LASTEXITCODE -ne 3) {
    throw "Failed to copy Module (${LASTEXITCODE}), see build.log for details"
}

## TODO: Use Grunt or write something native to handle this
#        The robocopy solution has a resolution of 1 minute...
if($Monitor) {
    Start-Job -Name PSGitBuild {
        param($ReleasePath, $SourcePath=$(Split-Path $ReleasePath))
        Set-Location $SourcePath
        [Environment]::CurrentDirectory = $SourcePath
        robocopy $SourcePath\src\ $ReleasePath /E /NP /MON:1
    } -ArgumentList $Release
}
