[CmdletBinding()]
param(
    [Alias("PSPath")]
    [string]$Path = $PSScriptRoot,
    [string]$ModuleName = $(Split-Path $Path -Leaf),
    # The target framework for .net (for packages), with fallback versions
    # The default supports PS3:  "net40","net35","net20","net45"
    # To only support PS4, use:  "net45","net40","net35","net20"
    # To support PS2, you use:   "net35","net20"
    [string[]]$TargetFramework = @("net40","net35","net20","net45"),
    [switch]$Monitor,
    [Nullable[int]]$RevisionNumber = ${Env:APPVEYOR_BUILD_NUMBER}
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Write-Host "BUILDING: $ModuleName from $Path"

$OutputPath = Join-Path $Path output
$null = mkdir $OutputPath -Force

# If the RevisionNumber is specified as ZERO, this is a release build
$Version = &"${PSScriptRoot}\Get-Version.ps1" -Module (Join-Path $Path\src "${ModuleName}.psd1") -DevBuild:$RevisionNumber -RevisionNumber:$RevisionNumber
$ReleasePath = Join-Path $Path $Version

Write-Verbose "OUTPUT Release Path: $ReleasePath"
if(Test-Path $ReleasePath) {
Write-Verbose "       Clean up old build"
    Write-Verbose "DELETE $ReleasePath\"
    Remove-Item $ReleasePath -Recurse -Force -ErrorAction SilentlyContinue
}

## Find dependency Package Files
Write-Verbose "       Copying Packages"
foreach($Package in ([xml](Get-Content (Join-Path $Path packages.config))).packages.package) {
    $folder = Join-Path $Path "packages\$($Package.id)*"
    # Check for each TargetFramework, in order of preference, fall back to using the lib folder
    $targets = ($TargetFramework -replace '^','lib\') + 'lib' | ForEach-Object { Join-Path $folder $_ }
    $PackageSource = Get-Item $targets -ErrorAction SilentlyContinue | Select -First 1 -Expand FullName
    if(!$PackageSource) {
        throw "Could not find a lib folder for $($Package.id) from package. You may need to run Setup.ps1"
    }

    Write-Verbose "COPY   $PackageSource\"
    $null = robocopy $PackageSource $ReleasePath\lib /MIR /NP /LOG:"$OutputPath\build.log" /R:2 /W:15
    if($LASTEXITCODE -gt 1) {
        throw "Failed to copy Package $($Package.id) (${LASTEXITCODE}), see build.log for details"
    }
}

## Copy PowerShell source Files
Write-Verbose "       Copying Module Source"
Write-Verbose "COPY   $Path\src\"
$null = robocopy $Path\src\  $ReleasePath /E /NP /LOG+:"$OutputPath\build.log" /R:2 /W:15
if($LASTEXITCODE -ne 3) {
    throw "Failed to copy Module (${LASTEXITCODE}), see build.log for details"
}
## Touch the PSD1 Version:
Write-Verbose "       Update Module Version"
$ReleaseManifest = Join-Path $ReleasePath "${ModuleName}.psd1"
Set-Content $ReleaseManifest ((Get-Content $ReleaseManifest) -Replace "^(\s*)ModuleVersion\s*=\s*'?[\d\.]+'?\s*`$", "`$1ModuleVersion = '$Version'")


## TODO: Use Grunt or write something native to handle this
#        The robocopy solution has a resolution of 1 minute...
if($Monitor) {
    Write-Verbose "MONITOR Path: $Path"
    Start-Job -Name "${ModuleName}Build" {
        param($ReleasePath, $SourcePath=$(Split-Path $ReleasePath))
        Set-Location $SourcePath
        [Environment]::CurrentDirectory = $SourcePath
        robocopy $SourcePath\src\ $ReleasePath /E /NP /MON:1 /R:5 /W:15
        if($LASTEXITCODE -gt 1) {
            Write-Error "Failed to copy Module (${LASTEXITCODE}), see build.log for details"
        }
    } -ArgumentList $ReleasePath
}
