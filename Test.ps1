[CmdletBinding()]
param(
    [Switch]$Quiet,
    [Switch]$ShowWip,
    $FailLimit=0,
    
    [ValidateNotNullOrEmpty()]    
    [String]$JobID = ${Env:APPVEYOR_JOB_ID},

    [ValidateNotNullOrEmpty()]
    [String]$BuildVersion = ${Env:APPVEYOR_BUILD_VERSION},

    [ValidateNotNullOrEmpty()]
    [String]$CodeCovToken = ${ENV:CODECOV_TOKEN}
)
$TestPath = Join-Path $PSScriptRoot Test
$SourcePath = Join-Path $PSScriptRoot src
$OutputPath = Join-Path $PSScriptRoot output
$null = mkdir $OutputPath -Force

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Verbose "Import-Module $PSScriptRoot\lib\Pester" -Verbose:(!$Quiet)
Import-Module $PSScriptRoot\lib\Pester -Force

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "TESTING $($PSGit.ModuleVersion) build $BuildVersion" -Verbose:(!$Quiet)

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion



Write-Verbose "Import-Module $Release\PSGit.psd1" -Verbose:(!$Quiet)
Import-Module $Release\PSGit.psd1 -Force

$Options = @{
    OutputFormat = "NUnitXml"
    OutputFile = (Join-Path $OutputPath TestResults.xml)
}
if($Quiet) { $Options.Quiet = $Quiet }
if(!$ShowWip){ $Options.ExcludeTag = @("wip") }

$TestResults = Invoke-Gherkin -Path $TestPath -CodeCoverage "$Release\*.ps[m1]*" -PassThru @Options

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
            $TestResults.CodeCoverage.HitCommands[$i].File = $TestResults.CodeCoverage.HitCommands[$i].File.Replace($Release, $SourcePath)
        }
        for($i=0; $i -lt $TestResults.CodeCoverage.MissedCommands.Count; $i++) {
            $TestResults.CodeCoverage.MissedCommands[$i].File = $TestResults.CodeCoverage.MissedCommands[$i].File.Replace($Release, $SourcePath)
        }

        if($result.CodeCoverage.MissedCommands.Count -gt 0) {
            $result.CodeCoverage.MissedCommands |
                ConvertTo-Html -Title $CodeCoverageTitle | 
                Out-File (Join-Path $OutputPath "CodeCoverage-${BuildVersion}.html")
        }
        if(${CodeCovToken})
        {
            Write-Verbose "Sending CI Code-Coverage Results" -Verbose:(!$Quiet)
            $response = &"$TestPath\Send-CodeCov" -CodeCoverage $result.CodeCoverage -RepositoryRoot $PSScriptRoot -OutputPath $OutputPath -Token ${CodeCovToken}
            Write-Verbose $response.message -Verbose:(!$Quiet)
        }
    }
}

if(Get-Command Add-AppveyorCompilationMessage) { 
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

