$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PSGit = Import-LocalizedData -BaseDirectory $PSScriptRoot\src -FileName PSGit.psd1

$Release = Join-Path $PSScriptRoot $PSGit.ModuleVersion
if(Test-Path $Release) {
    rm $Release -Recurse -Force -ErrorAction SilentlyContinue
}

## Copy Library Files
$null = robocopy $(Split-Path $global:LibGit2Sharp) $Release\lib /MIR /NP /LOG:build.log
if($LASTEXITCODE -gt 1) {
    throw "Failed to copy Libraries (${LASTEXITCODE}), see build.log for details"
}
## Copy Source Files
## TODO: use /MON:1 on the last robocopy task to keep the build up to date on every save...
$null = robocopy $PSScriptRoot\src\  $Release /E /NP /LOG+:build.log
if($LASTEXITCODE -ne 3) {
    throw "Failed to copy Module (${LASTEXITCODE}), see build.log for details"
}
