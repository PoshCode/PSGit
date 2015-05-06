#Requires -Version "4.0"
if(!(Get-Module PackageManagement)) {
    throw "The PackageManagement module is required"
}

if(!(Test-Path Variable:global:LibGit2Sharp) -or !(Test-Path $global:LibGit2Sharp)) {
    $global:LibGit2Sharp = Resolve-Path $PSScriptRoot\bin\libgit2sharp\lib\*\LibGit2Sharp.dll -ErrorAction SilentlyContinue
}

if(!$global:LibGit2Sharp) {
    if(!($Name = Get-PackageSource | ? Location -eq 'https://www.nuget.org/api/v2' | % Name)) {
       $Name = Register-PackageSource NuGet -Location 'https://www.nuget.org/api/v2' -ForceBootstrap -ProviderName NuGet | % Name
    }
    $null = mkdir $PSScriptRoot\bin\ -Force
    $package = Install-Package libgit2sharp -Source NuGet -Destination $PSScriptRoot\bin -ExcludeVersion -PackageSave nuspec -Force

    if(!$package) {
        throw "Failed to install libgit2sharp assembly"
    }

    $global:LibGit2Sharp = Resolve-Path $PSScriptRoot\bin\libgit2sharp\lib\*\LibGit2Sharp.dll -ErrorAction SilentlyContinue
}

Get-ChildItem $PSScriptRoot\bin\libgit2sharp\lib\*\*
