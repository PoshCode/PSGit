Import-Module PSGit -Force

Given "we are NOT in a repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    Remove-Item TestDrive:\* -Recurse -Force
}

Given "we have initialized a repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
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
    $script:result = Get-GitStatus $pathspec
}

When "Add-GitItem (.*)? is called" {
    param($pathspec)
    # TODO: replace with PSGit native commands
    git add --all $pathspec
}

# This regex allows the step to be written as any of:
# the output should be: whatever
# the output should be: 'whatever'
# the output should be: "whatever"
# the output should be: 
#    """"multi-line string"""
Then 'the output should be:(?:\s*(["''])?(?<output>.*)(\1))?' {
    param($output)
    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd

    $result | Must -ceq $output
}

Then "the output should have" {
    param($Table)
    Write-Verbose ($Table | Out-String)

    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd

    foreach($Property in $Table) {
        $result | Must -Any $Property.Property -Eq $Property.Value
    }
}