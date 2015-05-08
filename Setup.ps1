#Requires -Version "4.0" -Module PackageManagement
#NOTE: if you don't have PackageManagement, you can use nuget instead:
#      nuget install libgit2sharp -OutputDirectory .\packages -ExcludeVersion
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if(!(Test-Path Variable:global:LibGit2Sharp) -or !(Test-Path $global:LibGit2Sharp)) {
    $global:LibGit2Sharp = Resolve-Path $PSScriptRoot\packages\libgit2sharp\lib\*\LibGit2Sharp.dll -ErrorAction SilentlyContinue
}

if(!$global:LibGit2Sharp) {
    if(!($Name = Get-PackageSource | ? Location -eq 'https://www.nuget.org/api/v2' | % Name)) {
       $Name = Register-PackageSource NuGet -Location 'https://www.nuget.org/api/v2' -ForceBootstrap -ProviderName NuGet | % Name
    }
    $null = mkdir $PSScriptRoot\packages\ -Force
    $package = Install-Package libgit2sharp -Source NuGet -Destination $PSScriptRoot\packages -ExcludeVersion -PackageSave nuspec -Force

    if(!$package) {
        throw "Failed to install libgit2sharp assembly"
    }

    $global:LibGit2Sharp = Resolve-Path $PSScriptRoot\packages\libgit2sharp\lib\*\LibGit2Sharp.dll -ErrorAction SilentlyContinue
}

Get-ChildItem $PSScriptRoot\packages\libgit2sharp\lib\*\*