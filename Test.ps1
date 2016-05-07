[CmdletBinding()]
param(
    [Alias("PSPath")]
    [string]$Path = $PSScriptRoot,
    [string]$ModuleName = $(Split-Path $Path -Leaf),

    [Switch]$SkipBuild,

    [Switch]$Quiet,

    [Switch]$ShowWip,

    $FailLimit=0,
    
    [ValidateNotNullOrEmpty()]    
    [String]$JobID = ${Env:APPVEYOR_JOB_ID},

    [Nullable[int]]$RevisionNumber = ${Env:APPVEYOR_BUILD_NUMBER},

    [ValidateNotNullOrEmpty()]
    [String]$CodeCovToken = ${ENV:CODECOV_TOKEN}
)
$TestPath = Join-Path $Path Test
$SourcePath = Join-Path $Path src
$OutputPath = Join-Path $Path output
$null = mkdir $OutputPath -Force

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Verbose "Import-Module $PSScriptRoot\lib\Pester" -Verbose:(!$Quiet)
Import-Module $PSScriptRoot\lib\Pester -Force
if(!$SkipBuild) {
    &"$PSScriptRoot\Build.ps1" -Path:$Path -ModuleName:$ModuleName -RevisionNumber:$RevisionNumber
}

Write-Host "TESTING: $ModuleName with $Path\Test"

$Version = &"${PSScriptRoot}\Get-Version.ps1" -Module (Join-Path $Path\src "${ModuleName}.psd1") -DevBuild:$RevisionNumber -RevisionNumber:$RevisionNumber
$ReleasePath = Join-Path $Path $Version

Write-Verbose "TESTING $ModuleName v$Version" -Verbose:(!$Quiet)
Remove-Module $ModuleName -ErrorAction SilentlyContinue

$Options = @{
    OutputFormat = "NUnitXml"
    OutputFile = (Join-Path $OutputPath TestResults.xml)
}
if($Quiet) { $Options.Quiet = $Quiet }
if(!$ShowWip){ $Options.ExcludeTag = @("wip") }

Set-Content "$Path\Test\.Do.Not.COMMIT.This.Steps.ps1" "Import-Module $ReleasePath\${ModuleName}.psd1 -Force"

# Show the commands they would have to run to get these results:
Write-Host $(prompt) -NoNewLine
Write-Host Import-Module $ReleasePath\${ModuleName}.psd1 -Force
Write-Host $(prompt) -NoNewLine
Write-Host Invoke-Gherkin -Path $TestPath -CodeCoverage "$ReleasePath\*.ps[m1]*" -PassThru @Options

$TestResults = Invoke-Gherkin -Path $TestPath -CodeCoverage "$ReleasePath\*.ps[m1]*" -PassThru @Options

Remove-Module $ModuleName -ErrorAction SilentlyContinue
Remove-Item "$Path\Test\.Do.Not.COMMIT.This.Steps.ps1"

$script:failedTestsCount = 0
$script:passedTestsCount = 0
foreach($result in $TestResults)
{
    if($result -and $result.CodeCoverage.NumberOfCommandsAnalyzed -gt 0)
    {
        $script:failedTestsCount += $result.FailedCount 
        $script:passedTestsCount += $result.PassedCount 
        $CodeCoverageTitle = 'Code Coverage {0:F1}%'  -f (100 * ($result.CodeCoverage.NumberOfCommandsExecuted / $result.CodeCoverage.NumberOfCommandsAnalyzed))

        # Map file paths, e.g.: \1.0 back to \src
        for($i=0; $i -lt $TestResults.CodeCoverage.HitCommands.Count; $i++) {
            $TestResults.CodeCoverage.HitCommands[$i].File = $TestResults.CodeCoverage.HitCommands[$i].File.Replace($ReleasePath, $SourcePath)
        }
        for($i=0; $i -lt $TestResults.CodeCoverage.MissedCommands.Count; $i++) {
            $TestResults.CodeCoverage.MissedCommands[$i].File = $TestResults.CodeCoverage.MissedCommands[$i].File.Replace($ReleasePath, $SourcePath)
        }

        if($result.CodeCoverage.MissedCommands.Count -gt 0) {
            $result.CodeCoverage.MissedCommands |
                ConvertTo-Html -Title $CodeCoverageTitle | 
                Out-File (Join-Path $OutputPath "CodeCoverage-${Version}.html")
        }
        if(${CodeCovToken})
        {
            Write-Verbose "Sending CI Code-Coverage Results" -Verbose:(!$Quiet)
            $response = &"$TestPath\Send-CodeCov" -CodeCoverage $result.CodeCoverage -RepositoryRoot $Path -OutputPath $OutputPath -Token ${CodeCovToken}
            Write-Verbose $response.message -Verbose:(!$Quiet)
        }
    }
}

if(Get-Command Add-AppveyorCompilationMessage -ErrorAction SilentlyContinue) { 
    Add-AppveyorCompilationMessage -Message ("{0} of {1} tests passed" -f @($TestResults.PassedScenarios).Count, (@($TestResults.PassedScenarios).Count + @($TestResults.FailedScenarios).Count)) -Category $(if(@($TestResults.FailedScenarios).Count -gt 0) { "Warning" } else { "Information"})
    Add-AppveyorCompilationMessage -Message ("{0:P} of code covered by tests" -f ($TestResults.CodeCoverage.NumberOfCommandsExecuted / $TestResults.CodeCoverage.NumberOfCommandsAnalyzed)) -Category $(if($TestResults.CodeCoverage.NumberOfCommandsExecuted -lt $TestResults.CodeCoverage.NumberOfCommandsAnalyzed) { "Warning" } else { "Information"})
}

if(${JobID}) {
    if(Test-Path $Options.OutputFile) {
        Write-Verbose "Sending Test Results to AppVeyor backend" -Verbose:(!$Quiet)
        $wc = New-Object 'System.Net.WebClient'
        $response = $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/${JobID}", $Options.OutputFile)
        Write-Verbose ([System.Text.Encoding]::ASCII.GetString($response)) -Verbose:(!$Quiet)
    } else {
        Write-Warning "Couldn't find Test Output: $($Options.OutputFile)"
    }
}

if($FailedTestsCount -gt $FailLimit) {
    $exception = New-Object AggregateException "Failed Scenarios:`n`t`t'$($TestResults.FailedScenarios.Name -join "'`n`t`t'")'"
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, "FailedScenarios", "LimitsExceeded", $Results
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

