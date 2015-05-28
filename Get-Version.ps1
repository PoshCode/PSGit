#.Synopsis
# Calculate the build number.
param(
    $Module,
    # If set, override the module's revision
    [Nullable[int]]$RevisionNumber
)

[Version]$Version = if(Test-Path $Module -Type Leaf) {
    (Import-LocalizedData -BaseDirectory (Split-Path $Module) -FileName (Split-Path ${Module} -Leaf)).ModuleVersion
} elseif(Test-Path $Module -Type Container) {
    (Import-LocalizedData -BaseDirectory $Module -FileName "$(Split-Path ${Module} -Leaf).psd1").ModuleVersion 
} else {
    Get-Module $Module -List | Select -First 1 -Expand Version 
}

if($RevisionNumber) {
    # For release builds we don't increment the build number
    $Build = if($Version.Build -le 0) { 0 } else { $Version.Build }
} else {
    # For dev builds, assume we're working on the NEXT release
    $Build = if($Version.Build -le 0) { 1 } else { $Version.Build + 1}
}

if([string]::IsNullOrEmpty($RevisionNumber)) {
    New-Object Version $Version.Major, $Version.Minor, $Build
} else {
    New-Object Version $Version.Major, $Version.Minor, $Build, $RevisionNumber
}
