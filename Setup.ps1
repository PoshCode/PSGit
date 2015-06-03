#Requires -Version "4.0" -Module PackageManagement
#.Notes
#      if you don't have PackageManagement, you can use nuget instead:
#      nuget install libgit2sharp -OutputDirectory .\packages -ExcludeVersion
[CmdletBinding()]
param(
    [Alias("PSPath")]
    [string]$Path = $PSScriptRoot,
    [string]$ModuleName = $(Split-Path $Path -Leaf)
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Write-Host "SETUP $ModuleName in $Path"

if(Test-Path (Join-Path $Path packages.config)) {
    if(!($Name = Get-PackageSource | ? Location -eq 'https://www.nuget.org/api/v2' | % Name)) {
        Write-Warning "Adding NuGet package source"
        $Name = Register-PackageSource NuGet -Location 'https://www.nuget.org/api/v2' -ForceBootstrap -ProviderName NuGet | % Name
    }
    $null = mkdir $Path\packages\ -Force

    # This recreates nuget's package restore, but hypothetically, with support for any provider
    # E.g.: nuget restore -PackagesDirectory "$Path\packages" -PackageSaveMode nuspec
    foreach($Package in ([xml](gc .\packages.config)).packages.package) {
        Write-Verbose "Installing $($Package.id) v$($Package.version) from $($Package.Source)"
        $install = Install-Package -Name $Package.id -RequiredVersion $Package.version -Source $Package.Source -Destination $Path\packages -PackageSave nuspec -Force -ErrorVariable failure
        if($failure) {
            throw "Failed to install $($package.id), see errors above."
        }
    }
}

git submodule update --init --recursive