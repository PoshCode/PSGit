if(!(git config --get user.email)) {
    git config --global user.email "Anonymous@PoshCode.org"
    git config --global user.name "Nobody Important"
    git config --global core.autocrlf "true"
}

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

Given "we are in a git repository" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    Remove-Item TestDrive:\* -Recurse -Force

    New-GitRepository
}

Given "we have initialized a repository(?: with)?" {
    param($table)

    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    # Clear out any old stuff when we're asked to "initialize" a repository...
    Remove-Item TestDrive:\* -Recurse -Force

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
            }
        }
    }
}

Given "we have added a submodule `"(\w+)`"" {
    param($module)
    # TODO: replace with PSGit native commands
    git submodule add https://github.com/PoshCode/PSGit.git $module 2>&1
}


Given "we are in an empty folder" {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    Remove-Item TestDrive:\* -Recurse -Force
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
    if($pathspec) {
        $script:result = Get-GitInfo $pathspec -ErrorVariable script:errors -WarningVariable script:warnings
    } else {
        $script:result = Get-GitInfo -ErrorVariable script:errors -WarningVariable script:warnings
    }
}

When "New-GitRepository (.*)? ?is called" {
    param($pathspec)
    if($pathspec) {
        New-GitRepository $pathspec -ErrorVariable script:errors -WarningVariable script:warnings
    } else {
        New-GitRepository -ErrorVariable script:errors -WarningVariable script:warnings
    }

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
Then 'the output should be(?:.*(?<type>warning|error|information))?:(?:\s*(["''])?(?<output>.*)(\1))?' {
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
        "information" {
            $global:information | % { $_.ToString() }| Must -ceq $output
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
    
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

    if(!(Test-Path $folder -PathType Container))
    {
        throw "Folder ($folder) not found!"
    }
    return $true

}

Then 'there should NOT be a ["''](.*)["''] file' {
    param($file)
    
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    
    if(Test-Path $file -PathType Leaf)
    {
        throw "File ($file) found! Should not be there!"
    }
    return $true

}

Then 'the content of ["''](?<file>.*)["''] should be ["''](?<content>.*)["'']' {
    param($file,$content)

    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo

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
