Given "we have a command ([\w-]+)" {
    param($command)
    $script:command = Get-Command $command -Module PSGit
}

Given "we are NOT in a repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    Remove-Item TestDrive:\* -Recurse -Force
}

Given "we have initialized a repository(?: with)?" {
    param($table)

    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    # TODO: replace with PSGit native commands
    git init

    if($table) {
        foreach($change in $table) {
            switch($change.FileAction) {
                "Created" {
                    New-Item $change.Name -Item File
                }
                "Added" {
                    # TODO: replace with PSGit native commands
                    git add --all $pathspec
                }
                "Modified" {
                    Add-Content $change.Name (Get-Date)
                }
                "Commited" {
                    # TODO: replace with PSGit native commands
                    git commit -m "$($change.Name)"
                }
            }
        }    
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

Then "it should have parameters:" {
    param($Table)

    foreach($Parameter in $Table) {
        if(!$command.Parameters.ContainsKey($Parameter.Name)) {
            throw "Parameter $($Parameter.Name) does not exist"
        }
        $command.Parameters.($Parameter.Name) | Must ParameterType -eq ($Parameter.Type -as [Type])
    }
}