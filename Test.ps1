[CmdletBinding()]
param([Switch]$Quiet, $FailLimit=0)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Verbose "Import-Module $PSScriptRoot\lib\Pester" -Verbose:(!$Quiet)
Import-Module $PSScriptRoot\lib\Pester -Force

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
Write-Verbose "TESTING $($PSGit.ModuleVersion) build $ENV:APPVEYOR_BUILD_VERSION" -Verbose:(!$Quiet)

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion

Write-Verbose "Import-Module $Release\PSGit.psd1" -Verbose:(!$Quiet)
Import-Module $Release\PSGit.psd1

$Results = Invoke-Gherkin $Pwd\test -ExcludeTag wip -CodeCoverage "$Release\*.ps[m1]*" -PassThru -Quiet:$Quiet

if($Results.FailedCount -gt $FailLimit) {
    $exception = New-Object AggregateException "Failed Scenarios:`n`t`t'$($Results.FailedScenarios.Name -join "'`n`t`t'")'"
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, "FailedScenarios", "LimitsExceeded", $Results
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}
