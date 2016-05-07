if(!(git config --get user.email)) {
    git config --global user.email "Anonymous@PoshCode.org"
    git config --global user.name "Nobody Important"
    git config --global core.autocrlf "true"
}

BeforeScenario {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    Remove-Item TestDrive:\* -Recurse -Force
}

AfterScenario {
    Pop-Location
    [Environment]::CurrentDirectory = Convert-Path $Pwd
}

Given "we have a command ([\w-]+)" {
    param($command)
    $script:command = Get-Command $command -Module PSGit -ErrorAction Stop
}

Given "we are NOT in a repository" {
    # Remove-Item TestDrive:\* -Recurse -Force
    if(gci){ throw "There Are Things Here!" }
}
Given "we are in an empty folder" {
    if(gci){ throw "There Are Things Here!" }
}

Given "we are in a git repository" {
    New-GitRepository
}

function ProcessGitActions($table) {
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
                    git commit -m "Ignore $($change.Name)"
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
                "Push" {
                    &{[CmdletBinding()]param() 

                        git push

                    } 2>>..\git.log
                }
                "Branched" {
                    &{[CmdletBinding()]param() 

                        git checkout -b $change.Name 
                
                    } 2>>..\git.log
                }
                "Reset" {
                    git reset --hard $change.Name
                }
            }
        }
    }
}

Given "we have initialized a repository(?: with)?" {
    param($table)

    # TODO: replace with PSGit native commands
    git init

    ProcessGitActions $table
}

Given "we have cloned a repository(?: and)?" {
    param($table)

    mkdir source
    pushd .\source
    # TODO: replace with PSGit native commands
    git init
    Set-Content SourceOne.ps1   (Get-Date)
    Set-Content SourceTwo.ps1   (Get-Date)
    git add Source*
    git commit -m "Initial Commit"
    popd

    &{[CmdletBinding()]param() git clone --bare .\source } 2>..\git.log

    mkdir copy
    cd .\copy

    # git clone outputs information to stderr for no reason
    &{[CmdletBinding()]param() git clone ..\source.git . } 2>..\git.log

    ProcessGitActions $table
}

Given "we have cloned a complex repository(?: and)?" {
    param($table)

    &{
        mkdir source
        pushd .\source
        # TODO: replace with PSGit native commands
        git init

        # Add some files
        Set-Content SourceOne.ps1   (Get-Date)
        Set-Content SourceTwo.ps1   (Get-Date)
        git add Source*
        git commit -m "Initial Commit"

        # Add some more files
        Set-Content SourceThree.ps1   (Get-Date)
        Set-Content SourceFour.ps1   (Get-Date)
        git add Source*
        git commit -m "Second Commit"
        git tag -a v1.0 -m "All Files Present"

        # Add some more files
        Add-Content SourceOne.ps1   (Get-Date)
        Add-Content SourceFour.ps1   (Get-Date)
        git commit -a -m "Third Commit"

        # Branch
        git checkout -b dev
        Add-Content SourceOne.ps1   (Get-Date)
        Add-Content SourceTwo.ps1   (Get-Date)
        git commit -a -m "Rewrite One and Two"

        # Branch From Dev
        git checkout -b feature1
        Add-Content SourceOne.ps1   (Get-Date)
        Add-Content SourceFour.ps1   (Get-Date)
        git commit -a -m "Alter One and Four"

        # Rebranch From Dev
        git checkout dev
        git checkout -b feature2
        Add-Content SourceThree.ps1   (Get-Date)
        git commit -a -m "Alter Three"

        Add-Content SourceThree.ps1   (Get-Date)
        git commit -a -m "Alter Three Again"

        # Switch back to dev and merge feature2
        git checkout dev
        git merge feature2

        popd

        # create a "bare" repo, suitable for pushing to
        git clone --bare .\source 

        mkdir copy
        cd .\copy

        # git clone outputs information to stderr for no reason
        git clone ..\source.git .

    } 2>>.\git.log

    ProcessGitActions $table
}

Given "we have added a submodule `"(\w+)`"" {
    param($module)
    # TODO: replace with PSGit native commands
    git submodule add https://github.com/PoshCode/PSGit.git $module 2>&1
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

    $script:result = Get-GitChange $pathspec -ErrorVariable script:errors -WarningVariable script:warnings @Options -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}
When "Get-GitInfo (.*)? ?is called" {
    param($pathspec)
    if($pathspec) {
        $script:result = Get-GitInfo $pathspec -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    } else {
        $script:result = Get-GitInfo -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    }
}

When "Get-GitBranch (?:(?<Force>-Force )|(?<pathspec>.*) )*is called" {
    param($pathspec, $Force=$null)
    $Force = $null -ne $Force
    if($pathspec) {
        $script:result = Get-GitBranch $pathspec -Force:$Force -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    } else {
        $script:result = Get-GitBranch -Force:$Force -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    }
}

When "New-GitRepository (.*)? ?is called" {
    param($pathspec)
    if($pathspec) {
        New-GitRepository $pathspec -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    } else {
        New-GitRepository -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    }
}

When "Add-GitItem (.*)? is called" {
    param($pathspec)
    # TODO: replace with PSGit native commands
    git add --all $pathspec
}

When "Show-GitStatus (.*)? ?is called" {
    param($pathspec)
    if($pathspec) {
        Show-GitStatus $pathspec -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    } else {
        Show-GitStatus -ErrorVariable script:errors -WarningVariable script:warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    }

}


# This regex allows the step to be written as any of:
# the output should be a warning: whatever
# the output should be an error: whatever
# the output should be: whatever
# the output should be: 'whatever'
# the output should be: "whatever"
# the output should be: 
#    """"multi-line string"""
Then 'the output should be(?:.*(?<type>warning|error|information))?:(?:\s*(["''])?(?<output>.*)(\1))?' {
    param($output, $type = "default")
    switch($type) {
        "warning" {
            $script:warnings | % { $_.ToString() } | Must -ceq $output
        }
        "error" {
            $script:errors | % { $_.ToString() }| Must -ceq $output
        }
        "information" {
            $global:information | % { $_.ToString() }| Must -ceq $output
        }
        default {
            $script:result | % { $_.ToString() }| Must -ceq $output
        }
    }

}

Then "there should be no output" {

    $script:result   | Must -BeNullOrEmpty
    $script:warnings | Must -BeNullOrEmpty
    $script:errors   | Must -BeNullOrEmpty
}

Then "the output should have" {
    param($Table)
    Write-Verbose ($Table | Out-String)

    foreach($Property in $Table) {
        switch($Property.Value) {
            '$True' {
                $script:result | Must -Any $Property.Property -Eq $True
            }
            '$False' {
                $script:result | Must -Any $Property.Property -Eq $False
            }
            '$null' {
                $script:result | Must -Any $Property.Property -Eq $null
            } 
            default {
                $script:result | Must -Any $Property.Property -Eq $Property.Value
            }
        }
    }
}

Then "output (\d+) '(.*)' should (\w+) '(.*)'" {
    param([int]$Index, $Property, $Comparator, $Pattern)
    $index--

    $Parameters = @{
        $Comparator = $True
        Value = $Pattern
    }

    $script:result[$index] | Must $Property @Parameters    
}

Then "output (\d+) should have" {
    param([int]$Index, $Table)
    Write-Verbose ($Table | Out-String)
    $index--

    foreach($Property in $Table) {
        switch($Property.Value) {
            '$True' {
                $script:result[$index] | Must -Any $Property.Property -Eq $True
            }
            '$False' {
                $script:result[$index] | Must -Any $Property.Property -Eq $False
            }
            '$null' {
                $script:result[$index] | Must -Any $Property.Property -Eq $null
            } 
            default {
                $script:result[$index] | Must -Any $Property.Property -Eq $Property.Value
            }
        }
    }
}

Then "there should be (\d+) results" {
    param([int]$Count)
    Must -Input @($script:result) Count -eq $Count
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
    param($Table)
    # TODO: add "AFTER" support for Gherkin so we can do this:
    trap {
        Write-Warning $($Result | ft -auto | Out-String)
        Write-Warning $($(git status) -Join "`n")
        throw $_
    }

    for($f =0; $f -lt $Result.Count; $f++) {
        # Staged | Change  | Path
        $R = $Result[$f] 
        $T = $Table[$f]
        if($T.OldPath) {
            $R | Must OldPath -eq $T.OldPath
        }
        $R | Must Path    -eq $T.Path
        $R | Must Staged  -eq ($T.Staged -eq "True")
        $R | Must Change  -eq $T.Change

    }
}

Then 'there should be a ["''](.*)["''] folder' {
    param($folder)
    
    if(!(Test-Path $folder -PathType Container))
    {
        throw "Folder ($folder) not found!"
    }
    return $true

}

Then 'there should NOT be a ["''](.*)["''] file' {
    param($file)
    
    if(Test-Path $file -PathType Leaf)
    {
        throw "File ($file) found! Should not be there!"
    }
    return $true

}

Then 'the content of ["''](?<file>.*)["''] should be ["''](?<content>.*)["'']' {
    param($file,$content)

    if(Test-Path $file -PathType Leaf)
    {
        $data = Get-Content $file -Raw
        if($data -eq $content -or $data.Trim() -eq $content)
        {
            return $true
        }
        else
        {
            throw "Content not found in file! ($data)"
        }

    }
    throw "File $file not found"
}

Given "we expect Get-Info and Get-Change to be called" {
    Mock -Module PSGit Get-Info { } -Verifiable
    Mock -Module PSGit Get-Change { } -Verifiable
}


# this step lets us verify the number of calls to those three mocks
When "(?<command>.*) is logged(?: (?<exactly>exactly) (?<count>\d+) times?)?" {
    param($command, $count, $exactly)
    $param = @{Command = $command}
    if($count) {
        $param.Exactly = $Exactly -eq "Exactly"
        $param.Times = $count
    }
    Assert-MockCalled -Module PSGit @param
}



Then 'Wait-Debugger' { Wait-Debugger }