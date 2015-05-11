[CmdletBinding()]
param(
    [Switch]$Quiet,
    [Switch]$ShowWip,
    $FailLimit=0
)
$TestPath = Join-Path $PSScriptRoot Test
$OutputPath = Join-Path $PSScriptRoot output
$SourcePath = Join-Path $PSScriptRoot src

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Verbose "Import-Module $PSScriptRoot\lib\Pester" -Verbose:(!$Quiet)
Import-Module $PSScriptRoot\lib\Pester -Force

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "TESTING $($PSGit.ModuleVersion) build $ENV:APPVEYOR_BUILD_VERSION" -Verbose:(!$Quiet)

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion

if(!(Test-Path $OutputPath)) {
    $null = mkdir $OutputPath -Force
}

Write-Verbose "Import-Module $Release\PSGit.psd1" -Verbose:(!$Quiet)
Import-Module $Release\PSGit.psd1

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
    if($result)
    {
        $script:failedTestsCount += $result.FailedCount 
        $script:passedTestsCount += $result.PassedCount 
        $CodeCoverageTitle = 'Code Coverage {0:F1}%'  -f (100 * ($result.CodeCoverage.NumberOfCommandsExecuted / $result.CodeCoverage.NumberOfCommandsAnalyzed))

        if($result.CodeCoverage.MissedCommands.Count -gt 0) {
            $result.CodeCoverage.MissedCommands |
                ConvertTo-FormattedHtml -title $CodeCoverageTitle | 
                Out-File (Join-Path $OutputPath "CodeCoverage-${ENV:APPVEYOR_BUILD_VERSION}.html")
        }
        if(${ENV:CodeCovIoToken})
        {
            Write-Verbose "Sending CI Code-Coverage Results"
            $output = &"$TestPath\Send-CodeCov" -CodeCoverage $result.CodeCoverage -RepositoryRoot $PSScriptRoot -OutputPath $OutputPath -token ${ENV:CodeCovIoToken}
            Write-Verbose $ouput.message
        }
    }
}

if(${ENV:APPVEYOR_JOB_ID} -and (Test-Path $Options.OutputFile)) {
    $wc = New-Object 'System.Net.WebClient'
    $result = $wc.UploadFile("https://ci.appveyor.com/api/testresults/xunit/${ENV:APPVEYOR_JOB_ID}", $Options.OutputFile)
}

if($FailedTestsCount -gt $FailLimit) {
    $exception = New-Object AggregateException "Failed Scenarios:`n`t`t'$($TestResults.FailedScenarios.Name -join "'`n`t`t'")'"
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, "FailedScenarios", "LimitsExceeded", $Results
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

