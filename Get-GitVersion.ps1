enum Part {
    Major
    Minor
    Build
    Revision
    None
}

        function Get-Log {
            [CmdletBinding()]
            param()
            # # We have to transform the object to keep the data around after .Dispose()
            $Branches = $repo.Branches | Select-Object CanonicalName, FriendlyName, Is*, RemoteName, Tip, Track*, Upstream*, Ahead, Behind

            $Tags = @($repo.Tags)
            $Log = $repo.Commits | Select-Object Id,
            @{name = "Branch"; expr = { $c = $_; $Branches.Where{$c.Id -eq $_.Tip.Id} }},
            @{name = "Tags"; expr = { $c = $_; $Tags.Where{$c.Id -eq $_.Target.Id} }},
            Parents, Author,
            @{name = "Date"; expr = { $_.Author.When}},
            @{name = "Message"; expr = { $_.MessageShort}} |
                ForEach-Object { $_.PSTypeNames.Insert(0, "PSGit.Commit"), $_ }

            # Make the branch tip be one of the objects in the Log
            foreach ($branch in $Branches) {
                $branch.Tip = $Log.Where( {$_.Id -eq $branch.Tip.Id}, 1)
            }

            # We need to fix:
            # - only the tips of each branch have branch data
            # - the parent commit objects are separate (but identical) objects
            foreach ($commit in $Log) {
                Write-Verbose "Commit $($commit.Id) Branch: $($commit.Branch.FriendlyName)"
                # Reset the "Parents" to be pointers to their representation in the Log
                $commit.Parents = $Log.Where{$_.Id -in $commit.Parents.Id}
                # Set the branch on all the parents
                foreach ($parent in $commit.Parents) {
                    # How do we pick which "branch" a merge commit is in?
                    if (!$parent.Branch) {
                        # Write-Verbose "+ Update $($parent.Id) Branch: $($commit.Branch.FriendlyName)"
                        $parent.Branch = $commit.Branch
                    }
                }
            }

            Add-Member -Input $Log -Type NoteProperty -Name Branches -Value $Branches -Passthru
        }

function Get-GitVersion {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd,
        [String]$Sha
    )
    begin {
        [Part]$Highest = "None"
        [Version]$BaseVersion = "0.0.0.0"
        $Increment = [Ordered]@{
            Major = 0
            Minor = 0
            Build = 0
            Revision = 0
            None = 0 # this is a hack
        }
        function Increment {
            [CmdletBinding()]
            param($Commit, [Part]$NewIncrement, [Part]$CommitIncrement)

            # We only increment one part per commit, so pick the highest one we're going to use
            if ($Commit.Parents -eq $null -or -not (@($Commit.Parents).Branch.CanonicalName -eq $Commit.Branch.CanonicalName)) {
                [Part]$CommitIncrement = [Math]::Min([int]$NewIncrement, [int]$CommitIncrement)
            }
            # But only increment if we're not past that already
            if ($CommitIncrement -le $Highest) {
                Write-Verbose "Increment $CommitIncrement for '$($Commit.Message)' (on $($Commit.Branch.FriendlyName)) $($Commit.Id.Sha.Substring(0,7))"
                $Highest = $CommitIncrement
                $Increment["$CommitIncrement"] += 1
            } else {
                Write-Verbose "Skip incrementing $CommitIncrement because we already incremented $Highest"
            }
        }




        $Config = DATA {
            @{
                Branches = @{
                    master = @{
                        Pattern = "master"
                        # Matches tags like v1.0.0 or 2.1.0.0
                        VersionTag      = "v?(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"
                        NewIncrement    = "Major"
                        CommitIncrement = "Build"
                    }
                    release = @{
                        Pattern = "releases?/"
                        # Matches release branches like 1.0.0
                        VersionName     = "releases?/(?<version>\d+\.\d+\.\d+)"
                        # NOTIMPLEMENTED: VersionTag      = "v?(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"
                        NewIncrement    = "Minor"
                        CommitIncrement = "None"
                    }
                    feature = @{
                        Pattern = "features?/|dev/"
                        NewIncrement = "Build"
                        CommitIncrement = "Revision"
                    }
                }
            }
        }

    }
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if (!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            if (!@($repo.Commits)) {
                Write-Warning "No commits found in repository!"
                return
            }
            # Now, to find the version for *THIS* commit, we need to:
            # 1. Find a source of truth
            # 2. Increment from there according to rules

            # In order to guarantee each branch gets it's own version number, we need to index them in "some way"
            $Log = Get-Log

            function Set-BranchVersions {
                # GIVEN: $LOG with .BRANCHES

                # Go up Master from it's tip until we find a BaseVersion
                $Commit = $Master = $Log.Where({$_.Branch.FriendlyName -match $Config.Branches.Master.Pattern},0)

                do {
                    ## check if we found a source of truth:
                    # Does it have a version tag:
                    if ($Commit.Tags.FriendlyName -match "^$($Config.TagPattern)$") {
                        [Version]$BaseVersion = $Matches["Version"]
                        Write-Verbose "Found version tag $BaseVersion on $($Commit.Id): $($Commit.Tags.FriendlyName)"
                        break
                    }

                    # Is it a merge from a release branch:
                    if ($Release = @($Commit.Parents).Where( {$_.Branch.FriendlyName -match $Config.Branches.Release.Pattern}, 0)) {
                        # Check the branch name
                        if ($Release.Branch.FriendlyName -match "^$($Config.Branches.Release.VersionName)") {
                            [Version]$BaseVersion = $Matches["Version"]
                            Write-Verbose "Found release branch merge $BaseVersion on $($Commit.Id): $($Commit.Tags.FriendlyName)"
                            break
                        } else {
                            throw "Can't determine version from release branch name. Check your config for release branches "
                        }
                    }

                    $Commit = @($Commit.Parents).Where( {$_.Branch.FriendlyName -match $Config.Branches.Master.Pattern}, 0)
                } while ($Commit)

                # Now, tag with version any feature branches
                if($BaseVersion -ne "0.0.0.0") {
                    $Commit | Add-Member -Type NoteProperty -Name Version -Value $BaseVersion


                    [Version]$BaseVersion = "0.0.0.0"

                }
                # Now, from this
            }


            # The commit we care about is the current HEAD
            if ($Sha) {
                $Commit = $tip = $Log.Where( { $_.Id.Sha.StartsWith($Sha) })
                if (@($tip).Count -gt 1) {
                    throw "Bad Sha, matches multiple commits: `n$($tip.Id.Sha -join "`n")"
                }
            } else {
                $Commit = $tip = $Log[0] #.Where{ $_.Id -eq $repo.Head.Id}
            }

            do {
                Write-Verbose "Testing '$($Commit.Message)' ($($Commit.Branch.FriendlyName)) $($Commit.Id.Sha.Substring(0,7))"


                ## otherwise increment according to the config
                # find the branch config for this branch
                $BranchConfig = $null
                foreach ($branch in $Config.Branches.Keys) {
                    if ($Commit.Branch.FriendlyName -match "^$branch") {
                        $BranchConfig = $Config.Branches[$branch]
                        continue
                    }
                }
                if ($BranchConfig) {
                    # increment accordingly
                    . Increment $Commit @BranchConfig
                } else {
                    Write-Host "Can't find branch config for $($Commit.Branch.FriendlyName)"
                    $Commit | Out-Host
                }

                # Follow the trail
                $Commit = @($Commit.Parents)[-1]
            } while ($Commit)

            $Increment | Out-String | Out-Host
            $BaseVersion | Out-String | Out-Host

            $Version = [Version]::new(($BaseVersion.Major + $Increment.Major), ($BaseVersion.Minor + $Increment.Minor), ($BaseVersion.Build + $Increment.Build), ([Math]::Max(0, $BaseVersion.Revision) + $Increment.Revision))
            $SemVer = $Version.ToString(3) + "-" + $tip.Branch.FriendlyName + '.' + $Version.Revision + '.' + $Increment.None + '.sha.' + $tip.Id + '.date.' + $tip.Author.When.UtcDateTime.ToString("O").split(".", 2)[0]
            [PSCustomObject]@{
                Version = $Version
                SemVer = $SemVer
            }

            <#
            $Commits = @($Log)
            [Array]::Reverse($Commits)

            [Version]$Version = "1.0.0"
            #Write-Verbose "Initially, Version is $Version`n"
            foreach ($Commit in $Commits) {
                if ($Commit.Tags.FriendlyName -match $TagPattern) {
                    [Version]$Version = $Matches["Version"]
                    $CommitsSinceVersionSource = 0
                    $BranchesSinceVersionSource = 0
                    #Write-Verbose "After considering Tags, version is $Version"
                } else {
                    # Find the previously tagged build version
                    $CommitsSinceVersionSource = 0
                    $Parents = $Commit

                    #Write-Verbose "Commit $($Commit.Id) Branch $($Commit.Branch)"
                    do {
                        $Parents = @($Parents)[0].Parents
                        $CommitsSinceVersionSource += 1
                        #Write-Verbose "Parent $(@($Parents)[0].Id) tags ($(@($Parents)[0].Tags.FriendlyName))"
                    } while ($Parents -and ($Parents.Tags.FriendlyName -notmatch $TagPattern))

                    # We are always building the NEXT version
                    if (@($Parents)[0].Tags.FriendlyName -match $TagPattern) {
                        [Version]$Version = $Matches["Version"]
                        $Version = [Version]::new($Version.Major, $Version.Minor + 1, 0, $CommitsSinceVersionSource)
                        #Write-Verbose "After considering history, version is $Version"
                    }

                    switch -regex ($Commit.Branch.FriendlyName) {
                        "master" {
                            $BranchesSinceVersionSource += 1
                            $Version = [Version]::new($Version.Major, $Version.Minor, $BranchesSinceVersionSource)
                        }
                        "features?" {
                            #Write-Verbose "Feature branch! (if it's the first commit, increment the counter: parent $($Commit.Parents[0].Branch.FriendlyName))"
                            if ($Commit.Parents[0].Branch.FriendlyName -eq "master") {
                                $BranchesSinceVersionSource += 1
                                $Commit.Branch | Add-Member -MemberType NoteProperty -Name "Version" -Value $BranchesSinceVersionSource
                            }
                            $Version = [Version]::new($Version.Major, $Version.Minor, $Commit.Branch.Version, $CommitsSinceVersionSource)
                        }
                        "releases?" {
                            if ($Commit.Branch.FriendlyName -match "releases?/$Prefix(?<version>\d+\.\d+\.\d+(?:\d+\.)?)") {
                                [Version]$Version = $Matches["Version"]
                            }
                        }
                    }
                    #Write-Verbose "After incrementing, version is $Version`n"
                }

                $Commit | Add-Member -MemberType NoteProperty -Name Version -Value $Version
                $Commit | Add-Member -MemberType NoteProperty -Name CommitsSinceVersionSource -Value $CommitsSinceVersionSource
                $Commit | Add-Member -MemberType NoteProperty -Name BranchesSinceVersionSource -Value $BranchesSinceVersionSource
            }
            $Log
        #>
        } finally {
            if ($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}
