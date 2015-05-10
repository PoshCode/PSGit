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
                    Set-Content $change.Name (Get-Date)
                }
                "Added" {
                    # TODO: replace with PSGit native commands
                    git add --all $pathspec
                }
                "Ignore" {
                    # TODO: replace with PSGit native commands
                    Add-Content .gitignore $change.Name
                    git add .\.gitignore
                }
                "Modified" {
                    Add-Content $change.Name (Get-Date)
                }
                "Commited" {
                    # TODO: replace with PSGit native commands
                    git commit -m "$($change.Name)"
                }
                "Removed" {
                    Remove-Item $change.Name
                }
                "Renamed" {
                    Rename-Item $change.Name $change.Value
                }
            }
        }
    }
}


When "Get-GitChange (.*)? ?is called" {
    param($pathspec)
    $newspec = $pathspec -replace "-ShowIgnored"

    $Options = @{}
    if($newspec -ne $pathspec) {
        $pathspec = $newspec
        $Options.ShowIgnored = $true
    }    

    $newspec = $pathspec -replace "-HideSubmodules"
    if($newspec -ne $pathspec) {
        $pathspec = $newspec
        $Options.HideSubmodules = $true
    }   
    

    $script:result = Get-GitChange $pathspec -ErrorVariable script:errors -WarningVariable script:warnings @Options
}
When "Get-GitInfo (.*)? ?is called" {
    param($pathspec)
    $script:result = Get-GitInfo $pathspec -ErrorVariable script:errors -WarningVariable script:warnings
}

When "Add-GitItem (.*)? is called" {
    param($pathspec)
    # TODO: replace with PSGit native commands
    git add --all $pathspec
}

# This regex allows the step to be written as any of:
# the output should be a warning: whatever
# the output should be an error: whatever
# the output should be: whatever
# the output should be: 'whatever'
# the output should be: "whatever"
# the output should be: 
#    """"multi-line string"""
Then 'the output should be(?:.*(?<type>warning|error))?:(?:\s*(["''])?(?<output>.*)(\1))?' {
    param($output, $type = "default")
    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd
    switch($type) {
        "warning" {
            $script:warnings | % { $_.ToString() } | Must -ceq $output
        }
        "error" {
            $script:errors | % { $_.ToString() }| Must -ceq $output
        }
        default {
            $script:result | % { $_.ToString() }| Must -ceq $output
        }
    }

}

Then "there should be no output" {
    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd

    $script:result   | Must -BeNullOrEmpty
    $script:warnings | Must -BeNullOrEmpty
    $script:errors   | Must -BeNullOrEmpty
}

Then "the output should have" {
    param($Table)
    Write-Verbose ($Table | Out-String)

    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd

    foreach($Property in $Table) {
        $script:result | Must -Any $Property.Property -Eq $Property.Value
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

Then "the status of git should be" {

    # TODO: add "AFTER" support for Gherkin so we can do this:
    Pop-Location; [Environment]::CurrentDirectory = $Pwd

    Write-ERROR "TEST NOT IMPLEMENTED"

}