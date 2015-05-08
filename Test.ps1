param([Switch]$Quiet)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\lib\Pester -Force

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1
$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion

Import-Module $Release\PSGit.psd1

$Results = Invoke-Gherkin $Pwd\test -ExcludeTag wip -CodeCoverage "$Release\*.ps[m1]*" -PassThru -Quiet:$Quiet
if($Results.FailedCount -gt 0) {
    throw "Failed: '$($Results.FailedScenarios.Name -join "', '")'"
}