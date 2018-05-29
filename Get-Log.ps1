$Prefix = "v?"
$TagPattern = "$Prefix(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"

[ValidateSet("Major","Minor","Build","Revision")]
[string]$Increment = "Build"


function Get-Log {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if(!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            # # We have to transform the object to keep the data around after .Dispose()
            # $repo.Head |
            #     Select-Object $BranchProperties |
            #     ForEach-Object { $_.PSTypeNames.Insert(0,"PSGit.Branch"); $_ }

            $Log = $repo.Commits | Select-Object Id,
                @{name = "Branch"; expr = { $c = $_; $repo.Branches.Where{$c.Id -eq $_.Tip.Id} }},
                @{name = "Tags";   expr = { $c = $_; $repo.Tags.Where{$c.Id -eq $_.Target.Id} }},
                Parents, Author,
                @{name = "Date";   expr = { $_.Author.When}},
                Message |
                ForEach-Object { $_.PSTypeNames.Insert(0, "PSGit.Commit"), $_ }

            Write-Verbose "Scanning $($Log.Count) commits"
            foreach($commit in $Log) {
                $commit.Parents = $Log.Where{$_.Id -in $commit.Parents.Id}
                foreach($parent in $commit.Parents) {
                    if(!$parent.Branch) {
                        $parent.Branch = $commit.Branch
                    }
                    # foreach($parent in $Log.Where{$_.Id -eq $p.Id}) {
                    #     if($parent.Children) {
                    #         $parent.Children += $commit
                    #     } else {
                    #         $parent | Add-Member -MemberType NoteProperty -Name Children -Value @($commit)
                    #     }
                    # }
                }
            }

            $Commits = @($Log)
            [Array]::Reverse($Commits)

            [Version]$Version = "1.0.0"
            foreach($Commit in $Commits) {
                if ($Commit.Tags.Name -match $TagPattern) {
                    [Version]$Version = $Matches["Version"]
                    $CommitsSinceVersionSource = 0
                    $BranchesSinceVersionSource = 0
                } else {
                    # Find the previously tagged build version
                    $CommitsSinceVersionSource = 0
                    $Parents = $Commit
                    do {
                        $Parents = @($Parents)[0].Parents
                        $CommitsSinceVersionSource += 1
                        Write-Verbose "Check parent $(@($Parents)[0].Id) for tags"
                    } while ($Parents -and ($Parents.Tags.Name -notmatch $TagPattern))

                    # We are always building the NEXT version
                    if (@($Parents)[0].Tags.Name -match $TagPattern) {
                        [Version]$Version = $Matches["Version"]
                        $Version = [Version]::new($Version.Major, $Version.Minor + 1, 0, $CommitsSinceVersionSource)
                    }

                    switch -regex ($Commit.Branch.Name) {
                        "master" {
                            $Version = [Version]::new($Version.Major, $Version.Minor, $CommitsSinceVersionSource)
                        }
                        "features?" {
                            # $Increment += "Build"
                            if ($Commit.Parents[0].Branch.Name -eq "master") {
                                $BranchesSinceVersionSource += 1
                            }
                            $Version = [Version]::new($Version.Major, $Version.Minor, $BranchesSinceVersionSource, $CommitsSinceVersionSource)
                        }
                        "releases?" {
                            if ($Commit.Branch.Name -match "releases?/$Prefix(?<version>\d+\.\d+\.\d+(?:\d+\.)?)") {
                                [Version]$Version = $Matches["Version"]
                            }
                        }
                    }
                }

                $Commit | Add-Member -MemberType NoteProperty -Name Version -Value $Version
                $Commit | Add-Member -MemberType NoteProperty -Name CommitsSinceVersionSource -Value $CommitsSinceVersionSource
                $Commit | Add-Member -MemberType NoteProperty -Name BranchesSinceVersionSource -Value $BranchesSinceVersionSource
            }
            $Log
        } finally {
            if($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}
