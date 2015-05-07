#Requires -Version "4.0" -Module PackageManagement

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

## Build -- TODO: use Grunt to keep the build up to date on every save...
$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion
if(Test-Path $Release) {
    rm $Release -Recurse -Force
}
$null = mkdir "$Release" -Force
$null = mkdir "$Release\lib" -Force

## Copy Source Files
Copy-Item "$PSScriptRoot\src\*" -Destination $Release

## Copy Library Files
Copy-Item "$(Split-Path $global:LibGit2Sharp)\*" -Recurse -Destination $Release\lib


## Test 
Import-Module $PSScriptRoot\lib\Pester
Invoke-Gherkin $PSScriptRoot\test