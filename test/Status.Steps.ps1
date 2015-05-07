Import-Module PSGit -Force

Given "a new repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    Write-Verbose "New repository in $repo"
    # TODO: replace with PSGit native commands
    git init
}

Given "adding (\d+) files" {
    param([int]$count)
    for($f=0; $f-lt$count; $f++){
        New-Item ([io.path]::GetRandomFileName()) -Item File
    }
}

Given "(\d+) files are edited" {
    param([int]$count)

    foreach($file in Get-ChildItem | Get-Random -Count $count){
        Add-Content $file (Get-Date)
    }    
}

When "Get-GitStatus (.*)? ?is called" {
    param($pathspec)
    $result = Get-GitStatus $pathspec
}

When "Add-GitItem (.*)? is called" {
    param($pathspec)
    # TODO: replace with PSGit native commands
    git add --all $pathspec
}

Then "the returned object should show" {
    param($Table)
    Write-Verbose ($Table | Out-String)

    Pop-Location
    [Environment]::CurrentDirectory = $Pwd

    foreach($Property in $Table) {
        $result | Must $Property.Property -Eq $Property.Value
    }
}