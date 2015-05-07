Import-Module PSGit -Force

Given "a new repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    Write-Verbose "New repository in $repo"
    # TODO: replace with PSGit native commands
    git init
}

When "Get-Status is called" {
    $result = Get-Status
}

Then "the returned object should show" {
    param($Table)
    Write-Verbose ($Table | Out-String)

    Pop-Location
    [Environment]::CurrentDirectory = $Pwd

    foreach($Property in $Table | Get-Member -Type Properties | % Name) {
        $result | Must $Property -Eq $Table.$Property
    }
}