[CmdletBinding()]
param(
    [switch]$TagFeatures,

    [string]$TestFolder = "~\projects\TestVersions",

    $Source
)
if ($DebugPreference -ne "SilentlyContinue") {
    $DebugPreference = "Continue"
}
if(!$Source) {
    $Source = if ($PSScriptRoot) {
        $PSScriptRoot
    } else {
        "~\Projects\Modules\PSGit\Examples"
    }
}

function Test-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Version
    )

    try {
        GitVersion | ConvertFrom-Json -ov Result | % {
            Write-Host "Informational: " $_.InformationalVersion -Fore DarkCyan
        }
    # JSON parse errors should stop everything
    } catch {
        Write-Warning "Error parsing GitVersion output:"
        GitVersion | Out-Host
        throw $_
    }
    if(($Version -split '\.').Count -eq 3) {
        $Version = "$Version.0"
    }

    if ($Result.AssemblySemVer -ne $Version) {
        Write-Warning "Expected $Version but got $($Result.AssemblySemVer)"
        if($DebugPreference -ne "SilentlyContinue") {
            $Result | Out-String | Write-Debug
            Wait-Debugger
        }
    } else {
        Write-Host "AssemblySemVer: $($Result.AssemblySemVer)" -Fore Green
    }
}

function New-Commit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Version,
        $File = "touch"
    )

    Add-Content -Path "$File.log" -Value $Version -Encoding UTF8

    git add *
    git commit -m "Want $Version"
    sleep -milli 100
}

## reset
gi $TestFolder -ea 0 | rm -Recurse -Force -ea 0
mkdir $TestFolder -ea 0
sl $TestFolder -ea stop

## Set up your project:
## Set up git
git init
## Set up GitVersion
cp $Source\GitVersion.yml
git add *
## Set up a first commit
git commit -m "Initial commit"
## Until you tag or put the version in the yaml, the previous version is 0.0.0
Test-Version 0.1.0.0

# Manually set the version by tagging
$NewVersion = "18.5.0"
git tag $NewVersion
Test-Version $NewVersion

# At this point, the "NEXT" release will probably be 18.6.0

## Now imagine DEV1 starts a feature
git branch features/one
git checkout features/one

## We would like each feature to increment the patch: Major.Minor.PATCH
$NewVersion = "18.6.1"
Set-Content Readme.md "Testing versions"
New-Commit $NewVersion -File one
if ($TagFeatures) {
    ## As a test, tag feature branches
    git tag $NewVersion
}
Test-Version $NewVersion

## And DEV2 starts a feature

git checkout master
git branch features/two
git checkout features/two

$NewVersion = "18.6.2"
New-Commit $NewVersion -File two
if ($TagFeatures) {
    ## As a test, tag feature branches
    git tag $NewVersion
}
Test-Version $NewVersion

$NewVersion = "18.6.2.1"
New-Commit $NewVersion -File two
Test-Version $NewVersion

git checkout features/one

## But what we want is for each commit to increment only the build: Major.Minor.Patch.BUILD
## The SemVer should be: 18.6.1+1 (but we use the AssemblyVersion)
$NewVersion = "18.6.1.1"
New-Commit $NewVersion -File one
Test-Version $NewVersion

git checkout features/two

$NewVersion = "18.6.2.2"
New-Commit $NewVersion -File two
Test-Version $NewVersion

## And DEV2 finishes, and merges to master
$NewVersion = "18.6.3"
git checkout master
git merge --no-ff -m "Want $NewVersion (merge two)" features/two
git branch -d features/two
Test-Version $NewVersion

## And DEV3 starts a feature
git checkout master
git branch features/three
git checkout features/three

$NewVersion = "18.6.4"
New-Commit $NewVersion -File three
if ($TagFeatures) {
    ## As a test, tag feature branches
    git tag $NewVersion
}
Test-Version $NewVersion

$NewVersion = "18.6.4.1"
New-Commit $NewVersion -File three
Test-Version $NewVersion

## And DEV1 does some more work
git checkout features/one

$NewVersion = "18.6.1.2"
New-Commit $NewVersion -File one
Test-Version $NewVersion

## And DEV1 finishes, and merges to master
$NewVersion = "18.6.5"
git checkout master
git merge --no-ff -m "Want $NewVersion (merge one)" features/one
git branch -d features/one
Test-Version $NewVersion

## RANDOM COMMIT ON MASTER
$NewVersion = "18.6.6"
New-Commit $NewVersion -File one
Test-Version $NewVersion

## RELEASE BRANCH
$Release = $NewVersion = "18.6.7"
git branch releases/$NewVersion
git checkout releases/$NewVersion
New-Commit $NewVersion
Test-Version $NewVersion

## COMMIT ON RELEASE
$NewVersion = "18.6.7"
New-Commit $NewVersion
Test-Version $NewVersion

if($StopEarly) {
    return
}

## And DEV2 starts a new feature
git checkout master
git branch features/two
git checkout features/two

$NewVersion = "18.6.8"
New-Commit $NewVersion -File two
if ($TagFeatures) {
    ## As a test, tag feature branches
    git tag $NewVersion
}
Test-Version $NewVersion

$NewVersion = "18.6.8.1"
New-Commit $NewVersion -File two
Test-Version $NewVersion

## Finish RELEASE
$NewVersion = $Release -split "\." | % {$i=0; $a=@()} { $i += 1; if($i -eq 3){ $a += @(([int]$_) + 1) }else{ $a += @($_) } } { $a -join "." }
git checkout releases/$Release
git tag $NewVersion
Test-Version $NewVersion
git checkout master
git merge --no-ff -m "Want $NewVersion (merge $NewVersion)" releases/$Release
git branch -d releases/$Release

## And DEV3 finishes, and merges to master ??
$NewVersion = "18.7.1"
git checkout master
git merge --no-ff -m "Want $NewVersion (merge three)" features/three
git branch -d features/three
Test-Version $NewVersion
